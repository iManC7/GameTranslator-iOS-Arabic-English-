// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/SubtitleStabilizer.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

enum StabilizerKind: Sendable { case none, translate, clear, restore }

/// Okuma hattının bir kareye vereceği tepki.
struct StabilizerAction: Equatable, Sendable {
  let kind: StabilizerKind
  let text: String?

  init(_ kind: StabilizerKind, _ text: String? = nil) {
    self.kind = kind
    self.text = text
  }

  static let None = StabilizerAction(.none)
  static let Clear = StabilizerAction(.clear)
  static func translate(_ text: String) -> StabilizerAction { StabilizerAction(.translate, text) }
  /// Az önce kalkan satır geri geldi; çevirisi yeniden gösterilir, yeniden çevrilmez.
  static func restore(_ text: String) -> StabilizerAction { StabilizerAction(.restore, text) }

  /// Kotlin data class eşitliği (String.equals: UTF-16 birimleri birebir).
  static func == (a: StabilizerAction, b: StabilizerAction) -> Bool {
    a.kind == b.kind && a.text.map { Array($0.utf16) } == b.text.map { Array($0.utf16) }
  }
}

/// Kare kare gelen OCR çıktısını izler; altyazı kararlı hale gelince çevrilmesini, ekrandan kalkınca TV'den
/// temizlenmesini ister. Aynı altyazıyı tekrar göndermez. Kararlar okuma hızına değil saate bağlıdır.
/// Windows'taki GameTranslator.Core/SubtitleStabilizer.cs ile aynı kurallar.
final class SubtitleStabilizer {
  /// Bölge bu kadar boş kalırsa altyazı kalkmış sayılır.
  static let CLEAR_AFTER_MS = 800
  /// Kalkan satır bu süre içinde geri gelirse aynı satırdır; yeniden çevrilmez.
  static let RESTORE_WITHIN_MS = 1500
  /// Çevirisi başarısız olan satır en erken bu kadar sonra yeniden denenir.
  static let RETRY_AFTER_MS = 1000
  /// Çöp gibi okunan satır ancak bu kadar süre aynı okununca gider.
  static let GARBLED_STABLE_MS = 700
  private static let HISTORY_SIZE = 5

  private static let CLOSERS = KotlinText.units("\"'”’»)]")
  private static let ENDERS = KotlinText.units(".!?…")

  /// Satır nokta, ünlem, soru ya da üç noktayla bitiyor mu (kapanan tırnak ve parantezler yok sayılır).
  static func endsSentence(_ raw: String) -> Bool {
    var text = KotlinText.trim(KotlinText.units(raw))
    while let last = text.last, CLOSERS.contains(last) { text.removeLast() }
    return !text.isEmpty && ENDERS.contains(text[text.count - 1])
  }

