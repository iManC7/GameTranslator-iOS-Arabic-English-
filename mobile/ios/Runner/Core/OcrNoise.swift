// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/OcrNoise.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Süslü yazı tiplerinde, solan ya da titreyen altyazıda yazı tanıma bazı sözcükleri harf, rakam ve simge
/// karışımı çöpe çevirir ("ou$3e", "waters2aljd"). Windows'taki GameTranslator.Core/OcrNoise.cs ile aynı kurallar.
enum OcrNoise {
  private static let SYMBOLS = KotlinText.units("$@#%^*_=|\\~<>{}¢£¥§©®°±µ¶¤")
  // Java'da `\d` yalnız ASCII rakamdır (ICU'da Unicode Nd); aynı anlam için [0-9] yazılır.
  private static let leadingNumber = KotlinText.fullMatchRegex("^[0-9]+(?:m|km|ft|yd)?[.?!:;]?$")
  private static let usual = KotlinText.fullMatchRegex(
    "^(?:[A-Za-z]{1,4}[0-9]{1,4}|[0-9]+(?:st|nd|rd|th|s|k|K|m|km|kg|cm|mm|p|x|fps|hp|HP|XP|xp|v|V|D|d)|[xX][0-9]{1,3}" +
      "|[0-9]+[.,][0-9]+[A-Za-z]{0,3}|[0-9]{1,2}[:.][0-9]{2}(?:am|pm|AM|PM)?)$")

  private static let EDGE_EXTRA = KotlinText.units("\"'“”‘’«»()[]")
  private static let STRAY = KotlinText.units("?!.,;:")
  private static let SENTENCE_END = KotlinText.units(".?!…,;:")
  private static let BRACKETS = KotlinText.units("[]()")
  private static let VOWELS = KotlinText.units("aeiouyäöüıàáâèéêìíîòóôùúû")
  private static let MISREAD_SUFFIXES: [UTF16Text] = ["m", "ll", "ve", "d"].map { KotlinText.units($0) }
  private static let APOSTROPHE: UInt16 = 0x27 // '
  private static let RIGHT_QUOTE: UInt16 = 0x2019 // ’
  private static let HYPHEN: UInt16 = 0x2D
  private static let LOWER_L: UInt16 = 0x6C
  private static let PIPE: UInt16 = 0x7C
  private static let DOT: UInt16 = 0x2E
  private static let CAPITAL_I = KotlinText.units("I")

  static func tokens(_ text: String) -> [String] { tokens(KotlinText.units(text)).map { KotlinText.string($0) } }

  static func tokens(_ text: UTF16Text) -> [UTF16Text] { KotlinText.splitJavaWhitespace(text).filter { !$0.isEmpty } }

  /// C#'taki char.IsNumber: ondalık rakam, harf-sayı (Ⅳ) ve diğer sayılar (½, ²).
  static func isNumber(_ c: UInt16) -> Bool {
    switch KotlinText.category(c) {
    case .decimalNumber, .letterNumber, .otherNumber: return true
    default: return false
    }
  }

  private static func isPunctuationOrSymbol(_ c: UInt16) -> Bool {
    switch KotlinText.category(c) {
    case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation, .initialPunctuation,
      .finalPunctuation, .otherPunctuation, .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol:
      return true
    default: return false
    }
  }

  static func clean(_ line: String) -> String {
    var kept: [UTF16Text] = []
    let tokens = tokens(KotlinText.units(line))
    for index in tokens.indices {
      let token = tokens[index]
      let (lead, core, trail) = split(token)
      // Tek başına "l" ya da "|" çoğu zaman yanlış okunmuş "I"dır; ardından küçük harfle süren sözcük
      // gelmiyorsa altyazı kutusunun kenarıdır, atılır.
      if let pronoun = misreadI(core) {
        let next: UInt16 = index + 1 < tokens.count ? (tokens[index + 1].first { KotlinText.isLetter($0) } ?? 0) : 0
        if pronoun != CAPITAL_I || KotlinText.isLowerCase(next) { kept.append(lead + pronoun + trail) }
        continue
      }
      // Yalnız "?!", ".", "," gibi işaretlerden oluşan parça yazı tanımanın uydurmasıdır.
      if core.isEmpty && isStrayPunctuation(token) {
        if !kept.isEmpty && !SENTENCE_END.contains(kept[kept.count - 1].last!) { kept[kept.count - 1] += token }
        continue
      }
      if let fixedCore = cleanCore(core) { kept.append(lead + fixedCore + trail) }
      else if !trail.isEmpty && !kept.isEmpty { kept[kept.count - 1] += trail }
    }
    // Altyazının yanındaki göstergenin sayısı satırın başına yapışıyor ("9? We'll lose"): sayı atılır.
    if kept.count >= 3 && KotlinText.matches(leadingNumber, KotlinText.string(kept[0]))
      && KotlinText.isUpperCase(kept[1][0]) {
      kept.remove(at: 0)
    }
    return KotlinText.string(KotlinText.join(kept, [0x20]))
  }

