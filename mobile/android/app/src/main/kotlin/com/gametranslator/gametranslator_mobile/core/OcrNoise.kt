// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import java.util.Locale

/**
 * Süslü yazı tiplerinde, solan ya da titreyen altyazıda yazı tanıma bazı sözcükleri harf, rakam ve simge
 * karışımı çöpe çevirir ("ou$3e", "waters2aljd"). Windows'taki GameTranslator.Core/OcrNoise.cs ile aynı kurallar.
 */
object OcrNoise {
    private const val SYMBOLS = "$@#%^*_=|\\~<>{}¢£¥§©®°±µ¶¤"
    private val whitespace = Regex("\\s+")
    private val leadingNumber = Regex("^\\d+(?:m|km|ft|yd)?[.?!:;]?$")
    private val usual = Regex(
        "^(?:[A-Za-z]{1,4}\\d{1,4}|\\d+(?:st|nd|rd|th|s|k|K|m|km|kg|cm|mm|p|x|fps|hp|HP|XP|xp|v|V|D|d)|[xX]\\d{1,3}" +
            "|\\d+[.,]\\d+[A-Za-z]{0,3}|\\d{1,2}[:.]\\d{2}(?:am|pm|AM|PM)?)$")

    internal fun tokens(text: String): List<String> = text.split(whitespace).filter { it.isNotEmpty() }

    /** C#'taki char.IsNumber: ondalık rakam, harf-sayı (Ⅳ) ve diğer sayılar (½, ²). */
    internal fun isNumber(c: Char): Boolean = when (Character.getType(c).toByte()) {
        Character.DECIMAL_DIGIT_NUMBER, Character.LETTER_NUMBER, Character.OTHER_NUMBER -> true
        else -> false
    }

    private fun isPunctuationOrSymbol(c: Char): Boolean = when (Character.getType(c).toByte()) {
        Character.CONNECTOR_PUNCTUATION, Character.DASH_PUNCTUATION, Character.START_PUNCTUATION,
        Character.END_PUNCTUATION, Character.INITIAL_QUOTE_PUNCTUATION, Character.FINAL_QUOTE_PUNCTUATION,
        Character.OTHER_PUNCTUATION, Character.MATH_SYMBOL, Character.CURRENCY_SYMBOL,
        Character.MODIFIER_SYMBOL, Character.OTHER_SYMBOL -> true
        else -> false
    }

    fun clean(line: String): String {
        val kept = mutableListOf<String>()
        val tokens = tokens(line)
        for (index in tokens.indices) {
            val token = tokens[index]
            val (lead, core, trail) = split(token)
            // Tek başına "l" ya da "|" çoğu zaman yanlış okunmuş "I"dır; ardından küçük harfle süren sözcük
            // gelmiyorsa altyazı kutusunun kenarıdır, atılır.
            val pronoun = misreadI(core)
            if (pronoun != null) {
                val next = if (index + 1 < tokens.size) tokens[index + 1].firstOrNull { it.isLetter() } ?: '\u0000' else '\u0000'
                if (pronoun != "I" || next.isLowerCase()) kept.add(lead + pronoun + trail)
                continue
            }
            // Yalnız "?!", ".", "," gibi işaretlerden oluşan parça yazı tanımanın uydurmasıdır.
            if (core.isEmpty() && isStrayPunctuation(token)) {
                if (kept.isNotEmpty() && !".?!…,;:".contains(kept.last().last())) kept[kept.size - 1] = kept.last() + token
                continue
            }
            val fixedCore = cleanCore(core)
            if (fixedCore != null) kept.add(lead + fixedCore + trail)
            else if (trail.isNotEmpty() && kept.isNotEmpty()) kept[kept.size - 1] = kept.last() + trail
        }
        // Altyazının yanındaki göstergenin sayısı satırın başına yapışıyor ("9? We'll lose"): sayı atılır.
        if (kept.size >= 3 && leadingNumber.matches(kept[0]) && kept[1][0].isUpperCase()) kept.removeAt(0)
        return kept.joinToString(" ")
    }

