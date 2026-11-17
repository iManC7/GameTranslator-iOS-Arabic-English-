/* SPDX-License-Identifier: AGPL-3.0-only */
/* gt_native.h işlevlerini Kotlin'deki Native nesnesine bağlar. Geri çağrılar libchiaki'nin kendi iş
 * parçacıklarından gelir; iş parçacığı JVM'e bir kez bağlanır ve kapanırken kendiliğinden ayrılır. */

#include "gt_native.h"

#include <jni.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

#define NATIVE_CLASS "com/gametranslator/gametranslator_mobile/Native"

static JavaVM *gt_vm;
static pthread_key_t gt_detach_key;

static void gt_detach(void *unused)
{
	(void)unused;
	if(gt_vm)
		(*gt_vm)->DetachCurrentThread(gt_vm);
}

/* Çağıran iş parçacığının JNIEnv'i; gerekirse JVM'e bağlar. */
static JNIEnv *gt_env(void)
{
	JNIEnv *env = NULL;
	if(!gt_vm)
		return NULL;
	if((*gt_vm)->GetEnv(gt_vm, (void **)&env, JNI_VERSION_1_6) == JNI_OK)
		return env;
	if((*gt_vm)->AttachCurrentThread(gt_vm, &env, NULL) != JNI_OK)
		return NULL;
	pthread_setspecific(gt_detach_key, (void *)1);
	return env;
}

/* Java'da fırlatılan istisna yerel iş parçacığını düşürmesin. */
static void gt_clear_exception(JNIEnv *env)
{
	if((*env)->ExceptionCheck(env))
		(*env)->ExceptionClear(env);
}

/* libchiaki günlüğü geçersiz UTF-8 taşıyabilir (PS5 adı); NewStringUTF öyle metinde çöker. */
static jstring gt_string(JNIEnv *env, const char *text)
{
	if(!text)
		return NULL;
	size_t length = strlen(text);
	char *clean = malloc(length + 1);
	if(!clean)
		return NULL;
	for(size_t i = 0; i < length; i++)
		clean[i] = ((unsigned char)text[i] < 0x80 && text[i] != 0) ? text[i] : '?';
	clean[length] = '\0';
	jstring result = (*env)->NewStringUTF(env, clean);
	free(clean);
	return result;
}

/* PS5 adı gibi gerçek UTF-8 metinler: bayt dizisi olarak verilir, Kotlin çözer. */
static jbyteArray gt_bytes(JNIEnv *env, const char *text)
{
	jsize length = text ? (jsize)strlen(text) : 0;
	jbyteArray array = (*env)->NewByteArray(env, length);
	if(array && length > 0)
		(*env)->SetByteArrayRegion(env, array, 0, length, (const jbyte *)text);
	return array;
}

/* --- Arama --- */

typedef struct {
	jobject callback;
	jmethodID on_console;
} gt_discover_ctx;

static void gt_on_console(const char *host, const char *name, int awake, void *user)
{
	gt_discover_ctx *ctx = user;
	JNIEnv *env = gt_env();
	if(!env)
		return;
	jstring j_host = gt_string(env, host);
	jbyteArray j_name = gt_bytes(env, name);
	(*env)->CallVoidMethod(env, ctx->callback, ctx->on_console, j_host, j_name, awake ? JNI_TRUE : JNI_FALSE);
	gt_clear_exception(env);
	if(j_host)
		(*env)->DeleteLocalRef(env, j_host);
	if(j_name)
		(*env)->DeleteLocalRef(env, j_name);
}

static jint gt_discover(JNIEnv *env, jobject self, jobjectArray targets, jint timeout_ms, jobject callback)
{
	(void)self;
	if(!targets || !callback)
		return 1;
	jsize count = (*env)->GetArrayLength(env, targets);
	const char **hosts = calloc((size_t)(count > 0 ? count : 1), sizeof(char *));
	jstring *refs = calloc((size_t)(count > 0 ? count : 1), sizeof(jstring));
	if(!hosts || !refs)
	{
		free(hosts);
		free(refs);
		return -1;
	}
	for(jsize i = 0; i < count; i++)
	{
		refs[i] = (jstring)(*env)->GetObjectArrayElement(env, targets, i);
		hosts[i] = refs[i] ? (*env)->GetStringUTFChars(env, refs[i], NULL) : NULL;
	}

	jclass cls = (*env)->GetObjectClass(env, callback);
	gt_discover_ctx ctx;
	ctx.callback = (*env)->NewGlobalRef(env, callback);
	ctx.on_console = (*env)->GetMethodID(env, cls, "onConsole", "(Ljava/lang/String;[BZ)V");
	(*env)->DeleteLocalRef(env, cls);

	int result = -1;
	if(ctx.on_console)
		result = cs_discover(hosts, (int)count, (int)timeout_ms, gt_on_console, &ctx);
	else
		gt_clear_exception(env);

	(*env)->DeleteGlobalRef(env, ctx.callback);
	for(jsize i = 0; i < count; i++)
	{
		if(refs[i])
		{
			if(hosts[i])
				(*env)->ReleaseStringUTFChars(env, refs[i], hosts[i]);
			(*env)->DeleteLocalRef(env, refs[i]);
		}
	}
	free(hosts);
	free(refs);
	return result;
}

