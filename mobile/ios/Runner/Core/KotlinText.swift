// SPDX-License-Identifier: AGPL-3.0-only
// Port yardımcısı: Core/*.swift dosyalarının Kotlin (JVM) metin kurallarını birebir izlemesi için. Kotlin karşılığı yok;
// Core/ altındaki portlarla birlikte güncel tutulmalıdır.
import Foundation

/// Kotlin'deki `String` UTF-16 kod birimleriyle indekslenir; çekirdek portu bu yüzden metni `[UInt16]` olarak işler.
typealias UTF16Text = [UInt16]

/// JVM'deki `Char`/`String` davranışlarının Swift karşılıkları (java.lang.Character, kotlin.text).
enum KotlinText {
  @inline(__always) static func units(_ s: String) -> UTF16Text { Array(s.utf16) }

  @inline(__always) static func string<S: Sequence>(_ units: S) -> String where S.Element == UInt16 {
    String(decoding: Array(units), as: UTF16.self)
  }

  @inline(__always) static func isSurrogate(_ c: UInt16) -> Bool { c >= 0xD800 && c <= 0xDFFF }

  /// Character.getType(char): vekil (surrogate) birim tek başına Cs'dir, hiçbir harf/sayı sınıfına girmez.
  static func category(_ c: UInt16) -> Unicode.GeneralCategory {
    guard !isSurrogate(c), let scalar = Unicode.Scalar(c) else { return .surrogate }
    return scalar.properties.generalCategory
  }

  @inline(__always) private static func properties(_ c: UInt16) -> Unicode.Scalar.Properties? {
    guard !isSurrogate(c), let scalar = Unicode.Scalar(c) else { return nil }
    return scalar.properties
  }

  /// Character.isLetter: Lu, Ll, Lt, Lm, Lo.
  static func isLetter(_ c: UInt16) -> Bool {
    switch category(c) {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: return true
    default: return false
    }
  }

  /// Character.isDigit: Nd.
  static func isDigit(_ c: UInt16) -> Bool { category(c) == .decimalNumber }

  static func isLetterOrDigit(_ c: UInt16) -> Bool { isLetter(c) || isDigit(c) }

  /// Character.isUpperCase: Lu ya da Other_Uppercase (Unicode "Uppercase" özelliği).
  static func isUpperCase(_ c: UInt16) -> Bool { properties(c)?.isUppercase ?? false }

  /// Character.isLowerCase: Ll ya da Other_Lowercase (Unicode "Lowercase" özelliği).
  static func isLowerCase(_ c: UInt16) -> Bool { properties(c)?.isLowercase ?? false }

  /// Kotlin Char.isWhitespace: Character.isWhitespace || Character.isSpaceChar.
  static func isWhitespace(_ c: UInt16) -> Bool {
    switch c {
    case 0x09...0x0D, 0x1C...0x1F: return true
    default:
      switch category(c) {
      case .spaceSeparator, .lineSeparator, .paragraphSeparator: return true
      default: return false
      }
    }
  }

  /// Java regex'teki `\s` (UNICODE_CHARACTER_CLASS olmadan): [ \t\n\x0B\f\r].
  @inline(__always) static func isJavaRegexSpace(_ c: UInt16) -> Bool {
    c == 0x20 || (c >= 0x09 && c <= 0x0D)
  }

  /// Character.toUpperCase(char): basit (tek karakterlik) eşleme. Tam eşlemesi çok karakterli olanlar olduğu gibi kalır.
  static func uppercaseChar(_ c: UInt16) -> UInt16 {
    guard let p = properties(c) else { return c }
    let mapped = Array(p.uppercaseMapping.utf16)
    return mapped.count == 1 ? mapped[0] : c
  }

  /// Character.toLowerCase(char): basit eşleme ("İ" → "i"; tam eşlemesi "i̇" olur).
  static func lowercaseChar(_ c: UInt16) -> UInt16 {
    if c == 0x0130 { return 0x0069 }
    guard let p = properties(c) else { return c }
    let mapped = Array(p.lowercaseMapping.utf16)
    return mapped.count == 1 ? mapped[0] : c
  }

  /// Kotlin Char.equals(other, ignoreCase = true).
  static func equalsIgnoreCase(_ a: UInt16, _ b: UInt16) -> Bool {
    if a == b { return true }
    let ua = uppercaseChar(a)
    let ub = uppercaseChar(b)
    return ua == ub || lowercaseChar(ua) == lowercaseChar(ub)
  }

