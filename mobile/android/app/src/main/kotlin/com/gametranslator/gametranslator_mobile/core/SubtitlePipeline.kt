// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import java.util.concurrent.Executor
import kotlin.math.max
import kotlin.math.min

/** Metni çevirir; bloklar. Çevrilemezse null. */
fun interface TextTranslator {
    fun translate(text: String): String?
}

/** Çevirinin gittiği yer (TV sunucusu ve telefondaki ekran). */
interface SubtitleSink {
    fun show(text: String, durationMs: Int, box: TextBox?, replaces: Boolean)
    fun clear()
}

/**
 * Okunan altyazıyı çevirip gönderen hat: gürültü temizliği → kararlılık → önbellek → oyun paketi/çeviri → TV.
 * Windows'taki SubtitlePipeline.cs'in çekirdeği (bekletme ve dublaj yok).
 * [onRead] tek bir iş parçacığından çağrılır; çeviri [translateExecutor]'da yapılır, sonuçlar kilit altında işlenir.
 */
class SubtitlePipeline(
    private val translator: TextTranslator,
    private val sink: SubtitleSink,
    private val translateExecutor: Executor,
    private val stabilizer: SubtitleStabilizer = SubtitleStabilizer(),
) {
    companion object {
        /** Satır ekranda durdukça çeviri de durur; kalkınca TV'den silinir. */
        const val ON_SCREEN_MS = 15000
        private const val CACHE_SIZE = 300

        /** Çevirisi geldiğinde ekrandan kalkmış satırın TV'de kalacağı süre. */
        fun readingTime(text: String): Int = min(8000, max(2000, 1200 + 60 * text.length))
    }

    private val lock = Any()
    private val cache = object : LinkedHashMap<String, String>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, String>?) = size > CACHE_SIZE
    }
    private var latest = 0
    /** Ekranda duran satırın numarası; satır kalktıysa -1. */
    private var onScreen = -1
    private var lastShownSource: String? = null

    /** Çeviri gösterildiğinde (kaynak, çeviri). */
    var onPair: ((String, String) -> Unit)? = null
    /** Çeviri başarısız olduğunda kaynak satır. */
    var onTranslateFailed: ((String) -> Unit)? = null
    /** Okunan ve temizlenen ham metin (boş olabilir); tanılama için. */
    var onReadText: ((String) -> Unit)? = null
    /**
     * Oyun paketi: kararlı satırın hazır Türkçesi (yoksa null). Çeviri motorundan önce, çeviri iş parçacığında bakılır;
     * bulunursa motora gidilmez ve paketteki metin olduğu gibi gösterilir (sözlük de uygulanmaz).
     */
    @Volatile var packLookup: ((String) -> PackMatch?)? = null
    /** Paketten gösterilen satır (kaynak, paket). */
    var onPackHit: ((String, PackMatch) -> Unit)? = null
    /** Paketten gösterilen satır sayısı. */
    @Volatile var packHits = 0
        private set

    /** Bir karenin okuması: [lines] yukarıdan aşağı satırlar, [box] yazının ekrandaki yeri. */
    fun onRead(lines: List<String>, box: TextBox?) {
        val text = lines.map { OcrNoise.clean(it) }.filter { it.isNotEmpty() }.joinToString("\n")
        onReadText?.invoke(text)
        synchronized(lock) {
            val action = stabilizer.feed(text)
            when (action.kind) {
                StabilizerKind.NONE -> {}
                StabilizerKind.CLEAR -> {
                    onScreen = -1
                    sink.clear()
                }
                StabilizerKind.RESTORE -> {
                    val source = action.text ?: return
                    val number = ++latest
                    onScreen = number
                    cache[key(source)]?.let { show(source, it, box, ON_SCREEN_MS, replaces = false) }
                        ?: request(number, source, box)
                }
                StabilizerKind.TRANSLATE -> {
                    val source = action.text ?: return
                    val number = ++latest
                    onScreen = number
                    val cached = cache[key(source)]
                    if (cached != null) deliver(number, source, cached, box) else request(number, source, box)
                }
            }
        }
    }

    private fun request(number: Int, source: String, box: TextBox?) {
        translateExecutor.execute {
            val packed = try {
                packLookup?.invoke(source)?.takeIf { it.text.isNotBlank() }
            } catch (error: Exception) {
                null
            }
            // İki satırlık altyazı tek cümledir; çevirmene tek satır olarak gider.
            val translated = packed?.text?.trim() ?: try {
                translator.translate(source.replace('\n', ' '))?.trim()
            } catch (error: Exception) {
                null
            }
            synchronized(lock) {
                if (packed != null) {
                    packHits++
                    onPackHit?.invoke(source, packed)
                }
                if (translated.isNullOrEmpty()) {
                    if (number == onScreen) stabilizer.forgetSent()
                    onTranslateFailed?.invoke(source)
                    return@synchronized
                }
                cache[key(source)] = translated
                deliver(number, source, translated, box)
            }
        }
    }

    /** Kilit altında çağrılır. Yerine yenisi gelmiş satırın geç kalan çevirisi gösterilmez. */
    private fun deliver(number: Int, source: String, translated: String, box: TextBox?) {
        if (number != latest) return
        // Çeviri kaynağıyla neredeyse aynıysa metin zaten hedef dildedir.
        if (!stabilizer.shouldSend(source, translated)) return
        val duration = if (number == onScreen) ON_SCREEN_MS else readingTime(translated)
        val replaces = lastShownSource?.let { TextMatch.isRevision(source, it) } ?: false
        show(source, translated, box, duration, replaces)
    }

    private fun show(source: String, translated: String, box: TextBox?, duration: Int, replaces: Boolean) {
        lastShownSource = source
        sink.show(translated, duration, box, replaces)
        onPair?.invoke(source, translated)
    }

    private fun key(source: String) = TextMatch.normalize(source)

    fun reset() {
        synchronized(lock) {
            latest++
            onScreen = -1
            lastShownSource = null
            if (stabilizer.reset().kind == StabilizerKind.CLEAR) sink.clear()
        }
    }
}

/**
 * Hangi karede yazı tanıma yapılacağını seçer: bölge değişmediyse son okuma yeniden kullanılır.
 * Oyun süresinin çoğunda bölge boştur ya da değişmez; telefonda bu pil ve ısı demektir (Windows'taki ReadScheduler).
 */
class ReadScheduler(private val changeThreshold: Int = 16, private val maxReuse: Int = 20) {
    private var previous: ByteArray? = null
    private var reused = 0

    /** true ise bölge değişmedi; son okuma geçerli. */
    fun canReuse(signature: ByteArray): Boolean {
        val before = previous
        previous = signature
        if (before != null && reused < maxReuse && !changed(before, signature)) {
            reused++
            return true
        }
        reused = 0
        return false
    }

    fun reset() {
        previous = null
        reused = 0
    }

    private fun changed(a: ByteArray, b: ByteArray): Boolean {
        if (a.size != b.size) return true
        for (i in a.indices) if (kotlin.math.abs((a[i].toInt() and 0xFF) - (b[i].toInt() and 0xFF)) > changeThreshold) return true
        return false
    }
}
