// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

/**
 * Altyazının başındaki konuşmacı işareti: tire ("- ", "– ", "— ") ya da ">>" (Windows'taki GoogleGtxTranslator ve
 * SubtitleSegmenter ile aynı kural). Çeviri motorları bu işaretleri silebildiği ya da bozabildiği için çeviriden
 * önce ayrılır, sonra olduğu gibi geri eklenir.
 */
object SpeakerPrefix {
    private val pattern = Regex("^(?:[-–—]+|>{1,3})\\s*")

    /** (işaret, geri kalan metin). İşaret yoksa ilk değer boştur. */
    fun split(text: String): Pair<String, String> {
        val trimmed = text.trim()
        val match = pattern.find(trimmed) ?: return "" to trimmed
        return match.value to trimmed.substring(match.value.length).trim()
    }
}

/** Çevirmeni sarar: konuşmacı işareti çevirmene gönderilmez, çevirinin başına geri konur. */
class PrefixTranslator(private val inner: TextTranslator) : TextTranslator {
    override fun translate(text: String): String? {
        val (prefix, rest) = SpeakerPrefix.split(text)
        if (prefix.isEmpty()) return inner.translate(text)
        // Yalnız işaretten oluşan satırda çevrilecek bir şey yoktur.
        if (rest.isEmpty()) return prefix.trim()
        val translated = inner.translate(rest)?.trim() ?: return null
        return if (translated.isEmpty()) null else prefix + translated
    }
}
