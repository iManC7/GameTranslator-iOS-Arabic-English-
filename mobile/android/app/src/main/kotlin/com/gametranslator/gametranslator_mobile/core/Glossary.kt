// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import java.util.Locale

/**
 * Terim sözlüğü (Windows: Glossary.cs, aynı biçim ve kurallar). Dosya biçimi:
 * `{ "game": "God of War", "terms": { "Leviathan Axe": "Leviathan Baltası" }, "keep": ["Kratos", "Atreus"] }`.
 * `terms` İngilizce terimi verilen Türkçeyle değiştirir, `keep` adları olduğu gibi bırakır. Eşleşme büyük/küçük harfe
 * bakmaz, yalnız tam sözcüklerde olur, uzun terim önce gelir ("Leviathan Axe", "Axe"dan önce).
 */
class Glossary private constructor(private val terms: Map<String, Term>) {
    data class Term(val english: String, val turkish: String)

    /** Metinde bulunan terim: konumu, sözlükteki İngilizcesi ve Türkçesi. */
    data class Match(val start: Int, val length: Int, val english: String, val turkish: String)

    /** Uzundan kısaya terimler; arama bu sırayla yapılır. */
    private val ordered: List<Term> = terms.values.sortedWith(compareByDescending<Term> { it.english.length }.thenBy { it.english })

    val count: Int get() = terms.size
    val isEmpty: Boolean get() = terms.isEmpty()

    /** Terimin Türkçesi; yoksa null. */
    fun turkish(english: String): String? = terms[collapse(english).lowercase(Locale.ROOT)]?.turkish

    /**
     * Metindeki terimler: büyük/küçük harfe bakmadan, tam sözcük, uzun terim önce; çakışan kısa terim alınmaz.
     * Sonuç metindeki sıraya göredir.
     */
    fun find(text: String): List<Match> {
        val found = ArrayList<Match>()
        if (ordered.isEmpty() || text.isEmpty()) return found
        for (term in ordered) {
            var start = 0
            while (start <= text.length - term.english.length) {
                val index = text.indexOf(term.english, start, ignoreCase = true)
                if (index < 0) break
                val end = index + term.english.length
                if (isBoundary(text, index - 1) && isBoundary(text, end) && found.none { index < it.start + it.length && it.start < end })
                    found.add(Match(index, term.english.length, term.english, term.turkish))
                start = index + 1
            }
        }
        found.sortBy { it.start }
        return found
    }

    companion object {
        val EMPTY = Glossary(emptyMap())

        /** [terms] İngilizce → Türkçe, [keep] olduğu gibi kalacak adlar. Harfsiz, boş ya da çok uzun girdi alınmaz. */
        fun of(terms: Map<String, String>, keep: List<String> = emptyList()): Glossary {
            val all = LinkedHashMap<String, Term>()
            fun add(rawEnglish: String, rawTurkish: String) {
                val english = collapse(rawEnglish)
                val turkish = collapse(rawTurkish)
                // Harfsiz terim her yerde eşleşirdi; yer tutucu sayısı sınırlı olduğundan çok uzun terim de alınmaz.
                if (english.none { it.isLetter() } || turkish.isEmpty() || english.length > 80) return
                all[english.lowercase(Locale.ROOT)] = Term(english, turkish)
            }
            for ((english, turkish) in terms) add(english, turkish)
            for (name in keep) add(name, name)
            return Glossary(all)
        }

        private fun isBoundary(text: String, index: Int) = index < 0 || index >= text.length || !text[index].isLetterOrDigit()

        private fun collapse(text: String) = text.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }.joinToString(" ")
    }
}

/**
 * Sözlük teriminin Türkçe eki (Windows: TurkishSuffix.cs, aynı kurallar). Çeviri motoru terimin yerindeki yer tutucu
 * ada bir ek koyar ("Zarmon'a", "Zarmon'un"); ek, hangi hâl olduğu korunarak gerçek terime göre yeniden kurulur:
 * ünlü uyumu (Kratos'u, Midgard'ı), kaynaştırma (Freya'ya, Freya'nın), ünsüz benzeşmesi (Kratos'ta); özel ad kesmeyle
 * ayrılır, cins ad bitişik yazılır ve p/ç/k yumuşar (kılıcı); çok sözcüklü, dar ünlüyle biten terim tamlama sayılır
 * (Leviathan Baltası'nı).
 */
object TurkishSuffix {
    private val TURKISH = Locale.forLanguageTag("tr-TR")
    private const val VOWELS = "aeıioöuü"
    private const val BACK_VOWELS = "aıou"
    private const val ROUNDED_VOWELS = "ouöü"
    private const val HIGH_VOWELS = "ıiuü"
    private const val VOICELESS = "fstkçşhp"
    /** Daha uzun "ek" büyük olasılıkla ek değildir; dokunulmaz. */
    private const val MAX_SUFFIX_LENGTH = 12