  /// Monoton saat (Android'deki SystemClock.elapsedRealtime karşılığı), milisaniye.
  static func monotonicMillis() -> Int64 { Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000) }

  private struct Left {
    let rows: String
    let raw: String
    let leftAt: Int64
  }

  private let similarity: Double
  private let stableFrames: Int
  private let clearAfterMs: Int
  private let clock: () -> Int64

  init(
    similarity: Double = 0.85,
    stableFrames: Int = 2,
    clearAfterMs: Int = SubtitleStabilizer.CLEAR_AFTER_MS,
    clock: @escaping () -> Int64 = SubtitleStabilizer.monotonicMillis
  ) {
    self.similarity = similarity
    self.stableFrames = stableFrames
    self.clearAfterMs = clearAfterMs
    self.clock = clock
  }

  private var candidate = ""
  private var candidateCount = 0
  private var candidateSince: Int64 = 0
  /// Ekrandaki (gönderilmiş) satır: sadeleştirilmiş satırlar alt alta, ve ilk okunduğu hali.
  private var sent = ""
  private var sentRaw = ""
  private var emptySince: Int64?
  private var history: [Left] = []
  /// Çevirisi başarısız olan satır ve en erken yeniden deneneceği an.
  private var forgotten = ""
  private var retryAt: Int64 = 0

  func feed(_ rawText: String) -> StabilizerAction {
    let time = clock()
    let text = TextMatch.normalize(rawText)
    // 3 karakterden kısa okumalar (gürültü, tek simge) boş kare sayılır.
    if text.utf16.count < 3 {
      candidate = ""
      candidateCount = 0
      let since: Int64
      if let existing = emptySince { since = existing } else { since = time; emptySince = time }
      if !sent.isEmpty && time - since >= Int64(clearAfterMs) {
        leaveScreen(time)
        return StabilizerAction.Clear
      }
      return StabilizerAction.None
    }

    emptySince = nil
    if TextMatch.isSimilar(text, candidate, similarity) {
      candidateCount += 1
    } else {
      candidate = text
      candidateCount = 1
      candidateSince = time
    }
    // Noktalamayla biten satır tamamdır; beklemeden ilk karede gider. Çöp gibi okunan satır beklemeden gitmez.
    let garbled = OcrNoise.looksGarbled(rawText)
    let ready = garbled
      ? candidateCount >= stableFrames && time - candidateSince >= Int64(SubtitleStabilizer.GARBLED_STABLE_MS)
      : candidateCount >= stableFrames || SubtitleStabilizer.endsSentence(rawText)
    // Gönderilenin gürültülü yeniden okuması yeni satır değildir.
    if isSame(text, sent) { return StabilizerAction.None }
    if !ready { return StabilizerAction.None }
    // Aynı cümlenin daha iyi olmayan okuması da yeni satır değildir.
    if !sentRaw.isEmpty && TextMatch.isWorseReread(rawText, sentRaw) { return StabilizerAction.None }

    // Az önce kalkan satır geri geldiyse okuma birkaç kare kaçmıştır: çevirisi yeniden gösterilir.
    if let index = history.lastIndex(where: {
      time - $0.leftAt <= Int64(SubtitleStabilizer.RESTORE_WITHIN_MS) && isSame(text, $0.rows)
    }) {
      let back = history.remove(at: index)
      leaveScreen(time)
      sent = back.rows
      sentRaw = back.raw
      return StabilizerAction.restore(back.raw)
    }
    // Çevirisi az önce başarısız olan satır her karede yeniden istenmez.
    if !forgotten.isEmpty && time < retryAt && isSame(text, forgotten) { return StabilizerAction.None }

    leaveScreen(time)
    forgotten = ""
    sentRaw = KotlinText.trim(rawText)
    sent = TextMatch.normalizeRows(sentRaw)
    return StabilizerAction.translate(sentRaw)
  }

  private func isSame(_ text: String, _ rows: String) -> Bool { !rows.isEmpty && TextMatch.isSameSubtitle(text, rows) }

  /// Ekrandaki satırı geçmişe yazar (kalktı ya da yerine başkası geldi).
  private func leaveScreen(_ time: Int64) {
    if sent.isEmpty { return }
    history.append(Left(rows: sent, raw: sentRaw, leftAt: time))
    if history.count > SubtitleStabilizer.HISTORY_SIZE { history.remove(at: 0) }
    sent = ""
    sentRaw = ""
  }

  /// Çeviri kaynağıyla neredeyse aynıysa metin zaten hedef dildedir (ör. konsolun Türkçe menüleri).
  func shouldSend(_ source: String, _ translation: String) -> Bool {
    !TextMatch.isSimilar(TextMatch.normalize(source), TextMatch.normalize(translation), 0.90)
  }

  /// Son gönderilen satırı unutur (çevirisi başarısız oldu); satır ekranda kaldıkça en erken 1 sn sonra yeniden denenir.
  func forgetSent() {
    if !sent.isEmpty { forgotten = sent }
    retryAt = clock() + Int64(SubtitleStabilizer.RETRY_AFTER_MS)
    sent = ""
    sentRaw = ""
    candidate = ""
    candidateCount = 0
  }

  @discardableResult
  func reset() -> StabilizerAction {
    candidate = ""
    candidateCount = 0
    emptySince = nil
    history.removeAll()
    forgotten = ""
    if sent.isEmpty { return StabilizerAction.None }
    sent = ""
    sentRaw = ""
    return StabilizerAction.Clear
  }
}