    /** Bir okumanın ne kadar sözcük gibi göründüğü: düzgün sözcüklerin harfleri artı, çöp parçalar eksi sayılır. */
    fun score(text: String): Int {
        var score = 0
        for (token in tokens(text)) {
            val core = split(token).second
            val letters = core.count { it.isLetter() }
            if (letters == 0) continue
            val clean = cleanCore(core) == core && normalCase(core) && core.none { it in "[]()" }
            score += if (clean) letters else -2 * letters
        }
        return score
    }

    /** Okuma çöp gibi mi: harflerinin altıda birinden çoğu bozuk sözcüklerde. */
    fun looksGarbled(text: String): Boolean {
        var good = 0
        var bad = 0
        for (token in tokens(text)) {
            val core = split(token).second
            val letters = core.filter { it.isLetter() }
            if (letters.isEmpty()) continue
            val clean = cleanCore(core) == core && normalCase(core) && core.none { it in "[]()" } && !vowelless(letters)
            if (clean) good += letters.length else bad += letters.length
        }
        return bad * 6 > good + bad
    }

    /** Üç ve daha çok harfli, ünlüsüz ve kısaltma olmayan sözcük: İngilizcede olmaz ("Gtt", "rnnk"). */
    private fun vowelless(letters: String): Boolean =
        letters.length >= 3 && !letters.all { it.isUpperCase() } &&
            letters.lowercase(Locale.ROOT).none { it in "aeiouyäöüıàáâèéêìíîòóôùúû" }

    /** "word", "WORD", "Word", "McDonald", "don't": büyük harf yalnız başta ya da baştan bir dizi. */
    private fun normalCase(core: String): Boolean {
        val letters = core.filter { it.isLetter() }
        if (letters.all { it.isUpperCase() } || letters.drop(1).all { it.isLowerCase() }) return true
        return letters.drop(1).count { it.isUpperCase() } == 1 && letters.count { it.isLowerCase() } >= 2
    }

    /** "l", "|", "l'm", "|'ll" → "I", "I'm", "I'll" (null: böyle bir okuma değil). */
    private fun misreadI(core: String): String? {
        if (core.isEmpty() || (core[0] != 'l' && core[0] != '|')) return null
        if (core.length == 1) return "I"
        if (core[1] != '\'' && core[1] != '’') return null
        if (core.substring(2) !in setOf("m", "ll", "ve", "d")) return null
        return "I" + core.substring(1)
    }

    /** Yalnız ? ! . , ; : işaretlerinden oluşan parça; üç nokta ("...") gerçek noktalamadır. */
    private fun isStrayPunctuation(token: String): Boolean =
        token.isNotEmpty() && token.all { it in "?!.,;:" } && !(token.length >= 2 && token.all { it == '.' })

    /** Sözcüğün kendisi; null ise tamamen çöptür. */
    private fun cleanCore(core: String): String? {
        val letters = core.count { it.isLetter() }
        val digits = core.count { isNumber(it) }
        val hasSymbol = core.any { it in SYMBOLS }
        if (letters == 0) return core // "24", "$500", "…"
        if (!hasSymbol && digits == 0) return core
        if (!hasSymbol && isUsualMix(core)) return core
        // Gerçek sözcüğe yapışmış çöp: baştaki en az 3 harf korunur ("waters2aljd" → "waters").
        val prefix = core.takeWhile { it.isLetter() || it == '\'' || it == '’' || it == '-' }
        return if (prefix.count { it.isLetter() } >= 3) prefix else null
    }

    /** "PS5", "R2", "2nd", "100m", "4K", "60fps", "x2", "R2-D2": olağan harf-rakam karışımları. */
    private fun isUsualMix(core: String): Boolean =
        core.split('-').all { part -> part.none { isNumber(it) } || usual.matches(part) }

    private fun isEdge(c: Char): Boolean =
        c !in SYMBOLS && (isPunctuationOrSymbol(c) || c in "\"'“”‘’«»()[]")

    /** (baştaki işaretler, sözcük, sondaki işaretler) */
    internal fun split(token: String): Triple<String, String, String> {
        var start = 0
        var end = token.length
        while (start < end && isEdge(token[start])) start++
        while (end > start && isEdge(token[end - 1])) end--
        return Triple(token.substring(0, start), token.substring(start, end), token.substring(end))
    }
}
