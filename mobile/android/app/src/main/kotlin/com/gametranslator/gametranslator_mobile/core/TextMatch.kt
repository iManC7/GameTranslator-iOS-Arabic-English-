// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/**
 * OCR çıktılarını karşılaştırmak için sadeleştirme ve gürültüye dayanıklı benzerlik.
 * Windows'taki GameTranslator.Core/TextMatch.cs ile aynı kurallar.
 */
object TextMatch {
    /** Küçük harf, yalnız harf/rakam, tek boşluk. */
    fun normalize(s: String): String {
        val builder = StringBuilder(s.length)
        for (c in s.lowercase(Locale.ROOT)) builder.append(if (isAlphanumeric(c)) c else ' ')
        return builder.split(' ').filter { it.isNotEmpty() }.joinToString(" ")
    }

    /** Levenshtein oranı [threshold] ve üstündeyse benzer sayılır. Boş metin hiçbir metne benzemez. */
    fun isSimilar(a: String, b: String, threshold: Double = 0.85): Boolean {
        if (a == b) return a.isNotEmpty()
        if (a.isEmpty() || b.isEmpty()) return false
        var previous = IntArray(b.length + 1) { it }
        var row = IntArray(b.length + 1)
        for (i in 1..a.length) {
            row[0] = i
            for (j in 1..b.length)
                row[j] = min(min(previous[j] + 1, row[j - 1] + 1), previous[j - 1] + if (a[i - 1] == b[j - 1]) 0 else 1)
            val swap = previous; previous = row; row = swap
        }
        return 1 - previous[b.length].toDouble() / max(a.length, b.length) >= threshold
    }

    /** Satırları ayrı ayrı sadeleştirip alt alta birleştirir; [isSameSubtitle] kaçırılan satırı bundan anlar. */
    fun normalizeRows(s: String): String =
        s.replace("\r\n", "\n").split('\n').map { normalize(it) }.filter { it.isNotEmpty() }.joinToString("\n")

    /**
     * Yeni okuma, gönderilmiş altyazının yeniden okuması mı. Başına ya da sonuna sözcük eklenmiş metin yenidir;
     * sondan kısalmış metin ise ancak tam bir satırı eksikse aynı altyazıdır.
     */
    fun isSameSubtitle(reread: String, sent: String): Boolean {
        val rows = sent.split('\n')
        val flat = rows.joinToString(" ")
        val x = cleanWords(reread)
        val y = cleanWords(flat)
        if (y.isNotEmpty() && x.size > y.size && (startsWith(x, y) || endsWith(x, y))) return false
        if (isSimilar(reread, flat)) return true
        if (x.isNotEmpty() && x.size < y.size && (startsWith(y, x) || endsWith(y, x)))
            return isWholeRows(x.size, rows, startsWith(y, x))
        val remaining = y.toMutableList()
        val sentCount = remaining.size
        var shared = 0
        for (word in x) if (remaining.remove(word)) shared++
        if (x.size >= 4 && x.size <= sentCount && shared >= x.size * 0.85) return true
        val longer = max(x.size, sentCount)
        val shorter = min(x.size, sentCount)
        if (shorter < 6 || shorter.toDouble() / longer < 0.75) return false
        return shared.toDouble() / longer >= 0.75
    }

    /** Yeni satır, az önce gösterilen satırın uzamış ya da düzelmiş okuması mı; TV onu öncekinin yerine koyar. */
    fun isRevision(newText: String, oldText: String): Boolean {
        val x = normalize(newText)
        val y = normalize(oldText)
        if (x.isEmpty() || y.isEmpty()) return false
        if (isGrowth(newText, oldText) || isGrowth(oldText, newText)) return true
        if (isSimilar(x, y, 0.8)) return true
        val a = cleanWords(x)
        val b = cleanWords(y).toMutableList()
        val shorter = min(a.size, b.size)
        val longer = max(a.size, b.size)
        if (shorter < 5) return false
        if (similarity(a, b) >= 0.65) return true
        var shared = 0
        for (word in a) if (b.remove(word)) shared++
        return shared.toDouble() / longer >= 0.7
    }

    /** Okuma, gönderilmiş satırın aynı cümleyi bozuk okuyan ve ondan daha iyi olmayan bir yeniden okuması mı. */
    fun isWorseReread(reread: String, sent: String): Boolean {
        val a = normalize(reread)
        val b = normalize(sent)
        val x = cleanWords(a)
        val y = cleanWords(b)
        if (x.size < 5 || y.isEmpty() || isGrowth(reread, sent) || isGrowth(sent, reread)) return false
        val reads = similarity(x, y) >= 0.65 || isSimilar(a, b, 0.75)
        return reads && OcrNoise.score(reread) < OcrNoise.score(sent) + 4
    }

    /** Levenshtein oranı (sözcük dizileri için). */
    private fun similarity(x: List<String>, y: List<String>): Double {
        if (x.isEmpty() || y.isEmpty()) return if (x.isEmpty() && y.isEmpty()) 1.0 else 0.0
        var previous = IntArray(y.size + 1) { it }
        var row = IntArray(y.size + 1)
        for (i in 1..x.size) {
            row[0] = i
            for (j in 1..y.size)
                row[j] = min(min(previous[j] + 1, row[j - 1] + 1), previous[j - 1] + if (x[i - 1] == y[j - 1]) 0 else 1)
            val swap = previous; previous = row; row = swap
        }
        return 1 - previous[y.size].toDouble() / max(x.size, y.size)
    }

    /** [newText], [oldText]'in sonuna (ya da başına) sözcük eklenmiş hali mi (daktilo efekti). */
    fun isGrowth(newText: String, oldText: String): Boolean {
        val x = normalize(newText).split(' ').filter { it.isNotEmpty() }
        val y = normalize(oldText).split(' ').filter { it.isNotEmpty() }
        if (y.isEmpty() || x.size <= y.size) return false
        return startsWith(x, y) || (y.size >= 2 && endsWith(x, y))
    }

    private fun startsWith(words: List<String>, part: List<String>) = words.take(part.size) == part

    private fun endsWith(words: List<String>, part: List<String>) = words.drop(max(0, words.size - part.size)) == part

    /** Baştan (ya da sondan) [count] sözcük tam satırlara denk geliyor mu. */
    private fun isWholeRows(count: Int, rows: List<String>, fromStart: Boolean): Boolean {
        var total = 0
        for (row in if (fromStart) rows else rows.reversed()) {
            total += cleanWords(row).size
            if (total == count) return true
            if (total > count) return false
        }
        return false
    }

    // Tek harfler ("a", "I" ya da OCR'ın uydurduğu "O") karşılaştırmaya bir şey katmaz.
    private fun cleanWords(normalized: String): List<String> =
        normalized.split(' ').filter { w -> w.length > 1 && w.none { OcrNoise.isNumber(it) } }

    private fun isAlphanumeric(c: Char): Boolean = when (Character.getType(c).toByte()) {
        Character.UPPERCASE_LETTER, Character.LOWERCASE_LETTER, Character.TITLECASE_LETTER,
        Character.MODIFIER_LETTER, Character.OTHER_LETTER,
        Character.NON_SPACING_MARK, Character.COMBINING_SPACING_MARK, Character.ENCLOSING_MARK,
        Character.DECIMAL_DIGIT_NUMBER, Character.LETTER_NUMBER, Character.OTHER_NUMBER -> true
        else -> false
    }
}
