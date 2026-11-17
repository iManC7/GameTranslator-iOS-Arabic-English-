// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyPair
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.RSAPublicKey

/** ADB ile sdb'nin farkları: sürüm, karşılama yazısı, paket boyu, jetonun nasıl imzalandığı. */
class AdbOptions(
    val version: Int,
    val banner: String,
    val offeredMaxPayload: Int,
    /** true: jeton özet yerine geçer (adb); false: jeton SHA-1 ile özetlenip imzalanır (sdb). */
    val rawTokenSignature: Boolean,
    val keyName: String,
    /** sync SEND isteğine ",izinler" eklensin mi (adb ekler; TizenSdb eklemez, sdbd 0644 varsayar). */
    val sendMode: Boolean,
) {
    companion object {
        val ADB = AdbOptions(0x01000001, "host::\u0000", 256 * 1024, true, "gametranslator@GameTranslator", true)
        val SDB = AdbOptions(0x01000000, "host::sdb-net-client", 4096, false, "gametranslator@GameTranslator", false)
    }
}

/**
 * ADB (ve Samsung'un sdb'si) protokolünün ağ üzerinden kullanılan küçük bir parçası: bağlantı, RSA kimlik doğrulama
 * ve aynı anda tek akış. Google'ın adb aracını taşımadan TV'ye uygulama kurmaya yeter. Windows'taki AdbConnection.cs
 * ve TizenSdb'nin SdbTcpDevice'ının Kotlin karşılığı. Bütün çağrılar bloklar; ana iş parçacığında çağrılmamalı.
 */