    /** [term] + ek. [suffix] motorun yer tutucuya koyduğu ektir (kesmesiz: "a", "un", "ya", "dan"); boşsa terim döner. */
    fun attach(term: String, suffix: String, apostrophe: Char = '\''): String {
        if (term.isEmpty() || suffix.isEmpty()) return term
        var body = suffix.lowercase(TURKISH)
        if (body.length > MAX_SUFFIX_LENGTH || !body.all { it.isLetter() }) return term + apostrophe + suffix

        val proper = term[0].isUpperCase()
        val lastWord = term.substring(term.lastIndexOf(' ') + 1).lowercase(TURKISH)
        val lastLetter = lastWord.lastOrNull { it.isLetter() }
        var lastVowel = lastWord.lastOrNull { isVowel(it) }
        // Ünlüsüz kısaltma ("XP", "HP") harf adlarıyla okunur: "iks-pe" → ince, ünlüyle biter.
        val endsWithVowel = lastVowel == null || (lastLetter != null && isVowel(lastLetter))
        if (lastVowel == null) lastVowel = 'e'
        val compound = term.contains(' ') && lastLetter != null && lastLetter in HIGH_VOWELS && lastWord.length >= 3
        val voiceless = !endsWithVowel && lastLetter != null && lastLetter in VOICELESS

        // Baştaki kaynaştırma harfi yer tutucuya göreydi ("Zarmon" ünsüzle biter, çoğu zaman yoktur); atılır.
        if (body.length >= 2 && body[0] == 'y' && (isVowel(body[1]) || body[1] == 'l')) body = body.substring(1)
        else if (body.length >= 3 && body[0] == 'n' && body[1] in HIGH_VOWELS && body[2] == 'n') body = body.substring(1)

        val genitive = body.length >= 2 && body[0] in HIGH_VOWELS && body[1] == 'n' && (body.length == 2 || !isVowel(body[2]))
        val instrumental = body.length >= 2 && body[0] == 'l' && (body[1] == 'a' || body[1] == 'e') && !(body.length >= 3 && body[2] == 'r')
        var buffer = ""
        if (isVowel(body[0])) {
            if (compound || (endsWithVowel && genitive)) buffer = "n"
            else if (endsWithVowel) buffer = "y"
        } else if (body[0] == 'd' || body[0] == 't') {
            if (compound) buffer = "n"
            body = (if (compound || !voiceless) "d" else "t") + body.substring(1)
        } else if (instrumental && (endsWithVowel || compound)) {
            buffer = "y"
        }

        val harmonized = harmonize(body, lastVowel)
        if (proper) return term + apostrophe + buffer + harmonized
        val stem = if (buffer.isEmpty() && isVowel(harmonized[0])) soften(term) else term
        return stem + buffer + harmonized
    }

    /** Ekteki a/e ve ı/i/u/ü ünlülerini önceki ünlüye uydurur; "-ki" (Midgard'daki) değişmez. */
    internal fun harmonize(body: String, lastVowel: Char): String {
        val output = StringBuilder(body.length)
        var previous = lastVowel
        for (i in body.indices) {
            var c = body[i]
            val invariantKi = c == 'i' && i > 0 && body[i - 1] == 'k' && i == body.length - 1
            if (!invariantKi && c in "ae") c = if (previous in BACK_VOWELS) 'a' else 'e'
            else if (!invariantKi && c in HIGH_VOWELS) {
                val back = previous in BACK_VOWELS
                val rounded = previous in ROUNDED_VOWELS
                c = if (back) (if (rounded) 'u' else 'ı') else (if (rounded) 'ü' else 'i')
            }
            if (isVowel(c)) previous = c
            output.append(c)
        }
        return output.toString()
    }

    /**
     * Cins adın son p/ç/k'si ünlüyle başlayan ekten önce yumuşar (kitap → kitabı, kılıç → kılıcı, bıçak → bıçağı,
     * renk → rengi). Tek heceli sözcükler yumuşamaz (top → topu); t çoğu sözcükte yumuşamadığı için dokunulmaz.
     */
    internal fun soften(term: String): String {
        if (term.length < 2) return term
        val lower = term.lowercase(TURKISH)
        val word = lower.substring(lower.lastIndexOf(' ') + 1)
        val stem = term.dropLast(1)
        if (word.endsWith("nk")) return stem + "g"
        if (word.count { isVowel(it) } < 2) return term
        return when (term.last()) {
            'p' -> stem + "b"
            'ç' -> stem + "c"
            'k' -> stem + "ğ"
            else -> term
        }
    }

    internal fun isVowel(c: Char) = c in VOWELS
}

/**
 * Sözlük terimlerini çeviriden korur (Windows: TermProtection.cs, aynı kurallar). Terim, çeviri öncesinde uydurma bir
 * özel adla ("Zarmon", "Velkor") değiştirilir: çeviri motorları özel adı olduğu gibi bırakıp Türkçe ekini kesmeyle
 * ekler ("Zarmon'u al"). Çeviriden sonra ad bulunur, yerine Türkçe terim konur ve ek terime göre yeniden kurulur.
 * Bir ad çeviride yoksa sonuç güvenilmez sayılır (null), çağıran korumasız çeviriye döner.
 */
