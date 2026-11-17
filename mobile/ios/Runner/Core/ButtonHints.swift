// SPDX-License-Identifier: AGPL-3.0-only
// Yalnız iOS'ta (henüz): Kotlin karşılığı yok. Android ve Windows'a da taşınırsa kurallar aynı tutulmalı.
import Foundation

/// Altyazı bölgesine giren oyun düğmesi yazıları: "...who does. RESUME BA", "SKIP RESUME BA". Bunlar çeviriye
/// karışıyordu ("BA'yı DEVAM ET"). Satırın sonundaki büyük harfli düğme sözcükleri (RESUME, SKIP, ...) ve yanlarındaki
/// tuş işaretleri (1–2 karakter: "A", "BA", "R1") silinir. Silinecek kuyrukta en az bir düğme sözcüğü bulunmalı ve
/// kuyruk ya satırın tamamı olmalı ya da cümle sonu işaretinden (. ! ? … ") sonra gelmeli; normal diyalog etkilenmez.
enum ButtonHints {
  static let words: Set<String> = [
    "RESUME", "SKIP", "CONTINUE", "BACK", "SELECT", "CLOSE", "CONFIRM", "CANCEL", "NEXT", "EXIT", "HOLD", "PRESS",
    "OPTIONS", "MENU", "ACCEPT", "DECLINE", "RETURN", "PAUSE", "LOG", "JOURNAL", "PROCEED",
  ]

  /// Satırın sonundaki düğme yazıları atılmış hali; satır yalnız düğme yazısıysa boş metin.
  static func strip(_ line: String) -> String {
    let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
    var cut = tokens.count
    var sawWord = false
    while cut > 0 {
      let token = tokens[cut - 1]
      if words.contains(token) { sawWord = true } else if !isGlyph(token) { break }
      cut -= 1
    }
    guard sawWord, cut < tokens.count else { return line }
    if cut == 0 { return "" }
    let kept = tokens[..<cut].joined(separator: " ")
    guard let last = kept.last, ".!?…\"”'’".contains(last) else { return line }
    return kept
  }

  /// Tuş işareti gibi okunan kısa parça: 1–2 büyük harf ya da rakam ("A", "BA", "R1", "L2", "X").
  private static func isGlyph(_ token: String) -> Bool {
    (1...2).contains(token.count) && token.unicodeScalars.allSatisfy { ("A"..."Z").contains($0) || ("0"..."9").contains($0) }
  }
}