  /// Bir okumanın ne kadar sözcük gibi göründüğü: düzgün sözcüklerin harfleri artı, çöp parçalar eksi sayılır.
  static func score(_ text: String) -> Int {
    var score = 0
    for token in tokens(KotlinText.units(text)) {
      let core = split(token).1
      let letters = core.filter { KotlinText.isLetter($0) }.count
      if letters == 0 { continue }
      let clean = cleanCore(core) == core && normalCase(core) && !core.contains { BRACKETS.contains($0) }
      score += clean ? letters : -2 * letters
    }
    return score
  }

  /// Okuma çöp gibi mi: harflerinin altıda birinden çoğu bozuk sözcüklerde.
  static func looksGarbled(_ text: String) -> Bool {
    var good = 0
    var bad = 0
    for token in tokens(KotlinText.units(text)) {
      let core = split(token).1
      let letters = core.filter { KotlinText.isLetter($0) }
      if letters.isEmpty { continue }
      let clean = cleanCore(core) == core && normalCase(core) && !core.contains { BRACKETS.contains($0) }
        && !vowelless(letters)
      if clean { good += letters.count } else { bad += letters.count }
    }
    return bad * 6 > good + bad
  }

  /// Üç ve daha çok harfli, ünlüsüz ve kısaltma olmayan sözcük: İngilizcede olmaz ("Gtt", "rnnk").
  private static func vowelless(_ letters: UTF16Text) -> Bool {
    letters.count >= 3 && !letters.allSatisfy { KotlinText.isUpperCase($0) }
      && !KotlinText.lowercaseRoot(KotlinText.string(letters)).utf16.contains { VOWELS.contains($0) }
  }

  /// "word", "WORD", "Word", "McDonald", "don't": büyük harf yalnız başta ya da baştan bir dizi.
  private static func normalCase(_ core: UTF16Text) -> Bool {
    let letters = core.filter { KotlinText.isLetter($0) }
    let rest = letters.dropFirst()
    if letters.allSatisfy({ KotlinText.isUpperCase($0) }) || rest.allSatisfy({ KotlinText.isLowerCase($0) }) {
      return true
    }
    return rest.filter { KotlinText.isUpperCase($0) }.count == 1 && letters.filter { KotlinText.isLowerCase($0) }.count >= 2
  }

  /// "l", "|", "l'm", "|'ll" → "I", "I'm", "I'll" (null: böyle bir okuma değil).
  private static func misreadI(_ core: UTF16Text) -> UTF16Text? {
    if core.isEmpty || (core[0] != LOWER_L && core[0] != PIPE) { return nil }
    if core.count == 1 { return CAPITAL_I }
    if core[1] != APOSTROPHE && core[1] != RIGHT_QUOTE { return nil }
    if !MISREAD_SUFFIXES.contains(Array(core[2...])) { return nil }
    return CAPITAL_I + core[1...]
  }

  /// Yalnız ? ! . , ; : işaretlerinden oluşan parça; üç nokta ("...") gerçek noktalamadır.
  private static func isStrayPunctuation(_ token: UTF16Text) -> Bool {
    !token.isEmpty && token.allSatisfy { STRAY.contains($0) } && !(token.count >= 2 && token.allSatisfy { $0 == DOT })
  }

  /// Sözcüğün kendisi; null ise tamamen çöptür.
  private static func cleanCore(_ core: UTF16Text) -> UTF16Text? {
    let letters = core.filter { KotlinText.isLetter($0) }.count
    let digits = core.filter { isNumber($0) }.count
    let hasSymbol = core.contains { SYMBOLS.contains($0) }
    if letters == 0 { return core } // "24", "$500", "…"
    if !hasSymbol && digits == 0 { return core }
    if !hasSymbol && isUsualMix(core) { return core }
    // Gerçek sözcüğe yapışmış çöp: baştaki en az 3 harf korunur ("waters2aljd" → "waters").
    let prefix = Array(core.prefix { KotlinText.isLetter($0) || $0 == APOSTROPHE || $0 == RIGHT_QUOTE || $0 == HYPHEN })
    return prefix.filter { KotlinText.isLetter($0) }.count >= 3 ? prefix : nil
  }

  /// "PS5", "R2", "2nd", "100m", "4K", "60fps", "x2", "R2-D2": olağan harf-rakam karışımları.
  private static func isUsualMix(_ core: UTF16Text) -> Bool {
    KotlinText.split(core, HYPHEN).allSatisfy { part in
      !part.contains { isNumber($0) } || KotlinText.matches(usual, KotlinText.string(part))
    }
  }

  private static func isEdge(_ c: UInt16) -> Bool {
    !SYMBOLS.contains(c) && (isPunctuationOrSymbol(c) || EDGE_EXTRA.contains(c))
  }

  /// (baştaki işaretler, sözcük, sondaki işaretler)
  static func split(_ token: UTF16Text) -> (UTF16Text, UTF16Text, UTF16Text) {
    var start = 0
    var end = token.count
    while start < end && isEdge(token[start]) { start += 1 }
    while end > start && isEdge(token[end - 1]) { end -= 1 }
    return (Array(token[0..<start]), Array(token[start..<end]), Array(token[end...]))
  }

  static func split(_ token: String) -> (String, String, String) {
    let (a, b, c) = split(KotlinText.units(token))
    return (KotlinText.string(a), KotlinText.string(b), KotlinText.string(c))
  }
}