class TermProtector(private val glossary: Glossary, vararg sources: String) {
    /** Korunan terim: yer tutucusu ve yerine konacak Türkçe. */
    data class Slot(val placeholder: String, val english: String, val turkish: String)

    private val free = PLACEHOLDERS.filter { p -> sources.none { it.contains(p, ignoreCase = true) } }.toMutableList()
    private val byTerm = LinkedHashMap<String, Slot>()

    /** Bütün yer tutucular; çıktıda beklenmeyen ad kalmasın diye. */
    val allSlots: Collection<Slot> get() = byTerm.values

    /** Terimleri yer tutucularla değiştirir; bu metinde kullanılan yer tutucular döner. */
    fun protect(text: String): Pair<String, List<Slot>> {
        val matches = glossary.find(text)
        if (matches.isEmpty()) return text to emptyList()
        val builder = StringBuilder(text.length)
        val used = ArrayList<Slot>()
        var position = 0
        for (match in matches) {
            val key = match.english.lowercase(Locale.ROOT)
            var slot = byTerm[key]
            if (slot == null) {
                // Ad kalmadıysa geri kalan terimler korunmaz; motor onları kendi çevirir.
                if (free.isEmpty()) continue
                slot = Slot(free.removeAt(0), match.english, match.turkish)
                byTerm[key] = slot
            }
            builder.append(text, position, match.start).append(slot.placeholder)
            position = match.start + match.length
            if (slot !in used) used.add(slot)
        }
        builder.append(text, position, text.length)
        return builder.toString() to used
    }

    companion object {
        /**
         * Yer tutucu adlar: Türkçe ve İngilizcede sözcük değil, birbirinin başı değil, i/I içermez (Türkçe büyük/küçük
         * harf dönüşümü bozmasın), ünsüzle biter (yumuşamaz) ve kalın ünlülüdür.
         */
        internal val PLACEHOLDERS = listOf("Zarmon", "Velkor", "Dorvan", "Kelmar", "Tolvar", "Brandur", "Halvor", "Feldor")

        private val TURKISH = Locale.forLanguageTag("tr-TR")

        /**
         * Yer tutucuları Türkçe terimle değiştirir. [expected] çıktıda en az bir kez geçmeli, [all] içindeki diğer
         * adlar hiç geçmemeli; yoksa null.
         */
        fun restore(output: String, expected: List<Slot>, all: Collection<Slot>? = null, apostrophe: Char = '\''): String? {
            if (expected.isEmpty() && all.isNullOrEmpty()) return output
            for (slot in all ?: emptyList())
                if (slot !in expected && pattern(slot.placeholder).containsMatchIn(output)) return null
            var text = output
            for (slot in expected) {
                val pattern = pattern(slot.placeholder)
                if (!pattern.containsMatchIn(text)) return null
                val current = text
                text = pattern.replace(current) { match ->
                    val suffix = match.groups[1]?.value ?: match.groups[2]?.value ?: ""
                    val term = TurkishSuffix.attach(slot.turkish, suffix, apostrophe)
                    if (startsSentence(current, match.range.first)) capitalize(term) else term
                }
            }
            return text
        }

        /** Yer tutucu ve ardındaki ek: kesmeyle ("Zarmon'a", "Zarmon 'a") ya da bitişik ("Zarmona"). */
        private fun pattern(placeholder: String) =
            Regex("(?<![\\p{L}\\p{N}])$placeholder(?:\\s?['’`´](\\p{L}+)|(\\p{L}+))?(?![\\p{L}\\p{N}])", RegexOption.IGNORE_CASE)

        /** Metnin ya da cümlenin başı mı (önünde yalnız boşluk, tırnak, tire ya da cümle sonu var). */
        private fun startsSentence(text: String, index: Int): Boolean {
            for (i in index - 1 downTo 0) {
                val c = text[i]
                if (c.isWhitespace() || c in "\"“'‘(-–—¡¿") continue
                return c in ".!?…"
            }
            return true
        }

        private fun capitalize(term: String) =
            if (term.isEmpty() || !term[0].isLowerCase()) term else term.substring(0, 1).uppercase(TURKISH) + term.substring(1)
    }
}

/**
 * Çevirmeni sözlükle sarar: terimler korunarak çevrilir; motor bir yer tutucuyu düşürdüyse korumasız çeviriye dönülür
 * (terimsiz ama eksiksiz çeviri, eksik terimli çeviriden iyidir).
 */
class GlossaryTranslator(private val glossary: Glossary, private val inner: TextTranslator) : TextTranslator {
    override fun translate(text: String): String? {
        if (glossary.isEmpty) return inner.translate(text)
        val protector = TermProtector(glossary, text)
        val (input, used) = protector.protect(text)
        if (used.isEmpty()) return inner.translate(text)
        val translated = inner.translate(input) ?: return null
        return TermProtector.restore(translated, used, protector.allSlots) ?: inner.translate(text)
    }
}
