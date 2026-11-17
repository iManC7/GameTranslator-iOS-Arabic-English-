// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.InetSocketAddress
import java.net.Socket

/**
 * Yerel ağdaki TV'lere düz HTTP GET (LG Key Server, LG/Samsung cihaz bilgisi). Android, uygulamanın şifresiz HTTP
 * kullanmasını varsayılan olarak engeller; TV adresleri önceden bilinmediği için ağ güvenliği ayarında tek tek
 * izin verilemez. İstek doğrudan soketle yapılır; yalnız yerel ağdaki adreslere gider.
 */
object LanHttp {
    class Response(val status: Int, val body: ByteArray) {
        val text: String get() = String(body, Charsets.UTF_8)
    }

    fun get(host: String, port: Int, path: String, timeoutMs: Int = 4000, cancel: Cancel = Cancel.NONE): Response {
        val socket = Socket()
        if (cancel !== Cancel.NONE) cancel.track(socket)
        try {
            socket.connect(InetSocketAddress(host, port), timeoutMs)
            socket.soTimeout = timeoutMs
            val request = "GET $path HTTP/1.1\r\nHost: $host:$port\r\nUser-Agent: GameTranslator\r\nAccept: */*\r\nConnection: close\r\n\r\n"
            socket.getOutputStream().apply {
                write(request.toByteArray(Charsets.US_ASCII))
                flush()
            }
            return parse(java.io.BufferedInputStream(socket.getInputStream()))
        } finally {
            runCatching { socket.close() }
            if (cancel !== Cancel.NONE) cancel.untrack(socket)
        }
    }

    /** Yanıtı okur: durum satırı, başlıklar, gövde (Content-Length, chunked ya da bağlantı kapanana kadar). */
    fun parse(input: InputStream): Response {
        val statusLine = readLine(input) ?: throw IOException("boş yanıt")
        val status = statusLine.split(' ').getOrNull(1)?.toIntOrNull() ?: throw IOException("HTTP yanıtı değil: $statusLine")
        var length = -1
        var chunked = false
        while (true) {
            val line = readLine(input) ?: break
            if (line.isEmpty()) break
            val colon = line.indexOf(':')
            if (colon < 0) continue
            val name = line.substring(0, colon).trim().lowercase()
            val value = line.substring(colon + 1).trim()
            if (name == "content-length") length = value.toIntOrNull() ?: -1
            if (name == "transfer-encoding" && value.lowercase().contains("chunked")) chunked = true
        }
        val body = ByteArrayOutputStream()
        when {
            chunked -> while (true) {
                val size = readLine(input)?.substringBefore(';')?.trim()?.toIntOrNull(16) ?: break
                if (size == 0) break
                body.write(Adb.readExactly(input, size))
                readLine(input)
            }
            length >= 0 -> body.write(Adb.readExactly(input, minOf(length, MAX)))
            else -> {
                val buffer = ByteArray(8192)
                while (body.size() < MAX) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    body.write(buffer, 0, n)
                }
            }
        }
        return Response(status, body.toByteArray())
    }

    private const val MAX = 4 * 1024 * 1024

    private fun readLine(input: InputStream): String? {
        val line = ByteArrayOutputStream()
        while (true) {
            val b = input.read()
            if (b < 0) return if (line.size() == 0) null else line.toString("UTF-8")
            if (b == '\n'.code) return line.toString("UTF-8").trimEnd('\r')
            line.write(b)
            if (line.size() > 16384) throw IOException("satır çok uzun")
        }
    }
}