  /// Kotlin String.indexOf(other, startIndex, ignoreCase).
  static func indexOf(_ text: UTF16Text, _ other: UTF16Text, from startIndex: Int, ignoreCase: Bool) -> Int {
    let start = max(startIndex, 0)
    if other.isEmpty { return min(start, text.count) }
    let last = text.count - other.count
    if start > last { return -1 }
    var i = start
    while i <= last {
      var j = 0
      while j < other.count {
        let a = text[i + j]
        let b = other[j]
        if !(ignoreCase ? equalsIgnoreCase(a, b) : a == b) { break }
        j += 1
      }
      if j == other.count { return i }
      i += 1
    }
    return -1
  }

  static func contains(_ text: UTF16Text, _ other: UTF16Text, ignoreCase: Bool) -> Bool {
    indexOf(text, other, from: 0, ignoreCase: ignoreCase) >= 0
  }

  /// Kotlin String.trim(): baştaki ve sondaki Char.isWhitespace karakterleri.
  static func trim(_ s: UTF16Text) -> UTF16Text {
    var start = 0
    var end = s.count
    while start < end && isWhitespace(s[start]) { start += 1 }
    while end > start && isWhitespace(s[end - 1]) { end -= 1 }
    return Array(s[start..<end])
  }

  static func trim(_ s: String) -> String { string(trim(units(s))) }

  /// Kotlin CharSequence.isBlank().
  static func isBlank(_ s: String) -> Bool { s.utf16.allSatisfy { isWhitespace($0) } }

  /// Kotlin `split(Regex("\\s+"))` (Java `\s`); boş parçalar korunur.
  static func splitJavaWhitespace(_ s: UTF16Text) -> [UTF16Text] {
    var parts: [UTF16Text] = []
    var current: UTF16Text = []
    var i = 0
    while i < s.count {
      if isJavaRegexSpace(s[i]) {
        parts.append(current)
        current = []
        while i < s.count && isJavaRegexSpace(s[i]) { i += 1 }
      } else {
        current.append(s[i])
        i += 1
      }
    }
    parts.append(current)
    return parts
  }

  /// Kotlin `split(char)`: boş parçalar korunur ("" → [""]).
  static func split(_ s: UTF16Text, _ separator: UInt16) -> [UTF16Text] {
    s.split(separator: separator, omittingEmptySubsequences: false).map { Array($0) }
  }

  static func join(_ parts: [UTF16Text], _ separator: UTF16Text) -> UTF16Text {
    var out: UTF16Text = []
    for (i, part) in parts.enumerated() {
      if i > 0 { out.append(contentsOf: separator) }
      out.append(contentsOf: part)
    }
    return out
  }

  /// Kotlin String.compareTo: UTF-16 birimleriyle sözlük sırası.
  static func compare(_ a: UTF16Text, _ b: UTF16Text) -> Int {
    let n = min(a.count, b.count)
    for i in 0..<n where a[i] != b[i] { return Int(a[i]) - Int(b[i]) }
    return a.count - b.count
  }

  /// Kotlin `lowercase(Locale.ROOT)`: yerelden bağımsız (Türkçedeki noktasız ı sürprizi yok), tam eşleme ("İ" → "i̇").
  /// Swift'in `lowercased()`'ı bağlama bakmaz; JVM (ve paket betiğindeki Python `str.lower()`) sözcük sonundaki "Σ"yı
  /// "ς" yapar (Unicode Final_Sigma), o kural burada eklenir.
  static func lowercaseRoot(_ s: String) -> String {
    if !s.unicodeScalars.contains(where: { $0.value == 0x03A3 }) { return s.lowercased() }
    let scalars = Array(s.unicodeScalars)
    var out = String.UnicodeScalarView()
    for (i, scalar) in scalars.enumerated() {
      if scalar.value == 0x03A3 {
        out.append(isFinalSigma(scalars, i) ? "\u{03C2}" : "\u{03C3}")
      } else {
        out.append(contentsOf: scalar.properties.lowercaseMapping.unicodeScalars)
      }
    }
    return String(out)
  }