class AdbClient(
    private val input: InputStream,
    private val output: OutputStream,
    private val options: AdbOptions,
    /** Okuma zaman aşımını değiştirir (soket yoksa testlerde boş). */
    private val setTimeout: (Int) -> Unit = {},
    private val closeable: Closeable? = null,
) : Closeable {
    var maxPayload = 4096
        private set

    /** TV'nin karşılama yazısı (ör. "device::ro.product.name=...;"). */
    var banner = ""
        private set

    private var nextLocalId = 1

    /**
     * Karşılaşma: CNXN, gerekirse AUTH. [onApprovalNeeded]: TV bu telefonu ilk kez görüyor, ekranda "hata ayıklamaya
     * izin verilsin mi" sorusu çıktı. Onay için [approvalTimeoutMs] beklenir.
     */
    fun handshake(key: KeyPair, onApprovalNeeded: () -> Unit = {}, approvalTimeoutMs: Int = 90_000) {
        write(Adb.CNXN, options.version, options.offeredMaxPayload, options.banner.toByteArray(Charsets.US_ASCII))
        var signed = false
        var waitingForApproval = false
        setTimeout(10_000)
        while (true) {
            val packet = try {
                Adb.read(input)
            } catch (error: IOException) {
                // Onay beklenirken bağlantı kapandıysa ya da süre dolduysa kullanıcı izin vermedi.
                throw TvInstallException(if (waitingForApproval) TvError.NOT_APPROVED else TvError.UNREACHABLE, error.message, error)
            }
            when {
                packet.command == Adb.CNXN -> {
                    maxPayload = minOf(options.offeredMaxPayload, if (packet.arg1 <= 0) 4096 else packet.arg1)
                    banner = String(packet.data, Charsets.UTF_8).trimEnd('\u0000')
                    return
                }
                packet.command == Adb.AUTH && packet.arg0 == Adb.AUTH_TOKEN && !signed -> {
                    signed = true
                    val private = key.private as RSAPrivateKey
                    val signature = if (options.rawTokenSignature) Adb.signToken(private, packet.data) else Adb.signSha1(private, packet.data)
                    write(Adb.AUTH, Adb.AUTH_SIGNATURE, 0, signature)
                }
                packet.command == Adb.AUTH && (packet.arg0 == Adb.AUTH_TOKEN || packet.arg0 == Adb.AUTH_PUBLICKEY) && !waitingForApproval -> {
                    // İmza tanınmadı: TV bu anahtarı ilk kez görüyor. Açık anahtarı gönderince TV kullanıcıya sorar.
                    sendPublicKey(key)
                    waitingForApproval = true
                    setTimeout(approvalTimeoutMs)
                    onApprovalNeeded()
                }
                packet.command == Adb.AUTH -> Unit // onay beklenirken gelen yeni jeton: kullanıcının yanıtı bekleniyor
                else -> throw TvInstallException(TvError.UNREACHABLE, "beklenmeyen paket $packet")
            }
        }
    }

    private fun sendPublicKey(key: KeyPair) {
        write(Adb.AUTH, Adb.AUTH_PUBLICKEY, 0, Adb.publicKeyPayload(key.public as RSAPublicKey, options.keyName))
    }

    /** Okuma zaman aşımı (milisaniye) sonraki komutlar için. */
    fun timeout(millis: Int) = setTimeout(millis)

    /** Bir hizmet açar (ör. `shell:…`, `exec:…`, `sync:`). Hizmet açılamazsa hata verir. */
    fun open(service: String): AdbStream {
        val localId = nextLocalId++
        write(Adb.OPEN, localId, 0, (service + "\u0000").toByteArray(Charsets.UTF_8))
        val stream = AdbStream(localId)
        while (stream.remoteId == 0) {
            val packet = Adb.read(input)
            if (packet.arg1 != localId) continue
            when (packet.command) {
                Adb.OKAY -> stream.remoteId = packet.arg0
                Adb.CLSE -> throw TvInstallException(TvError.INSTALL_FAILED, "$service açılamadı")
                Adb.WRTE -> {
                    stream.received(packet)
                    if (stream.remoteId == 0) stream.remoteId = packet.arg0
                }
            }
        }
        return stream
    }

    /**
     * Hizmeti açar, varsa [data]'yı gönderir ve hizmet kapanana kadar çıktıyı toplar. [onSent]: gönderilen bayt
     * sayısı (ilerleme için).
     */
    fun run(service: String, data: ByteArray? = null, onSent: (Int) -> Unit = {}): String {
        val stream = open(service)
        try {
            if (data != null) {
                var offset = 0
                while (offset < data.size && !stream.closed) {
                    val length = minOf(maxPayload, data.size - offset)
                    stream.write(data, offset, length)
                    offset += length
                    onSent(offset)
                }
            }
            return String(stream.readAll(), Charsets.UTF_8)
        } finally {
            stream.close()
        }
    }

    /** Dosyayı sync hizmetiyle TV'ye yazar. */
    fun push(data: ByteArray, remotePath: String, mode: Int = 0x1A4 /* 0644 */, onSent: (Int) -> Unit = {}) {
        val stream = open("sync:")
        try {
            val path = if (options.sendMode) "$remotePath,${0x8000 or mode}" else remotePath
            stream.write(syncPacket("SEND", path.toByteArray(Charsets.UTF_8)))
            var offset = 0
            while (offset < data.size) {
                val length = minOf(SYNC_DATA, data.size - offset)
                stream.write(syncPacket("DATA", data, offset, length))
                offset += length
                onSent(offset)
            }
            stream.write(syncHeader("DONE", (System.currentTimeMillis() / 1000).toInt()))
            val reply = stream.readExactly(8)
            val id = String(reply, 0, 4, Charsets.US_ASCII)
            if (id != "OKAY") {
                val length = ByteBuffer.wrap(reply, 4, 4).order(ByteOrder.LITTLE_ENDIAN).int
                val message = if (id == "FAIL" && length in 1..4096) String(stream.readExactly(length), Charsets.UTF_8) else id
                throw TvInstallException(TvError.INSTALL_FAILED, "dosya TV'ye yazılamadı: $message")
            }
            runCatching { stream.write(syncHeader("QUIT", 0)) }
        } finally {
            stream.close()
        }
    }

    private fun write(command: Int, arg0: Int, arg1: Int, data: ByteArray, offset: Int = 0, length: Int = data.size) {
        output.write(Adb.encode(command, arg0, arg1, data, offset, length))
        output.flush()
    }

    override fun close() {
        runCatching { closeable?.close() }
    }

    /** Açık bir akış. Aynı anda tek akış kullanılır; başka akışların paketleri atlanır. */
    inner class AdbStream internal constructor(private val localId: Int) {
        var remoteId = 0
            internal set
        var closed = false
            private set
        private val pending = ArrayDeque<ByteArray>()
        private var head: ByteArray? = null
        private var headOffset = 0

        internal fun received(packet: Adb.Packet) {
            when (packet.command) {
                Adb.WRTE -> {
                    if (packet.data.isNotEmpty()) pending.addLast(packet.data)
                    write(Adb.OKAY, localId, packet.arg0, EMPTY)
                }
                Adb.CLSE -> closed = true
            }
        }

        /** Parçayı gönderir ve TV'nin aldığını (OKAY) bekler; arada gelen çıktı saklanır. */
        fun write(data: ByteArray, offset: Int = 0, length: Int = data.size) {
            var position = offset
            while (position < offset + length) {
                if (closed) throw IOException("akış kapandı")
                val size = minOf(maxPayload, offset + length - position)
                this@AdbClient.write(Adb.WRTE, localId, remoteId, data, position, size)
                position += size
                while (true) {
                    val packet = Adb.read(input)
                    if (packet.arg1 != localId) continue
                    if (packet.command == Adb.OKAY) break
                    received(packet)
                    if (closed) break
                }
            }
        }

        /** Sonraki çıktı parçası; akış kapandıysa null. */
        fun read(): ByteArray? {
            pending.removeFirstOrNull()?.let { return it }
            while (!closed) {
                val packet = Adb.read(input)
                if (packet.arg1 != localId) continue
                received(packet)
                pending.removeFirstOrNull()?.let { return it }
            }
            return null
        }

        fun readExactly(count: Int): ByteArray {
            val out = ByteArray(count)
            var filled = 0
            while (filled < count) {
                val chunk = head ?: read()?.also { head = it; headOffset = 0 } ?: throw IOException("akış erken kapandı")
                val n = minOf(count - filled, chunk.size - headOffset)
                System.arraycopy(chunk, headOffset, out, filled, n)
                filled += n
                headOffset += n
                if (headOffset >= chunk.size) head = null
            }
            return out
        }

        fun readAll(): ByteArray {
            val out = ByteArrayOutputStream()
            head?.let { out.write(it, headOffset, it.size - headOffset) }
            head = null
            while (true) out.write(read() ?: break)
            return out.toByteArray()
        }

        fun close() {
            if (!closed) {
                closed = true
                runCatching { this@AdbClient.write(Adb.CLSE, localId, remoteId, EMPTY) }
            }
        }
    }

    companion object {
        private val EMPTY = ByteArray(0)
        private const val SYNC_DATA = 64 * 1024

        fun syncHeader(id: String, value: Int): ByteArray =
            ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).put(id.toByteArray(Charsets.US_ASCII)).putInt(value).array()

        fun syncPacket(id: String, data: ByteArray, offset: Int = 0, length: Int = data.size): ByteArray =
            ByteBuffer.allocate(8 + length).order(ByteOrder.LITTLE_ENDIAN)
                .put(id.toByteArray(Charsets.US_ASCII)).putInt(length).put(data, offset, length).array()

        /**
         * TV'ye bağlanır ve karşılaşmayı yapar. Bağlanamazsa [TvError.UNREACHABLE]; [cancel] soketi kapatabilir.
         */
        fun connect(
            host: String,
            port: Int,
            key: KeyPair,
            options: AdbOptions,
            cancel: Cancel,
            onApprovalNeeded: () -> Unit = {},
            approvalTimeoutMs: Int = 90_000,
            connectTimeoutMs: Int = 5_000,
        ): AdbClient {
            val socket = cancel.track(Socket())
            try {
                cancel.guard {
                    try {
                        socket.tcpNoDelay = true
                        socket.connect(InetSocketAddress(host, port), connectTimeoutMs)
                    } catch (error: IOException) {
                        throw TvInstallException(TvError.UNREACHABLE, error.message, error)
                    }
                }
                val client = AdbClient(socket.getInputStream(), socket.getOutputStream(), options, { socket.soTimeout = it }, socket)
                cancel.guard { client.handshake(key, onApprovalNeeded, approvalTimeoutMs) }
                return client
            } catch (error: Exception) {
                runCatching { socket.close() }
                cancel.untrack(socket)
                if (error is SocketTimeoutException) throw TvInstallException(TvError.UNREACHABLE, error.message, error)
                throw error
            }
        }
    }
}
