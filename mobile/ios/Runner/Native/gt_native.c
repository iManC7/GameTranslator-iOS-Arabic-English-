/* SPDX-License-Identifier: AGPL-3.0-only */
/* gt_native.h arayüzünün libchiaki + VideoToolbox üstündeki iOS gerçeklemesi.
 * Arama, uyandırma, kayıt ve oturum kısmı Android'deki mobile/android/app/src/main/cpp/gt_native.c ile aynıdır
 * (oradan kopyalandı; birinde düzeltilen hata ötekinde de düzeltilmeli). Yalnız H.264 çözücü MediaCodec yerine
 * VideoToolbox ve kareler RGBA yerine BGRA (iOS'un yerel biçimi, Vision doğrudan okur). */

#include "gt_native.h"

#include <chiaki/common.h>
#include <chiaki/discovery.h>
#include <chiaki/log.h>
#include <chiaki/regist.h>
#include <chiaki/session.h>
#include <chiaki/thread.h>
#include <chiaki/time.h>


#include <CoreMedia/CoreMedia.h>
#include <CoreVideo/CoreVideo.h>
#include <VideoToolbox/VideoToolbox.h>

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#ifndef SIO_UDP_CONNRESET
#define SIO_UDP_CONNRESET _WSAIOW(IOC_VENDOR, 12)
#endif
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <pthread.h>
#include <time.h>
#endif

#define CS_LOG_MASK (CHIAKI_LOG_ERROR | CHIAKI_LOG_WARNING | CHIAKI_LOG_INFO)

static void cs_sleep_ms(unsigned int ms)
{
#ifdef _WIN32
	Sleep(ms);
#else
	struct timespec ts = { ms / 1000, (long)(ms % 1000) * 1000000L };
	nanosleep(&ts, NULL);
#endif
}

static int cs_level(ChiakiLogLevel level)
{
	if(level & CHIAKI_LOG_ERROR)
		return 0;
	if(level & CHIAKI_LOG_WARNING)
		return 1;
	return 2;
}

/* --- Günlük --- */

typedef struct {
	cs_log_cb cb;
	void *user;
} cs_log_target;

static void cs_log_forward(ChiakiLogLevel level, const char *message, void *user)
{
	cs_log_target *target = user;
	if(target && target->cb && message)
		target->cb(cs_level(level), message, target->user);
}

static void cs_logf(cs_log_cb cb, void *user, int level, const char *fmt, const char *arg)
{
	if(!cb)
		return;
	char line[256];
	snprintf(line, sizeof(line), fmt, arg);
	cb(level, line, user);
}

/* --- Başlatma --- */

static int cs_init_result = -1;

/* chiaki_lib_init WSAStartup'ı ve FEC'in Galois tablolarını hazırlar; bir kez yeterli. */
static void cs_init_once(void)
{
	cs_init_result = (int)chiaki_lib_init();
}

#ifdef _WIN32
static INIT_ONCE cs_once = INIT_ONCE_STATIC_INIT;

static BOOL CALLBACK cs_init_once_win(PINIT_ONCE once, PVOID parameter, PVOID *context)
{
	(void)once;
	(void)parameter;
	(void)context;
	cs_init_once();
	return TRUE;
}
#else
static pthread_once_t cs_once = PTHREAD_ONCE_INIT;
#endif

CS_API int cs_init(void)
{
#ifdef _WIN32
	InitOnceExecuteOnce(&cs_once, cs_init_once_win, NULL, NULL);
#else
	pthread_once(&cs_once, cs_init_once);
#endif
	return cs_init_result;
}

/* --- PS5 arama ve uyandırma --- */

typedef struct {
	cs_console_cb cb;
	void *user;
} cs_discover_ctx;

static void cs_discovery_cb(ChiakiDiscoveryHost *host, void *user)
{
	cs_discover_ctx *ctx = user;
	if(!host || !host->host_addr || !chiaki_discovery_host_is_ps5(host))
		return;
	ctx->cb(host->host_addr, host->host_name ? host->host_name : "PS5",
			host->state == CHIAKI_DISCOVERY_HOST_STATE_READY ? 1 : 0, ctx->user);
}