static jint gt_wake(JNIEnv *env, jobject self, jstring host, jlong credential)
{
	(void)self;
	if(!host)
		return 1;
	const char *c_host = (*env)->GetStringUTFChars(env, host, NULL);
	int result = cs_wake(c_host, (uint64_t)credential);
	(*env)->ReleaseStringUTFChars(env, host, c_host);
	return result;
}

/* --- Günlük, kayıt ve oturum için ortak dinleyici --- */

typedef struct {
	jobject listener;
	jmethodID on_log;
	jmethodID on_frame;
	jmethodID on_event;
} gt_listener;

static void gt_on_log(int level, const char *message, void *user)
{
	gt_listener *listener = user;
	if(!listener || !listener->listener || !listener->on_log)
		return;
	JNIEnv *env = gt_env();
	if(!env)
		return;
	jstring text = gt_string(env, message);
	(*env)->CallVoidMethod(env, listener->listener, listener->on_log, (jint)level, text);
	gt_clear_exception(env);
	if(text)
		(*env)->DeleteLocalRef(env, text);
}

/* out: 64 bayt (ad 32, kayıt anahtarı 16, oturum anahtarı 16). reason: 1 elemanlı. */
static jint gt_register(JNIEnv *env, jobject self, jstring host, jbyteArray account_id, jint pin,
		jbyteArray out, jintArray reason, jobject log)
{
	(void)self;
	if(!host || !account_id || !out || (*env)->GetArrayLength(env, account_id) != 8
			|| (*env)->GetArrayLength(env, out) < (jsize)sizeof(cs_registered_console))
		return -1;

	gt_listener listener;
	memset(&listener, 0, sizeof(listener));
	if(log)
	{
		jclass cls = (*env)->GetObjectClass(env, log);
		listener.listener = (*env)->NewGlobalRef(env, log);
		listener.on_log = (*env)->GetMethodID(env, cls, "onLog", "(ILjava/lang/String;)V");
		(*env)->DeleteLocalRef(env, cls);
		gt_clear_exception(env);
	}

	uint8_t account[8];
	(*env)->GetByteArrayRegion(env, account_id, 0, 8, (jbyte *)account);
	const char *c_host = (*env)->GetStringUTFChars(env, host, NULL);

	cs_registered_console console;
	memset(&console, 0, sizeof(console));
	uint32_t c_reason = 0;
	int result = cs_register(c_host, account, (uint32_t)pin, &console, &c_reason, gt_on_log, &listener);

	(*env)->ReleaseStringUTFChars(env, host, c_host);
	if(result == 0)
		(*env)->SetByteArrayRegion(env, out, 0, (jsize)sizeof(console), (const jbyte *)&console);
	if(reason && (*env)->GetArrayLength(env, reason) >= 1)
	{
		jint value = (jint)c_reason;
		(*env)->SetIntArrayRegion(env, reason, 0, 1, &value);
	}
	if(listener.listener)
		(*env)->DeleteGlobalRef(env, listener.listener);
	return result;
}

/* --- Oturum --- */

typedef struct {
	gt_listener listener;
	cs_session *session;
} gt_session;

static void gt_on_frame(const uint8_t *rgba, int width, int height, int stride, void *user)
{
	gt_listener *listener = user;
	JNIEnv *env = gt_env();
	if(!env || !listener->on_frame)
		return;
	/* Bellek yalnız çağrı süresince geçerli; Kotlin tarafı çağrı içinde kopyalar. */
	jobject buffer = (*env)->NewDirectByteBuffer(env, (void *)rgba, (jlong)stride * (jlong)height);
	if(!buffer)
	{
		gt_clear_exception(env);
		return;
	}
	(*env)->CallVoidMethod(env, listener->listener, listener->on_frame, buffer, (jint)width, (jint)height, (jint)stride);
	gt_clear_exception(env);
	(*env)->DeleteLocalRef(env, buffer);
}

