// SPDX-License-Identifier: AGPL-3.0-only
// Yalnız iOS'ta (henüz): Kotlin karşılığı yok. Android ve Windows'a da taşınırsa kurallar aynı tutulmalı.
import Foundation

/// Altyazının başındaki konuşmacı adı: "ENZO: ...", "MINE GUARD: ...". Ad her satırda ayrı çevrilince tutarsız
/// çıkıyordu ("MAYIN KORUYUCU", "MADEN KORUYUCU", "MAYIN KORUCU"); ad çevrilmez, olduğu gibi kalır.
/// Ad yalnız büyük harf, rakam, boşluk ve . ' ’ - & işaretlerinden oluşur, en az iki harf içerir, en çok 30
/// karakterdir; ardından iki nokta ve boşluk gelir. Küçük harf içeren "Note: ..." gibi satırlar ad sayılmaz.
enum SpeakerName {
  private static let pattern = try! NSRegularExpression(pattern: "^([A-Z0-9][A-Z0-9 .'’&-]{0,29}):[ \\t]+(\\S.*)$",
                                                        options: [.dotMatchesLineSeparators])

  /// (ad ve ardındaki ": ", geri kalan metin). Ad yoksa ilk değer boştur.
  static func split(_ text: String) -> (String, String) {
    let range = NSRange(text.startIndex..., in: text)
    guard let match = pattern.firstMatch(in: text, range: range),
          let nameRange = Range(match.range(at: 1), in: text),
          let restRange = Range(match.range(at: 2), in: text) else { return ("", text) }
    let name = text[nameRange].trimmingCharacters(in: .whitespaces)
    guard name.unicodeScalars.filter({ CharacterSet.uppercaseLetters.contains($0) }).count >= 2 else { return ("", text) }
    return (name + ": ", String(text[restRange]))
  }
}

/// Çevirmeni sarar: konuşmacı adı çevirmene gönderilmez, çevirinin başına olduğu gibi konur.
final class SpeakerNameTranslator: TextTranslator {
  private let inner: TextTranslator

  init(_ inner: TextTranslator) { self.inner = inner }

  func translate(_ text: String) -> String? {
    let (name, rest) = SpeakerName.split(text)
    if name.isEmpty { return inner.translate(text) }
    guard let translated = inner.translate(rest)?.trimmingCharacters(in: .whitespacesAndNewlines), !translated.isEmpty else { return nil }
    return name + translated
  }
}