  /// Unicode Final_Sigma: önünde (büyük/küçük harfe duyarsızları atlayarak) harfli karakter var, ardında yok.
  private static func isFinalSigma(_ s: [Unicode.Scalar], _ index: Int) -> Bool {
    var i = index - 1
    while i >= 0 && s[i].properties.isCaseIgnorable { i -= 1 }
    if i < 0 || !s[i].properties.isCased { return false }
    var j = index + 1
    while j < s.count && s[j].properties.isCaseIgnorable { j += 1 }
    return j >= s.count || !s[j].properties.isCased
  }

  /// Kotlin String eşitliği (UTF-16 birimleri birebir); Swift `==` kanonik eşdeğerliğe bakar.
  static func same(_ a: String?, _ b: String?) -> Bool {
    guard let a = a, let b = b else { return a == nil && b == nil }
    return a.utf16.elementsEqual(b.utf16)
  }

  // MARK: Kod noktası (Int) sürümleri: java.lang.Character'in int alan yöntemleri.

  @inline(__always) static func codePointProperties(_ cp: UInt32) -> Unicode.Scalar.Properties? {
    Unicode.Scalar(cp)?.properties
  }

  /// Character.getType(int); vekil kod noktası Cs.
  static func category(codePoint cp: UInt32) -> Unicode.GeneralCategory {
    codePointProperties(cp)?.generalCategory ?? .surrogate
  }

  /// Character.isLetter(int).
  static func isLetter(codePoint cp: UInt32) -> Bool {
    switch category(codePoint: cp) {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: return true
    default: return false
    }
  }

  /// Character.isDigit(int): Nd.
  static func isDigit(codePoint cp: UInt32) -> Bool { category(codePoint: cp) == .decimalNumber }

  /// Character.isUpperCase(int).
  static func isUpperCase(codePoint cp: UInt32) -> Bool { codePointProperties(cp)?.isUppercase ?? false }

  /// Character.isLowerCase(int).
  static func isLowerCase(codePoint cp: UInt32) -> Bool { codePointProperties(cp)?.isLowercase ?? false }

  /// Character.isWhitespace(int) || Character.isSpaceChar(int).
  static func isWhitespace(codePoint cp: UInt32) -> Bool {
    switch cp {
    case 0x09...0x0D, 0x1C...0x1F: return true
    default:
      switch category(codePoint: cp) {
      case .spaceSeparator, .lineSeparator, .paragraphSeparator: return true
      default: return false
      }
    }
  }

  /// String.codePoints(): Swift dizesinde tek başına vekil olmaz; kod noktaları Unicode skalerleridir.
  @inline(__always) static func codePoints(_ s: String) -> [UInt32] { s.unicodeScalars.map { $0.value } }

  /// `String(int[] codePoints, offset, count)`.
  static func string(codePoints: ArraySlice<UInt32>) -> String {
    var view = String.UnicodeScalarView()
    for cp in codePoints { if let scalar = Unicode.Scalar(cp) { view.append(scalar) } }
    return String(view)
  }

  static func string(codePoints: [UInt32]) -> String { string(codePoints: codePoints[...]) }

  static let turkish = Locale(identifier: "tr_TR")

  /// Kotlin `lowercase(Locale.forLanguageTag("tr-TR"))`.
  static func lowercaseTurkish(_ s: String) -> String { s.lowercased(with: turkish) }

  /// Kotlin `uppercase(Locale.forLanguageTag("tr-TR"))`.
  static func uppercaseTurkish(_ s: String) -> String { s.uppercased(with: turkish) }

  /// Kotlin Regex.matches için derlenmiş desen: aynı desen, sonuna `\z` eklenir; [matches] baştan bağlar (tam eşleşme).
  static func fullMatchRegex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
    regex("(?:" + pattern + ")\\z", options)
  }

  /// Kotlin Regex.matches: [fullMatchRegex] ile derlenmiş desenin bütün girdiyle eşleşmesi.
  static func matches(_ fullMatch: NSRegularExpression, _ s: String) -> Bool {
    let range = NSRange(location: 0, length: (s as NSString).length)
    return fullMatch.firstMatch(in: s, options: [.anchored], range: range) != nil
  }

  static func regex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
    // Desenler sabittir; derlenemezse programlama hatasıdır.
    return try! NSRegularExpression(pattern: pattern, options: options)
  }
}