static void gt_on_event(int event, int quit_reason, const char *reason_text, void *user)
{
	gt_listener *listener = user;
	JNIEnv *env = gt_env();
	if(!env || !listener->on_event)
		return;
	jstring text = gt_string(env, reason_text);
	(*env)->CallVoidMethod(env, listener->listener, listener->on_event, (jint)event, (jint)quit_reason, text);
	gt_clear_exception(env);
	if(text)
		(*env)->DeleteLocalRef(env, text);
}

static jlong gt_session_start(JNIEnv *env, jobject self, jstring host, jbyteArray regist_key, jbyteArray morning,
		jbyteArray account_id, jint max_fps, jobject j_listener)
{
	(void)self;
	if(!host || !regist_key || !morning || !account_id || !j_listener
			|| (*env)->GetArrayLength(env, regist_key) != 16 || (*env)->GetArrayLength(env, morning) != 16
			|| (*env)->GetArrayLength(env, account_id) != 8)
		return 0;

	gt_session *session = calloc(1, sizeof(gt_session));
	if(!session)
		return 0;
	jclass cls = (*env)->GetObjectClass(env, j_listener);
	session->listener.listener = (*env)->NewGlobalRef(env, j_listener);
	session->listener.on_log = (*env)->GetMethodID(env, cls, "onLog", "(ILjava/lang/String;)V");
	session->listener.on_frame = (*env)->GetMethodID(env, cls, "onFrame", "(Ljava/nio/ByteBuffer;III)V");
	session->listener.on_event = (*env)->GetMethodID(env, cls, "onEvent", "(IILjava/lang/String;)V");
	(*env)->DeleteLocalRef(env, cls);
	if(!session->listener.on_log || !session->listener.on_frame || !session->listener.on_event)
	{
		gt_clear_exception(env);
		(*env)->DeleteGlobalRef(env, session->listener.listener);
		free(session);
		return 0;
	}

	uint8_t key[16], morning_bytes[16], account[8];
	(*env)->GetByteArrayRegion(env, regist_key, 0, 16, (jbyte *)key);
	(*env)->GetByteArrayRegion(env, morning, 0, 16, (jbyte *)morning_bytes);
	(*env)->GetByteArrayRegion(env, account_id, 0, 8, (jbyte *)account);
	const char *c_host = (*env)->GetStringUTFChars(env, host, NULL);

	session->session = cs_session_start(c_host, key, morning_bytes, account, (int)max_fps,
			gt_on_frame, gt_on_event, gt_on_log, &session->listener);

	(*env)->ReleaseStringUTFChars(env, host, c_host);
	if(!session->session)
	{
		(*env)->DeleteGlobalRef(env, session->listener.listener);
		free(session);
		return 0;
	}
	return (jlong)(intptr_t)session;
}

static void gt_session_stop(JNIEnv *env, jobject self, jlong handle)
{
	(void)self;
	gt_session *session = (gt_session *)(intptr_t)handle;
	if(!session)
		return;
	/* İş parçacıkları beklenir; bundan sonra geri çağrı gelmez. */
	cs_session_stop(session->session);
	(*env)->DeleteGlobalRef(env, session->listener.listener);
	free(session);
}

static jint gt_init(JNIEnv *env, jobject self)
{
	(void)env;
	(void)self;
	return cs_init();
}

static const JNINativeMethod gt_methods[] = {
	{ "init", "()I", (void *)gt_init },
	{ "discover", "([Ljava/lang/String;IL" NATIVE_CLASS "$ConsoleCallback;)I", (void *)gt_discover },
	{ "wake", "(Ljava/lang/String;J)I", (void *)gt_wake },
	{ "register", "(Ljava/lang/String;[BI[B[IL" NATIVE_CLASS "$LogCallback;)I", (void *)gt_register },
	{ "sessionStart", "(Ljava/lang/String;[B[B[BIL" NATIVE_CLASS "$SessionListener;)J", (void *)gt_session_start },
	{ "sessionStop", "(J)V", (void *)gt_session_stop },
};

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
	(void)reserved;
	gt_vm = vm;
	pthread_key_create(&gt_detach_key, gt_detach);
	JNIEnv *env = NULL;
	if((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK)
		return JNI_ERR;
	jclass cls = (*env)->FindClass(env, NATIVE_CLASS);
	if(!cls)
		return JNI_ERR;
	if((*env)->RegisterNatives(env, cls, gt_methods, (jint)(sizeof(gt_methods) / sizeof(gt_methods[0]))) != JNI_OK)
		return JNI_ERR;
	return JNI_VERSION_1_6;
}