CS_API int cs_discover(const char *const *targets, int target_count, int timeout_ms, cs_console_cb callback, void *user)
{
	if(!targets || target_count <= 0 || !callback)
		return 1;

	/* Hedefsiz günlük: satırlar düşürülür (libchiaki'nin varsayılanı stdout'a yazardı). */
	ChiakiLog log;
	chiaki_log_init(&log, CHIAKI_LOG_ERROR, cs_log_forward, NULL);

	ChiakiDiscovery discovery;
	if(chiaki_discovery_init(&discovery, &log, AF_INET) != CHIAKI_ERR_SUCCESS)
		return -1;

#ifdef _WIN32
	/* Windows'ta ulaşılamayan bir adrese gönderilen paketin ICMP yanıtı recvfrom'u WSAECONNRESET ile
	 * bozar ve chiaki'nin arama iş parçacığı kapanır; tüm ağı taradığımız için bu kapatılmalı. */
	{
		BOOL report = FALSE;
		DWORD returned = 0;
		WSAIoctl(discovery.socket, SIO_UDP_CONNRESET, &report, sizeof(report), NULL, 0, &returned, NULL, NULL);
	}
#endif

	cs_discover_ctx ctx = { callback, user };
	ChiakiDiscoveryThread thread;
	if(chiaki_discovery_thread_start(&thread, &discovery, cs_discovery_cb, &ctx) != CHIAKI_ERR_SUCCESS)
	{
		chiaki_discovery_fini(&discovery);
		return -1;
	}

	struct sockaddr_in *addresses = calloc((size_t)target_count, sizeof(struct sockaddr_in));
	int address_count = 0;
	if(addresses)
	{
		for(int i = 0; i < target_count; i++)
		{
			if(!targets[i])
				continue;
			struct sockaddr_in *address = &addresses[address_count];
			address->sin_family = AF_INET;
			address->sin_port = htons(CHIAKI_DISCOVERY_PORT_PS5);
			if(inet_pton(AF_INET, targets[i], &address->sin_addr) == 1)
				address_count++;
		}
	}

	char version[] = CHIAKI_DISCOVERY_PROTOCOL_VERSION_PS5;
	ChiakiDiscoveryPacket packet;
	memset(&packet, 0, sizeof(packet));
	packet.cmd = CHIAKI_DISCOVERY_CMD_SRCH;
	packet.protocol_version = version;

	/* Yanıt kaçmasın diye arama süre dolana kadar tekrarlanır. */
	uint64_t end = chiaki_time_now_monotonic_ms() + (uint64_t)(timeout_ms > 0 ? timeout_ms : 0);
	do
	{
		for(int i = 0; i < address_count; i++)
			chiaki_discovery_send(&discovery, &packet, (struct sockaddr *)&addresses[i], sizeof(struct sockaddr_in));
		cs_sleep_ms(500);
	} while(chiaki_time_now_monotonic_ms() < end);

	chiaki_discovery_thread_stop(&thread);
	chiaki_discovery_fini(&discovery);
	int result = addresses ? 0 : -1;
	free(addresses);
	return result;
}

CS_API int cs_wake(const char *host, uint64_t credential)
{
	if(!host)
		return 1;
	ChiakiLog log;
	chiaki_log_init(&log, CHIAKI_LOG_ERROR, cs_log_forward, NULL);
	ChiakiErrorCode err = chiaki_discovery_wakeup(&log, NULL, host, credential, true);
	return err == CHIAKI_ERR_SUCCESS ? 0 : (int)err;
}

/* --- Kayıt --- */

static const char cs_reason_prefix[] = "Reported Application Reason: 0x";

/* "Reported Application Reason: 0x80108b02 (...)" satırından nedeni okur; yoksa false. */
static bool cs_reason_from_log(const char *line, uint32_t *reason)
{
	const char *found = line ? strstr(line, cs_reason_prefix) : NULL;
	if(!found)
		return false;
	const char *digits = found + sizeof(cs_reason_prefix) - 1;
	char *end = NULL;
	unsigned long value = strtoul(digits, &end, 16);
	if(end == digits)
		return false;
	*reason = (uint32_t)value;
	return true;
}

typedef struct {
	ChiakiMutex mutex;
	ChiakiCond cond;
	bool done;
	ChiakiRegistEventType type;
	bool has_host;
	ChiakiRegisteredHost host;
	uint32_t reason;
	cs_log_cb log;
	void *user;
} cs_regist_ctx;

