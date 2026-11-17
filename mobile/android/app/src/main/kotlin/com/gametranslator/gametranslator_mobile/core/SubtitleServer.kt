// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.Locale
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.max
import kotlin.math.min

/** Oyundaki altyazının ekrandaki yeri, kenarlara oranla (0–1). */
data class TextBox(val left: Double, val top: Double, val right: Double, val bottom: Double)

/** TV'de altyazının görünümü (Windows'taki SubtitleStyle ile aynı alanlar). */
data class SubtitleStyle(
    val fontSize: Int = 46,
    val bottomPercent: Int = 7,
    /** cover, above, below, fixed */
    val placement: String = "cover",
    val background: Int = 72,
    val bold: Boolean = false,
    /** white, yellow */
    val textColor: String = "white",
    /** inApp, overlay (yalnız Android TV uygulaması kullanır) */
    val displayMode: String = "inApp",
    val stackPrevious: Boolean = true,
)

/**
 * TV uygulamasının bağlandığı yerel Server-Sent Events sunucusu. `GET /events` akışında `subtitle`, `clear` ve
 * `style` olaylarını yayınlar; `GET /hello` ile TV telefonu ağda tanır. Windows'taki SubtitleServer.cs ile aynı protokol.
 */
class SubtitleServer(private val port: Int = DEFAULT_PORT, private val pingIntervalMs: Long = 15000) {
    /** /obs adresinde sunulan sayfa; verilmediyse adres 404 döner. */
    @Volatile var overlayPage: ByteArray? = null

    companion object {
        const val DEFAULT_PORT = 8787
        internal const val PING_FRAME = ": ping\n\nevent: ping\ndata: {}\n\n"
        /** TV uygulaması yanıtta küçük harfle "gametranslator" arar. */
        internal const val HELLO_BODY = "{\"app\":\"gametranslator\"}"

        internal fun jsonString(text: String): String {
            val out = StringBuilder(text.length + 2).append('"')
            for (c in text) when (c) {
                '"' -> out.append("\\\"")
                '\\' -> out.append("\\\\")
                '\n' -> out.append("\\n")
                '\r' -> out.append("\\r")
                '\t' -> out.append("\\t")
                else -> if (c < ' ') out.append(String.format(Locale.ROOT, "\\u%04x", c.code)) else out.append(c)
            }
            return out.append('"').toString()
        }

        /** Dört basamağa yuvarlanır, sondaki sıfırlar atılır (0.8750 → 0.875). */
        internal fun number(value: Double): String {
            val text = String.format(Locale.ROOT, "%.4f", min(1.0, max(0.0, value))).trimEnd('0').trimEnd('.')
            return if (text.isEmpty()) "0" else text
        }

        internal fun boxJson(b: TextBox) =
            "{\"bottom\":${number(b.bottom)},\"left\":${number(b.left)},\"right\":${number(b.right)},\"top\":${number(b.top)}}"

        internal fun frame(name: String, json: String) = "event: $name\ndata: $json\n\n"

        internal fun subtitleFrame(text: String, durationMs: Int, box: TextBox?, replaces: Boolean, at: Long): String {
            val json = StringBuilder("{\"at\":").append(at)
            if (box != null) json.append(",\"box\":").append(boxJson(box))
            json.append(",\"duration\":").append(durationMs)
            if (replaces) json.append(",\"replace\":true")
            json.append(",\"text\":").append(jsonString(text)).append('}')
            return frame("subtitle", json.toString())
        }

        internal fun styleFrame(s: SubtitleStyle) = frame("style",
            "{\"background\":${min(100, max(0, s.background))},\"bold\":${s.bold},\"bottomPercent\":${s.bottomPercent}," +
                "\"displayMode\":${jsonString(s.displayMode)},\"fontSize\":${s.fontSize},\"placement\":${jsonString(s.placement)}," +
                "\"stackPrevious\":${s.stackPrevious},\"textColor\":${jsonString(s.textColor)}}")
    }

    private class Client(val socket: Socket, val viewer: Boolean) {
        val out: OutputStream = socket.getOutputStream()
        val writeLock = Any()
    }

    private val clients = CopyOnWriteArrayList<Client>()
    private var listener: ServerSocket? = null
    private var pingTimer: ScheduledExecutorService? = null
    private val workers = Executors.newCachedThreadPool { r -> Thread(r, "gt-subtitle-server").apply { isDaemon = true } }
    @Volatile private var lastStyle: SubtitleStyle? = null

    /** Bağlı TV sayısı değişince çağrılır (sunucu iş parçacığında). */
    var onClientsChanged: ((Int) -> Unit)? = null

    val connectedClients: Int get() = clients.count { !it.viewer }

    /** Dinlenen port; başlamadıysa 0. */
    @Volatile var boundPort: Int = 0
        private set

    /** Sunucuyu başlatır ve dinlenen portu döner. Port doluysa rastgele bir port seçilir (TV zaten ağı tarar: yalnız 8787). */
    @Synchronized
    fun start(): Int {
        if (listener != null) return boundPort
        val server = try {
            ServerSocket().apply { reuseAddress = true; bind(InetSocketAddress(port)) }
        } catch (error: java.io.IOException) {
            ServerSocket(0)
        }
        listener = server
        boundPort = server.localPort
        workers.execute { acceptLoop(server) }
        pingTimer = Executors.newSingleThreadScheduledExecutor { r -> Thread(r, "gt-subtitle-ping").apply { isDaemon = true } }.also {
            it.scheduleAtFixedRate({ broadcast(PING_FRAME) }, pingIntervalMs, pingIntervalMs, TimeUnit.MILLISECONDS)
        }
        return boundPort
    }

