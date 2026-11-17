// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile

import java.nio.ByteBuffer

/** libgtnative.so (libchiaki + MediaCodec) işlevleri; gt_jni.c bu sınıfa bağlar. Hepsi bloklayabilir, ana iş parçacığında çağrılmaz. */
object Native {
    interface ConsoleCallback {
        /** Bulunan her PS5 için (aynı PS5 birden çok kez gelebilir). [name] UTF-8 baytlarıdır. */
        fun onConsole(host: String, name: ByteArray, awake: Boolean)
    }

    interface LogCallback {
        /** level: 0 hata, 1 uyarı, 2 bilgi. */
        fun onLog(level: Int, message: String?)
    }

    interface SessionListener : LogCallback {
        /** RGBA kare; [buffer] yalnız çağrı süresince geçerlidir, içinde kopyalanmalıdır. */
        fun onFrame(buffer: ByteBuffer, width: Int, height: Int, stride: Int)
        /** event: 0 bağlandı, 1 kapandı ([quitReason]: QUIT_*), 2 PS5 giriş şifresi istiyor. */
        fun onEvent(event: Int, quitReason: Int, reasonText: String?)
    }

    const val EVENT_CONNECTED = 0
    const val EVENT_QUIT = 1
    const val EVENT_LOGIN_PIN = 2

    const val QUIT_STOPPED = 0
    const val QUIT_IN_USE = 1
    const val QUIT_REFUSED = 2
    const val QUIT_NETWORK = 3
    const val QUIT_OTHER = 4

    /** Kayıt çıktısı: ad 32 bayt, kayıt anahtarı 16, oturum anahtarı 16. */
    const val REGISTERED_SIZE = 64

    val available: Boolean by lazy {
        try {
            System.loadLibrary("gtnative")
            init() == 0
        } catch (error: UnsatisfiedLinkError) {
            false
        }
    }

    external fun init(): Int
    external fun discover(targets: Array<String>, timeoutMs: Int, callback: ConsoleCallback): Int
    external fun wake(host: String, credential: Long): Int
    /** Dönüş: 0 başarı, 1 başarısız ([reason][0] PS5'in nedeni), 2 iptal, <0 başlatılamadı. */
    external fun register(host: String, accountId: ByteArray, pin: Int, out: ByteArray, reason: IntArray, log: LogCallback?): Int
    /** Dönüş: oturum tutamağı ya da 0. */
    external fun sessionStart(host: String, registKey: ByteArray, morning: ByteArray, accountId: ByteArray, maxFps: Int, listener: SessionListener): Long
    external fun sessionStop(handle: Long)
}