static void cs_regist_log(ChiakiLogLevel level, const char *message, void *user)
{
	cs_regist_ctx *ctx = user;
	/* PS5'in red nedeni olaya değil yalnız günlüğe yazılır; olaydan önce aynı iş parçacığında gelir. */
	uint32_t reason;
	if(cs_reason_from_log(message, &reason))
	{
		chiaki_mutex_lock(&ctx->mutex);
		ctx->reason = reason;
		chiaki_mutex_unlock(&ctx->mutex);
	}
	if(ctx->log && message)
		ctx->log(cs_level(level), message, ctx->user);
}

static void cs_regist_event(ChiakiRegistEvent *event, void *user)
{
	cs_regist_ctx *ctx = user;
	chiaki_mutex_lock(&ctx->mutex);
	if(!ctx->done)
	{
		ctx->type = event ? event->type : CHIAKI_REGIST_EVENT_TYPE_FINISHED_FAILED;
		if(event && event->type == CHIAKI_REGIST_EVENT_TYPE_FINISHED_SUCCESS && event->registered_host)
		{
			ctx->host = *event->registered_host;
			ctx->has_host = true;
		}
		ctx->done = true;
	}
	chiaki_mutex_unlock(&ctx->mutex);
	chiaki_cond_signal(&ctx->cond);
}

static bool cs_regist_done(void *user)
{
	return ((cs_regist_ctx *)user)->done;
}

CS_API int cs_register(const char *host, const uint8_t account_id[8], uint32_t pin,
		cs_registered_console *out, uint32_t *reason, cs_log_cb log, void *user)
{
	if(reason)
		*reason = 0;
	if(!host || !account_id || !out)
		return -1;

	cs_regist_ctx *ctx = calloc(1, sizeof(cs_regist_ctx));
	if(!ctx)
		return -1;
	ctx->log = log;
	ctx->user = user;
	if(chiaki_mutex_init(&ctx->mutex, false) != CHIAKI_ERR_SUCCESS)
	{
		free(ctx);
		return -1;
	}
	if(chiaki_cond_init(&ctx->cond) != CHIAKI_ERR_SUCCESS)
	{
		chiaki_mutex_fini(&ctx->mutex);
		free(ctx);
		return -1;
	}

	ChiakiLog regist_log;
	chiaki_log_init(&regist_log, CS_LOG_MASK, cs_regist_log, ctx);

	ChiakiRegistInfo info;
	memset(&info, 0, sizeof(info));
	info.target = CHIAKI_TARGET_PS5_1;
	info.host = host;
	info.broadcast = false;
	info.psn_online_id = NULL;
	memcpy(info.psn_account_id, account_id, CHIAKI_PSN_ACCOUNT_ID_SIZE);
	info.pin = pin;
	info.console_pin = 0;
	info.holepunch_info = NULL;
	info.rudp = NULL;

	ChiakiRegist regist;
	int result;
	ChiakiErrorCode err = chiaki_regist_start(&regist, &regist_log, &info, cs_regist_event, ctx);
	if(err != CHIAKI_ERR_SUCCESS)
	{
		cs_logf(log, user, 0, "Regist start failed: %s", chiaki_error_string(err));
		result = -1;
	}
	else
	{
		chiaki_mutex_lock(&ctx->mutex);
		/* libchiaki'nin kendi zaman aşımları var; yine de yanıt gelmezse 30 sn sonra iptal edilir. */
		err = chiaki_cond_timedwait_pred(&ctx->cond, &ctx->mutex, 30000, cs_regist_done, ctx);
		if(err == CHIAKI_ERR_TIMEOUT)
		{
			chiaki_mutex_unlock(&ctx->mutex);
			chiaki_regist_stop(&regist);
			chiaki_mutex_lock(&ctx->mutex);
			chiaki_cond_wait_pred(&ctx->cond, &ctx->mutex, cs_regist_done, ctx);
		}
		chiaki_mutex_unlock(&ctx->mutex);
		/* Kayıt iş parçacığı geri çağrıdan sonra kapanır; bırakmadan önce beklenir. */
		chiaki_regist_fini(&regist);

		if(ctx->type == CHIAKI_REGIST_EVENT_TYPE_FINISHED_SUCCESS && ctx->has_host)
		{
			memset(out, 0, sizeof(*out));
			memcpy(out->nickname, ctx->host.server_nickname, sizeof(out->nickname));
			out->nickname[sizeof(out->nickname) - 1] = '\0';
			memcpy(out->regist_key, ctx->host.rp_regist_key, sizeof(out->regist_key));
			memcpy(out->morning, ctx->host.rp_key, sizeof(out->morning));
			result = 0;
		}
		else if(ctx->type == CHIAKI_REGIST_EVENT_TYPE_FINISHED_CANCELED)
			result = 2;
		else
		{
			if(reason)
				*reason = ctx->reason;
			result = 1;
		}
	}

	chiaki_cond_fini(&ctx->cond);
	chiaki_mutex_fini(&ctx->mutex);
	free(ctx);
	return result;
}

