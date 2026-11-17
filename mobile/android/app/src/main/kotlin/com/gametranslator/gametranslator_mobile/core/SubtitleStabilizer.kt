// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

enum class StabilizerKind { NONE, TRANSLATE, CLEAR, RESTORE }

/** Okuma hattının bir kareye vereceği tepki. */
data class StabilizerAction(val kind: StabilizerKind, val text: String? = null) {
    companion object {
        val None = StabilizerAction(StabilizerKind.NONE)
        val Clear = StabilizerAction(StabilizerKind.CLEAR)
        fun translate(text: String) = StabilizerAction(StabilizerKind.TRANSLATE, text)
        /** Az önce kalkan satır geri geldi; çevirisi yeniden gösterilir, yeniden çevrilmez. */
        fun restore(text: String) = StabilizerAction(StabilizerKind.RESTORE, text)
    }
}

/**
 * Kare kare gelen OCR çıktısını izler; altyazı kararlı hale gelince çevrilmesini, ekrandan kalkınca TV'den
 * temizlenmesini ister. Aynı altyazıyı tekrar göndermez. Kararlar okuma hızına değil saate bağlıdır.
 * Windows'taki GameTranslator.Core/SubtitleStabilizer.cs ile aynı kurallar.
 */
class SubtitleStabilizer(
    private val similarity: Double = 0.85,
    private val stableFrames: Int = 2,
    private val clearAfterMs: Int = CLEAR_AFTER_MS,
    private val clock: () -> Long = { android.os.SystemClock.elapsedRealtime() },
) {
    companion object {
        /** Bölge bu kadar boş kalırsa altyazı kalkmış sayılır. */
        const val CLEAR_AFTER_MS = 800
        /** Kalkan satır bu süre içinde geri gelirse aynı satırdır; yeniden çevrilmez. */
        const val RESTORE_WITHIN_MS = 1500
        /** Çevirisi başarısız olan satır en erken bu kadar sonra yeniden denenir. */
        const val RETRY_AFTER_MS = 1000
        /** Çöp gibi okunan satır ancak bu kadar süre aynı okununca gider. */
        const val GARBLED_STABLE_MS = 700
        private const val HISTORY_SIZE = 5

        /** Satır nokta, ünlem, soru ya da üç noktayla bitiyor mu (kapanan tırnak ve parantezler yok sayılır). */
        fun endsSentence(raw: String): Boolean {
            val text = raw.trim().trimEnd('"', '\'', '”', '’', '»', ')', ']')
            return text.isNotEmpty() && ".!?…".contains(text.last())
        }
    }

    private data class Left(val rows: String, val raw: String, val leftAt: Long)

    private var candidate = ""
    private var candidateCount = 0
    private var candidateSince = 0L
    /** Ekrandaki (gönderilmiş) satır: sadeleştirilmiş satırlar alt alta, ve ilk okunduğu hali. */
    private var sent = ""
    private var sentRaw = ""
    private var emptySince: Long? = null
    private val history = mutableListOf<Left>()
    /** Çevirisi başarısız olan satır ve en erken yeniden deneneceği an. */
    private var forgotten = ""
    private var retryAt = 0L

    fun feed(rawText: String): StabilizerAction {
        val time = clock()
        val text = TextMatch.normalize(rawText)
        // 3 karakterden kısa okumalar (gürültü, tek simge) boş kare sayılır.
        if (text.length < 3) {
            candidate = ""
            candidateCount = 0
            val since = emptySince ?: time.also { emptySince = it }
            if (sent.isNotEmpty() && time - since >= clearAfterMs) {
                leaveScreen(time)
                return StabilizerAction.Clear
            }
            return StabilizerAction.None
        }

        emptySince = null
        if (TextMatch.isSimilar(text, candidate, similarity)) {
            candidateCount++
        } else {
            candidate = text
            candidateCount = 1
            candidateSince = time
        }
        // Noktalamayla biten satır tamamdır; beklemeden ilk karede gider. Çöp gibi okunan satır beklemeden gitmez.
        val garbled = OcrNoise.looksGarbled(rawText)
        val ready = if (garbled) candidateCount >= stableFrames && time - candidateSince >= GARBLED_STABLE_MS
        else candidateCount >= stableFrames || endsSentence(rawText)
        // Gönderilenin gürültülü yeniden okuması yeni satır değildir.
        if (isSame(text, sent)) return StabilizerAction.None
        if (!ready) return StabilizerAction.None
        // Aynı cümlenin daha iyi olmayan okuması da yeni satır değildir.
        if (sentRaw.isNotEmpty() && TextMatch.isWorseReread(rawText, sentRaw)) return StabilizerAction.None

        // Az önce kalkan satır geri geldiyse okuma birkaç kare kaçmıştır: çevirisi yeniden gösterilir.
        val index = history.indexOfLast { time - it.leftAt <= RESTORE_WITHIN_MS && isSame(text, it.rows) }
        if (index >= 0) {
            val back = history.removeAt(index)
            leaveScreen(time)
            sent = back.rows
            sentRaw = back.raw
            return StabilizerAction.restore(back.raw)
        }
        // Çevirisi az önce başarısız olan satır her karede yeniden istenmez.
        if (forgotten.isNotEmpty() && time < retryAt && isSame(text, forgotten)) return StabilizerAction.None

        leaveScreen(time)
        forgotten = ""
        sentRaw = rawText.trim()
        sent = TextMatch.normalizeRows(sentRaw)
        return StabilizerAction.translate(sentRaw)
    }

    private fun isSame(text: String, rows: String) = rows.isNotEmpty() && TextMatch.isSameSubtitle(text, rows)

    /** Ekrandaki satırı geçmişe yazar (kalktı ya da yerine başkası geldi). */
    private fun leaveScreen(time: Long) {
        if (sent.isEmpty()) return
        history.add(Left(sent, sentRaw, time))
        if (history.size > HISTORY_SIZE) history.removeAt(0)
        sent = ""
        sentRaw = ""
    }

    /** Çeviri kaynağıyla neredeyse aynıysa metin zaten hedef dildedir (ör. konsolun Türkçe menüleri). */
    fun shouldSend(source: String, translation: String): Boolean =
        !TextMatch.isSimilar(TextMatch.normalize(source), TextMatch.normalize(translation), 0.90)

    /** Son gönderilen satırı unutur (çevirisi başarısız oldu); satır ekranda kaldıkça en erken 1 sn sonra yeniden denenir. */
    fun forgetSent() {
        if (sent.isNotEmpty()) forgotten = sent
        retryAt = clock() + RETRY_AFTER_MS
        sent = ""
        sentRaw = ""
        candidate = ""
        candidateCount = 0
    }

    fun reset(): StabilizerAction {
        candidate = ""
        candidateCount = 0
        emptySince = null
        history.clear()
        forgotten = ""
        if (sent.isEmpty()) return StabilizerAction.None
        sent = ""
        sentRaw = ""
        return StabilizerAction.Clear
    }
}
