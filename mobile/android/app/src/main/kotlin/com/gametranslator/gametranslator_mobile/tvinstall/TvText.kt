// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

/** Sürüm karşılaştırması, paket adlarından sürüm ve elle yazılan adresler (Windows'taki Versions ve ManualAddress). */
object Versions {
    /** Sayısal karşılaştırma: 0.10.0, 0.9.9'dan yenidir. */
    fun isNewer(a: String, b: String): Boolean {
        val x = parts(a)
        val y = parts(b)
        for (i in 0 until maxOf(x.size, y.size)) {
            val left = x.getOrElse(i) { 0 }
            val right = y.getOrElse(i) { 0 }
            if (left != right) return left > right
        }
        return false
    }

    private fun parts(version: String): List<Int> = version.trim().split('.', '-').map { it.toIntOrNull() ?: 0 }

    /**
     * `gametranslator-androidtv_0.7.0.apk` → `0.7.0`, `com.gametranslator.tv_1.0.5_all.ipk` → `1.0.5`; ad bu
     * biçimde değilse null.
     */
    fun ofBundledFile(fileName: String): String? {
        val name = fileName.substringAfterLast('/').substringBeforeLast('.')
        val parts = name.split('_')
        if (fileName.endsWith(".ipk")) return if (parts.size >= 3) parts[1] else null
        val underscore = name.lastIndexOf('_')
        return if (underscore > 0 && underscore < name.length - 1) name.substring(underscore + 1) else null
    }
}

/**
 * Elle yazılan TV adresi. Kullanıcılar "192.168.1.5:3000", "http://192.168.1.5", sonda boşluk ya da (Türkçe sayı
 * klavyesinde nokta olmadığı için) "192,168,1,5" yazıyor. Adres burada temizlenir; adres olmayan giriş null döner.
 */
object ManualAddress {
    fun normalize(input: String?): String? {
        var text = (input ?: "").trim().replace(',', '.')
        val scheme = text.indexOf("://")
        if (scheme >= 0) text = text.substring(scheme + 3)
        val end = text.indexOfAny(charArrayOf('/', '?', '#'))
        if (end >= 0) text = text.substring(0, end)
        val parts = text.split(':')
        // Tek iki nokta port ayırır; daha fazlası IPv6'dır (TV'ler IPv4 adresiyle eşleşir).
        if (parts.size == 2) {
            if (parts[1].isEmpty() || !parts[1].all { it in '0'..'9' }) return null
            text = parts[0]
        } else if (parts.size > 2) {
            return null
        }
        if (text.endsWith('.')) text = text.dropLast(1)
        if (text.isEmpty()) return null
        if (text.all { it in '0'..'9' || it == '.' }) return ipv4(text)
        return if (isHostName(text)) text.lowercase() else null
    }

    private fun ipv4(text: String): String? {
        val octets = text.split('.')
        if (octets.size != 4) return null
        val values = octets.map { octet ->
            if (octet.length !in 1..3) return null
            octet.toIntOrNull()?.takeIf { it <= 255 } ?: return null
        }
        return values.joinToString(".")
    }

    /** Harf, rakam ve tireden oluşan, en az bir harf içeren etiketler (RFC 1123). */
    private fun isHostName(text: String): Boolean =
        text.length <= 253 && text.any { it.isAsciiLetter() } &&
            text.split('.').all { label ->
                label.length in 1..63 && label.first() != '-' && label.last() != '-' &&
                    label.all { it.isAsciiLetter() || it in '0'..'9' || it == '-' }
            }

    private fun Char.isAsciiLetter() = this in 'a'..'z' || this in 'A'..'Z'
}