/* --- Kare sınırlayıcı --- */

/* Saniyede en fazla belirli sayıda karenin geçmesine izin verir (Mac'teki FrameThrottle). */
typedef struct {
	uint64_t min_interval_us;
	uint64_t last_us;
	bool has_last;
} cs_throttle;

static void cs_throttle_init(cs_throttle *throttle, int max_fps)
{
	throttle->min_interval_us = max_fps > 0 ? 1000000ULL / (uint64_t)max_fps : 0;
	throttle->last_us = 0;
	throttle->has_last = false;
}

static bool cs_throttle_should_pass(cs_throttle *throttle, uint64_t now_us)
{
	if(throttle->has_last && now_us - throttle->last_us < throttle->min_interval_us)
		return false;
	throttle->last_us = now_us;
	throttle->has_last = true;
	return true;
}


/* --- H.264 çözücü (VideoToolbox) --- */

/* libchiaki her örneği Annex-B (00 00 00 01 başlangıç kodlu) verir. VideoToolbox uzunluk önekli (AVCC) NAL
 * birimleri ve SPS/PPS'ten kurulmuş bir biçim tanımı ister. Anahtar karelerin önünde SPS/PPS gelir; değişirlerse
 * çözücü yeniden kurulur. */

#define CS_MAX_PARAM 256

typedef struct {
	VTDecompressionSessionRef session;
	CMVideoFormatDescriptionRef format;
	uint8_t sps[CS_MAX_PARAM], pps[CS_MAX_PARAM];
	size_t sps_size, pps_size;
	uint8_t *avcc;          /* uzunluk önekli örnek için yeniden kullanılan tampon */
	size_t avcc_capacity;
	bool want_frame;        /* bu örneğin görüntüsü geri çağrıya verilecek mi (kare sınırlayıcı) */
	bool decode_failed;
	OSStatus last_status;   /* günlüğe yalnız değişince yazılır */
	cs_log_target *log;
	cs_frame_cb frame;
	void *user;
} cs_decoder;

/* Çözücü hatası (ör. arka planda iOS donanım çözücüsünü kapatınca -12903) günlüğe bir kez yazılır. */
static void cs_decoder_note(cs_decoder *decoder, OSStatus status, const char *what)
{
	if(status == decoder->last_status)
		return;
	decoder->last_status = status;
	if(!decoder->log || !decoder->log->cb)
		return;
	char line[128];
	if(status == noErr)
		snprintf(line, sizeof(line), "VideoToolbox: çözücü yeniden çalışıyor");
	else
		snprintf(line, sizeof(line), "VideoToolbox: %s başarısız (%d)", what, (int)status);
	decoder->log->cb(1, line, decoder->log->user);
}