    @Synchronized
    fun stop() {
        pingTimer?.shutdownNow()
        pingTimer = null
        try { listener?.close() } catch (_: java.io.IOException) {}
        listener = null
        boundPort = 0
        val closing = clients.toList()
        clients.clear()
        for (client in closing) close(client.socket)
        onClientsChanged?.invoke(0)
    }

    fun sendSubtitle(text: String, durationMs: Int = 15000, box: TextBox? = null, replaces: Boolean = false) =
        broadcast(subtitleFrame(text, durationMs, box, replaces, System.currentTimeMillis()))

    fun clear() = broadcast(frame("clear", "{}"))

    fun sendStyle(style: SubtitleStyle) {
        lastStyle = style
        broadcast(styleFrame(style))
    }

    private fun acceptLoop(server: ServerSocket) {
        while (true) {
            val socket = try { server.accept() } catch (error: java.io.IOException) { return }
            workers.execute { serve(socket) }
        }
    }

    private fun serve(socket: Socket) {
        try {
            socket.keepAlive = true
            // Altyazı çerçeveleri küçüktür; Nagle beklemesi her satırı TV'ye geç ulaştırmasın.
            socket.tcpNoDelay = true
            socket.soTimeout = 10000
            val requestLine = readRequestLine(socket) ?: return close(socket)
            val parts = requestLine.split(' ')
            val method = parts.getOrElse(0) { "" }
            val target = parts.getOrElse(1) { "" }
            val path = target.substringBefore('?')
            when {
                method == "OPTIONS" -> respondAndClose(socket, "204 No Content", "")
                method == "GET" && path == "/events" -> openStream(socket, target.contains("viewer=obs"))
                method == "GET" && path == "/hello" -> respondAndClose(socket, "200 OK", HELLO_BODY)
                method == "GET" && path == "/obs" -> overlayPage?.let { respondPage(socket, it) } ?: respondAndClose(socket, "404 Not Found", "")
                else -> respondAndClose(socket, "404 Not Found", "")
            }
        } catch (error: java.io.IOException) {
            close(socket)
        }
    }

    /** Başlıkların sonuna (boş satır) kadar okur, ilk satırı döner. 64 KB'yi aşan istek kapatılır. */
    private fun readRequestLine(socket: Socket): String? {
        val input = socket.getInputStream()
        val head = ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (head.size() < 65536) {
            val count = input.read(buffer)
            if (count <= 0) return null
            head.write(buffer, 0, count)
            val text = head.toString("US-ASCII")
            if (text.contains("\r\n\r\n")) return text.substringBefore("\r\n")
        }
        return null
    }

    /** Tarayıcıda ya da OBS'te açılan altyazı sayfası (Windows'taki /obs ile aynı dosya). */
    private fun respondPage(socket: Socket, page: ByteArray) {
        val head = "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text/html; charset=utf-8\r\n" +
            "Cache-Control: no-cache\r\nContent-Length: ${page.size}\r\nConnection: close\r\n\r\n"
        socket.getOutputStream().apply { write(head.toByteArray(Charsets.US_ASCII)); write(page); flush() }
        close(socket)
    }

    private fun respondAndClose(socket: Socket, status: String, body: String) {
        val head = "HTTP/1.1 $status\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: ${body.length}\r\nConnection: close\r\n\r\n$body"
        socket.getOutputStream().apply { write(head.toByteArray(Charsets.US_ASCII)); flush() }
        close(socket)
    }

    private fun openStream(socket: Socket, viewer: Boolean) {
        val head = StringBuilder()
            .append("HTTP/1.1 200 OK\r\n")
            .append("Content-Type: text/event-stream; charset=utf-8\r\n")
            .append("Cache-Control: no-cache\r\n")
            .append("Connection: keep-alive\r\n")
            .append("Access-Control-Allow-Origin: *\r\n\r\n")
            .append("retry: 2000\n\n")
        lastStyle?.let { head.append(styleFrame(it)) }
        val client = Client(socket, viewer)
        socket.soTimeout = 0
        write(client, head.toString())
        clients.add(client)
        onClientsChanged?.invoke(connectedClients)
        // İstemci bağlantıyı kapattığında listeden çıkarılır.
        try {
            val input = socket.getInputStream()
            val buffer = ByteArray(1024)
            while (input.read(buffer) > 0) { /* gelen veri yok sayılır */ }
        } catch (_: java.io.IOException) {
        }
        remove(client)
    }

    private fun remove(client: Client) {
        if (!clients.remove(client)) return
        close(client.socket)
        onClientsChanged?.invoke(connectedClients)
    }

    /** Gönderim hatası alan bağlantı kopmuş sayılır ve listeden çıkarılır. */
    private fun broadcast(frame: String) {
        for (client in clients) {
            workers.execute {
                try { write(client, frame) } catch (error: java.io.IOException) { remove(client) }
            }
        }
    }

    private fun write(client: Client, text: String) {
        synchronized(client.writeLock) {
            client.out.write(text.toByteArray(Charsets.UTF_8))
            client.out.flush()
        }
    }

    private fun close(socket: Socket) {
        try { socket.close() } catch (_: java.io.IOException) {}
    }
}
