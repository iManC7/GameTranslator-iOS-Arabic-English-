// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/SpeakerPrefix.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Altyazının başındaki konuşmacı işareti: tire ("- ", "– ", "— ") ya da ">>" (Windows'taki GoogleGtxTranslator ve
/// SubtitleSegmenter ile aynı kural). Çeviri motorları bu işaretleri silebildiği ya da bozabildiği için çeviriden
/// önce ayrılır, sonra olduğu gibi geri eklenir.
enum SpeakerPrefix {
  // Java'daki `\s` yalnız ASCII boşluklardır; ICU'daki Unicode `\s` yerine açık sınıf yazılır.
  private static let pattern = KotlinText.regex("^(?:[-–—]+|>{1,3})[ \\t\\n\\x0B\\f\\r]*")

  /// (işaret, geri kalan metin). İşaret yoksa ilk değer boştur.
  static func split(_ text: String) -> (String, String) {
    let trimmed = KotlinText.trim(text)
    let ns = trimmed as NSString
    guard let match = pattern.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: ns.length)) else {
      return ("", trimmed)
    }
    let value = ns.substring(with: match.range)
    return (value, KotlinText.trim(ns.substring(from: match.range.location + match.range.length)))
  }
}

/// Çevirmeni sarar: konuşmacı işareti çevirmene gönderilmez, çevirinin başına geri konur.
final class PrefixTranslator: TextTranslator {
  private let inner: TextTranslator

  init(_ inner: TextTranslator) { self.inner = inner }

  convenience init(_ inner: @escaping (String) -> String?) { self.init(FunctionTranslator(inner)) }

  func translate(_ text: String) -> String? {
    let (prefix, rest) = SpeakerPrefix.split(text)
    if prefix.isEmpty { return inner.translate(text) }
    // Yalnız işaretten oluşan satırda çevrilecek bir şey yoktur.
    if rest.isEmpty { return KotlinText.trim(prefix) }
    guard let translated = inner.translate(rest).map({ KotlinText.trim($0) }) else { return nil }
    return translated.isEmpty ? nil : prefix + translated
  }
}