static void cs_decoder_output(void *decompression_ref, void *frame_ref, OSStatus status, VTDecodeInfoFlags flags,
		CVImageBufferRef image, CMTime pts, CMTime duration)
{
	(void)frame_ref;
	(void)flags;
	(void)pts;
	(void)duration;
	cs_decoder *decoder = decompression_ref;
	if(status != noErr || !image)
	{
		decoder->decode_failed = true;
		return;
	}
	if(!decoder->want_frame || !decoder->frame)
		return;
	if(CVPixelBufferLockBaseAddress(image, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess)
		return;
	const uint8_t *base = CVPixelBufferGetBaseAddress(image);
	if(base)
		decoder->frame(base, (int)CVPixelBufferGetWidth(image), (int)CVPixelBufferGetHeight(image),
				(int)CVPixelBufferGetBytesPerRow(image), decoder->user);
	CVPixelBufferUnlockBaseAddress(image, kCVPixelBufferLock_ReadOnly);
}

static void cs_decoder_close_session(cs_decoder *decoder)
{
	if(decoder->session)
	{
		VTDecompressionSessionWaitForAsynchronousFrames(decoder->session);
		VTDecompressionSessionInvalidate(decoder->session);
		CFRelease(decoder->session);
		decoder->session = NULL;
	}
	if(decoder->format)
	{
		CFRelease(decoder->format);
		decoder->format = NULL;
	}
}

static void cs_decoder_init(cs_decoder *decoder, cs_frame_cb frame, void *user, cs_log_target *log)
{
	memset(decoder, 0, sizeof(*decoder));
	decoder->frame = frame;
	decoder->user = user;
	decoder->log = log;
}

static void cs_decoder_fini(cs_decoder *decoder)
{
	cs_decoder_close_session(decoder);
	free(decoder->avcc);
	decoder->avcc = NULL;
	decoder->avcc_capacity = 0;
}

/* Elde SPS ve PPS varsa çözücüyü kurar. */
static bool cs_decoder_open(cs_decoder *decoder)
{
	cs_decoder_close_session(decoder);
	if(!decoder->sps_size || !decoder->pps_size)
		return false;
	const uint8_t *params[2] = { decoder->sps, decoder->pps };
	const size_t sizes[2] = { decoder->sps_size, decoder->pps_size };
	if(CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, params, sizes, 4, &decoder->format) != noErr)
	{
		decoder->format = NULL;
		return false;
	}

	/* Çıktı BGRA: yazı tanıma (Vision) ve önizleme doğrudan kullanır. */
	int32_t pixel_format = kCVPixelFormatType_32BGRA;
	CFNumberRef pixel_number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pixel_format);
	const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
	const void *values[] = { pixel_number };
	CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1,
			&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(pixel_number);

	VTDecompressionOutputCallbackRecord callback = { cs_decoder_output, decoder };
	OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault, decoder->format, NULL, attributes, &callback, &decoder->session);
	CFRelease(attributes);
	if(status != noErr)
	{
		cs_decoder_note(decoder, status, "oturum kurulumu");
		decoder->session = NULL;
		cs_decoder_close_session(decoder);
		return false;
	}
	/* Gerçek zamanlı akış: gecikme biriktirmesin. */
	VTSessionSetProperty(decoder->session, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
	return true;
}

/* Annex-B'deki bir sonraki NAL birimini bulur. Dönüş: birimin başı (başlangıç kodundan sonra) ya da NULL. */
static const uint8_t *cs_next_nal(const uint8_t *data, size_t size, size_t *pos, size_t *nal_size)
{
	size_t i = *pos;
	/* Başlangıç kodunu (00 00 01 ya da 00 00 00 01) atla. */
	while(i + 3 <= size && !(data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 1))
		i++;
	if(i + 3 > size)
		return NULL;
	size_t start = i + 3;
	size_t j = start;
	while(j + 3 <= size && !(data[j] == 0 && data[j + 1] == 0 && (data[j + 2] == 1 || (data[j + 2] == 0 && j + 3 < size && data[j + 3] == 1))))
		j++;
	size_t end = j + 3 <= size ? j : size;
	*pos = end;
	*nal_size = end - start;
	return data + start;
}

/* Bir Annex-B örneğini çözer. want_frame ise görüntü geri çağrıya verilir.
 * Dönüş: false ise örnek çözülemedi; libchiaki bozuk kare bildirip yeni anahtar kare ister. */
static bool cs_decoder_feed(cs_decoder *decoder, const uint8_t *data, size_t size, bool want_frame)
{
	if(!data || !size)
		return true;

	/* Önce parametre kümeleri: değiştiyse çözücü yeniden kurulur. */
	bool params_changed = false;
	size_t avcc_size = 0;
	if(decoder->avcc_capacity < size + 64)
	{
		uint8_t *grown = realloc(decoder->avcc, size + 64);
		if(!grown)
			return false;
		decoder->avcc = grown;
		decoder->avcc_capacity = size + 64;
	}
	size_t pos = 0, nal_size = 0;
	const uint8_t *nal;
	while((nal = cs_next_nal(data, size, &pos, &nal_size)))
	{
		/* Sondaki sıfır doldurma baytları (trailing zero) birimin parçası değildir. */
		while(nal_size > 0 && nal[nal_size - 1] == 0)
			nal_size--;
		if(!nal_size)
			continue;
		int type = nal[0] & 0x1f;
		if(type == 7 || type == 8)
		{
			uint8_t *target = type == 7 ? decoder->sps : decoder->pps;
			size_t *target_size = type == 7 ? &decoder->sps_size : &decoder->pps_size;
			if(nal_size <= CS_MAX_PARAM && (nal_size != *target_size || memcmp(target, nal, nal_size) != 0))
			{
				memcpy(target, nal, nal_size);
				*target_size = nal_size;
				params_changed = true;
			}
			continue;
		}
		if(type == 9) /* erişim birimi ayıracı: VideoToolbox'a gerekmez */
			continue;
		uint32_t length = (uint32_t)nal_size;
		decoder->avcc[avcc_size + 0] = (uint8_t)(length >> 24);
		decoder->avcc[avcc_size + 1] = (uint8_t)(length >> 16);
		decoder->avcc[avcc_size + 2] = (uint8_t)(length >> 8);
		decoder->avcc[avcc_size + 3] = (uint8_t)length;
		memcpy(decoder->avcc + avcc_size + 4, nal, nal_size);
		avcc_size += 4 + nal_size;
	}

	if(params_changed || !decoder->session)
	{
		if(!cs_decoder_open(decoder))
			/* SPS/PPS henüz gelmediyse anahtar kare istenir. */
			return decoder->sps_size == 0 && avcc_size == 0;
	}
	if(!avcc_size)
		return true;

	CMBlockBufferRef block = NULL;
	if(CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, decoder->avcc, avcc_size, kCFAllocatorNull, NULL, 0, avcc_size, 0, &block) != noErr)
		return false;
	CMSampleBufferRef sample = NULL;
	const size_t sample_sizes[] = { avcc_size };
	OSStatus status = CMSampleBufferCreateReady(kCFAllocatorDefault, block, decoder->format, 1, 0, NULL, 1, sample_sizes, &sample);
	CFRelease(block);
	if(status != noErr)
		return false;

	decoder->want_frame = want_frame;
	decoder->decode_failed = false;
	/* Bayraksız çağrı eşzamanlıdır: çıktı geri çağrısı dönüşten önce gelir. */
	VTDecodeInfoFlags info = 0;
	status = VTDecompressionSessionDecodeFrame(decoder->session, sample, 0, NULL, &info);
	CFRelease(sample);
	if(status != noErr || decoder->decode_failed)
		cs_decoder_note(decoder, status != noErr ? status : -1, "kare çözme");
	else
		cs_decoder_note(decoder, noErr, NULL);
	if(status == kVTInvalidSessionErr)
	{
		/* Uygulama arka plana gidince iOS çözücüyü kapatır: yeniden kurulup anahtar kare istenir. */
		cs_decoder_close_session(decoder);
		return false;
	}
	return status == noErr && !decoder->decode_failed;
}

/* --- Görüntü akışı --- */

struct cs_session {
	ChiakiSession session;
	ChiakiLog log;
	cs_log_target log_target;
	cs_frame_cb frame;
	cs_event_cb event;
	void *user;
	cs_decoder decoder;
	cs_throttle throttle;
};

static int cs_quit_reason(ChiakiQuitReason reason)
{
	switch(reason)
	{
		case CHIAKI_QUIT_REASON_STOPPED:
			return CS_QUIT_STOPPED;
		case CHIAKI_QUIT_REASON_SESSION_REQUEST_RP_IN_USE:
			return CS_QUIT_IN_USE;
		case CHIAKI_QUIT_REASON_SESSION_REQUEST_CONNECTION_REFUSED:
		case CHIAKI_QUIT_REASON_CTRL_CONNECTION_REFUSED:
		case CHIAKI_QUIT_REASON_PSN_REGIST_FAILED:
			return CS_QUIT_REFUSED;
		case CHIAKI_QUIT_REASON_STREAM_CONNECTION_REMOTE_DISCONNECTED:
		case CHIAKI_QUIT_REASON_STREAM_CONNECTION_REMOTE_SHUTDOWN:
		case CHIAKI_QUIT_REASON_CTRL_CONNECT_FAILED:
		case CHIAKI_QUIT_REASON_STREAM_CONNECTION_UNKNOWN:
			return CS_QUIT_NETWORK;
		default:
			return CS_QUIT_OTHER;
	}
}

/* libchiaki'nin oturum iş parçacığında çağrılır. */
static void cs_session_event(ChiakiEvent *event, void *user)
{
	cs_session *session = user;
	if(!event || !session->event)
		return;
	switch(event->type)
	{
		case CHIAKI_EVENT_CONNECTED:
			session->event(CS_EVENT_CONNECTED, 0, NULL, session->user);
			break;
		case CHIAKI_EVENT_LOGIN_PIN_REQUEST:
			session->event(CS_EVENT_LOGIN_PIN, 0, NULL, session->user);
			break;
		case CHIAKI_EVENT_QUIT:
		{
			int reason = cs_quit_reason(event->quit.reason);
			const char *text = reason == CS_QUIT_OTHER ? chiaki_quit_reason_string(event->quit.reason) : event->quit.reason_str;
			session->event(CS_EVENT_QUIT, reason, text, session->user);
			break;
		}
		default:
			break;
	}
}

/* Akış iş parçacığında çağrılır. Her örnek çözülür, görüntü en çok max_fps kez verilir. */
static bool cs_session_video_sample(uint8_t *buf, size_t buf_size, int32_t frames_lost, bool frame_recovered, void *user)
{
	(void)frames_lost;
	(void)frame_recovered;
	cs_session *session = user;
	bool want = session->frame && cs_throttle_should_pass(&session->throttle, chiaki_time_now_monotonic_us());
	return cs_decoder_feed(&session->decoder, buf, buf_size, want);
}

CS_API cs_session *cs_session_start(const char *host, const uint8_t regist_key[0x10], const uint8_t morning[0x10],
		const uint8_t account_id[8], int max_fps,
		cs_frame_cb frame, cs_event_cb event, cs_log_cb log, void *user)
{
	if(!host || !regist_key || !morning || !account_id)
		return NULL;

	cs_session *session = calloc(1, sizeof(cs_session));
	if(!session)
		return NULL;
	session->frame = frame;
	session->event = event;
	session->user = user;
	session->log_target.cb = log;
	session->log_target.user = user;
	chiaki_log_init(&session->log, CS_LOG_MASK, cs_log_forward, &session->log_target);
	cs_throttle_init(&session->throttle, max_fps);
	cs_decoder_init(&session->decoder, frame, user, &session->log_target);

	ChiakiConnectInfo info;
	memset(&info, 0, sizeof(info));
	info.ps5 = true;
	info.host = host; /* libchiaki adresi oturum açılırken kopyalar */
	memcpy(info.regist_key, regist_key, sizeof(info.regist_key));
	memcpy(info.morning, morning, sizeof(info.morning));
	chiaki_connect_video_profile_preset(&info.video_profile, CHIAKI_VIDEO_RESOLUTION_PRESET_1080p, CHIAKI_VIDEO_FPS_PRESET_30);
	info.video_profile.codec = CHIAKI_CODEC_H264;
	info.video_profile_auto_downgrade = true;
	info.enable_keyboard = false;
	info.enable_dualsense = false;
	info.audio_video_disabled = CHIAKI_AUDIO_DISABLED;
	info.auto_regist = false;
	info.holepunch_session = NULL;
	info.rudp_sock = NULL;
	memcpy(info.psn_account_id, account_id, CHIAKI_PSN_ACCOUNT_ID_SIZE);
	info.packet_loss_max = 0.05;
	info.enable_idr_on_fec_failure = true;

	ChiakiErrorCode err = chiaki_session_init(&session->session, &info, &session->log);
	if(err != CHIAKI_ERR_SUCCESS)
	{
		cs_logf(log, user, 0, "Session init failed: %s", chiaki_error_string(err));
		cs_decoder_fini(&session->decoder);
		free(session);
		return NULL;
	}
	chiaki_session_set_event_cb(&session->session, cs_session_event, session);
	chiaki_session_set_video_sample_cb(&session->session, cs_session_video_sample, session);

	err = chiaki_session_start(&session->session);
	if(err != CHIAKI_ERR_SUCCESS)
	{
		/* Başlamamış oturumun beklenecek iş parçacığı yok; yalnız bellek bırakılır. */
		cs_logf(log, user, 0, "Session start failed: %s", chiaki_error_string(err));
		chiaki_session_fini(&session->session);
		cs_decoder_fini(&session->decoder);
		free(session);
		return NULL;
	}
	return session;
}

CS_API void cs_session_stop(cs_session *session)
{
	if(!session)
		return;
	/* Durdurma, iş parçacıkları beklenene (join) kadar sürer; sonrasında hiçbir geri çağrı gelmez
	 * ve bellek güvenle bırakılabilir. Aynı oturum için yalnız bir kez çağrılmalı. */
	chiaki_session_stop(&session->session);
	chiaki_session_join(&session->session);
	chiaki_session_fini(&session->session);
	cs_decoder_fini(&session->decoder);
	free(session);
}
