// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/Glossary.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Terim sözlüğü (Windows: Glossary.cs, aynı biçim ve kurallar). Dosya biçimi:
/// `{ "game": "God of War", "terms": { "Leviathan Axe": "Leviathan Baltası" }, "keep": ["Kratos", "Atreus"] }`.
/// `terms` İngilizce terimi verilen Türkçeyle değiştirir, `keep` adları olduğu gibi bırakır. Eşleşme büyük/küçük harfe
/// bakmaz, yalnız tam sözcüklerde olur, uzun terim önce gelir ("Leviathan Axe", "Axe"dan önce).
final class Glossary: Sendable {
  struct Term: Equatable, Sendable {
    let english: String
    let turkish: String
  }

  /// Metinde bulunan terim: konumu, sözlükteki İngilizcesi ve Türkçesi.
  /// [start] ve [length] UTF-16 birimleridir (Kotlin String indeksleri).
  struct Match: Equatable, Sendable {
    let start: Int
    let length: Int
    let english: String
    let turkish: String
  }

  /// Anahtar: `english.lowercase(Locale.ROOT)` UTF-16 birimleri (Kotlin String eşitliği).
  private let terms: [UTF16Text: Term]
  /// Uzundan kısaya terimler; arama bu sırayla yapılır.
  private let ordered: [(term: Term, english: UTF16Text)]

  private init(_ terms: [UTF16Text: Term]) {
    self.terms = terms
    self.ordered = terms.values
      .map { (term: $0, english: KotlinText.units($0.english)) }
      .sorted { a, b in
        if a.english.count != b.english.count { return a.english.count > b.english.count }
        return KotlinText.compare(a.english, b.english) < 0
      }
  }

  var count: Int { terms.count }
  var isEmpty: Bool { terms.isEmpty }

  /// Terimin Türkçesi; yoksa null.
  func turkish(_ english: String) -> String? {
    terms[KotlinText.units(KotlinText.lowercaseRoot(Glossary.collapse(english)))]?.turkish
  }

  /// Metindeki terimler: büyük/küçük harfe bakmadan, tam sözcük, uzun terim önce; çakışan kısa terim alınmaz.
  /// Sonuç metindeki sıraya göredir.
  func find(_ text: String) -> [Match] {
    var found: [Match] = []
    let units = KotlinText.units(text)
    if ordered.isEmpty || units.isEmpty { return found }
    for (term, english) in ordered {
      var start = 0
      while start <= units.count - english.count {
        let index = KotlinText.indexOf(units, english, from: start, ignoreCase: true)
        if index < 0 { break }
        let end = index + english.count
        if Glossary.isBoundary(units, index - 1) && Glossary.isBoundary(units, end)
          && !found.contains(where: { index < $0.start + $0.length && $0.start < end }) {
          found.append(Match(start: index, length: english.count, english: term.english, turkish: term.turkish))
        }
        start = index + 1
      }
    }
    // Kotlin sortBy kararlıdır; Swift sort kararlılığı garanti etmediği için eşit başlangıçlarda ekleme sırası korunur.
    return found.enumerated()
      .sorted { $0.element.start != $1.element.start ? $0.element.start < $1.element.start : $0.offset < $1.offset }
      .map { $0.element }
  }

  static let EMPTY = Glossary([:])

  /// [terms] İngilizce → Türkçe, [keep] olduğu gibi kalacak adlar. Harfsiz, boş ya da çok uzun girdi alınmaz.
  /// Kotlin'deki `Map` ekleme sırasını korur (aynı anahtarda sonraki kazanır); bu yüzden sıralı çiftler alınır.
  static func of(_ terms: KeyValuePairs<String, String>, keep: [String] = []) -> Glossary {
    of(pairs: terms.map { ($0.key, $0.value) }, keep: keep)
  }

  static func of(pairs terms: [(String, String)], keep: [String] = []) -> Glossary {
    var all: [UTF16Text: Term] = [:]
    func add(_ rawEnglish: String, _ rawTurkish: String) {
      let english = collapse(rawEnglish)
      let turkish = collapse(rawTurkish)
      // Harfsiz terim her yerde eşleşirdi; yer tutucu sayısı sınırlı olduğundan çok uzun terim de alınmaz.
      if !english.utf16.contains(where: { KotlinText.isLetter($0) }) || turkish.isEmpty || english.utf16.count > 80 {
        return
      }
      all[KotlinText.units(KotlinText.lowercaseRoot(english))] = Term(english: english, turkish: turkish)
    }
    for (english, turkish) in terms { add(english, turkish) }
    for name in keep { add(name, name) }
    return Glossary(all)
  }

  private static func isBoundary(_ text: UTF16Text, _ index: Int) -> Bool {
    index < 0 || index >= text.count || !KotlinText.isLetterOrDigit(text[index])
  }

  private static func collapse(_ text: String) -> String {
    let parts = KotlinText.splitJavaWhitespace(KotlinText.trim(KotlinText.units(text))).filter { !$0.isEmpty }
    return KotlinText.string(KotlinText.join(parts, [0x20]))
  }
}

/// Sözlük teriminin Türkçe eki (Windows: TurkishSuffix.cs, aynı kurallar). Çeviri motoru terimin yerindeki yer tutucu
/// ada bir ek koyar ("Zarmon'a", "Zarmon'un"); ek, hangi hâl olduğu korunarak gerçek terime göre yeniden kurulur:
/// ünlü uyumu (Kratos'u, Midgard'ı), kaynaştırma (Freya'ya, Freya'nın), ünsüz benzeşmesi (Kratos'ta); özel ad kesmeyle
/// ayrılır, cins ad bitişik yazılır ve p/ç/k yumuşar (kılıcı); çok sözcüklü, dar ünlüyle biten terim tamlama sayılır
/// (Leviathan Baltası'nı).
enum TurkishSuffix {
  private static let VOWELS = KotlinText.units("aeıioöuü")
  private static let BACK_VOWELS = KotlinText.units("aıou")
  private static let ROUNDED_VOWELS = KotlinText.units("ouöü")
  private static let HIGH_VOWELS = KotlinText.units("ıiuü")
  private static let VOICELESS = KotlinText.units("fstkçşhp")
  /// Daha uzun "ek" büyük olasılıkla ek değildir; dokunulmaz.
  private static let MAX_SUFFIX_LENGTH = 12

  private static func c(_ s: Unicode.Scalar) -> UInt16 { UInt16(s.value) }

  /// [term] + ek. [suffix] motorun yer tutucuya koyduğu ektir (kesmesiz: "a", "un", "ya", "dan"); boşsa terim döner.
  static func attach(_ term: String, _ suffix: String, _ apostrophe: Character = "'") -> String {
    if term.isEmpty || suffix.isEmpty { return term }
    var body = KotlinText.units(KotlinText.lowercaseTurkish(suffix))
    if body.count > MAX_SUFFIX_LENGTH || !body.allSatisfy({ KotlinText.isLetter($0) }) {
      return term + String(apostrophe) + suffix
    }

    let termUnits = KotlinText.units(term)
    let proper = KotlinText.isUpperCase(termUnits[0])
    let space = c(" ")
    let lastSpace = termUnits.lastIndex(of: space) ?? -1
    let lastWord = KotlinText.units(KotlinText.lowercaseTurkish(KotlinText.string(termUnits[(lastSpace + 1)...])))
    let lastLetter = lastWord.last { KotlinText.isLetter($0) }
    var lastVowel = lastWord.last { isVowel($0) }
    // Ünlüsüz kısaltma ("XP", "HP") harf adlarıyla okunur: "iks-pe" → ince, ünlüyle biter.
    let endsWithVowel = lastVowel == nil || (lastLetter != nil && isVowel(lastLetter!))
    if lastVowel == nil { lastVowel = c("e") }
    let compound = termUnits.contains(space) && lastLetter != nil && HIGH_VOWELS.contains(lastLetter!) && lastWord.count >= 3
    let voiceless = !endsWithVowel && lastLetter != nil && VOICELESS.contains(lastLetter!)

    // Baştaki kaynaştırma harfi yer tutucuya göreydi ("Zarmon" ünsüzle biter, çoğu zaman yoktur); atılır.
    if body.count >= 2 && body[0] == c("y") && (isVowel(body[1]) || body[1] == c("l")) {
      body = Array(body[1...])
    } else if body.count >= 3 && body[0] == c("n") && HIGH_VOWELS.contains(body[1]) && body[2] == c("n") {
      body = Array(body[1...])
    }

    let genitive = body.count >= 2 && HIGH_VOWELS.contains(body[0]) && body[1] == c("n")
      && (body.count == 2 || !isVowel(body[2]))
    let instrumental = body.count >= 2 && body[0] == c("l") && (body[1] == c("a") || body[1] == c("e"))
      && !(body.count >= 3 && body[2] == c("r"))
    var buffer: UTF16Text = []
    if isVowel(body[0]) {
      if compound || (endsWithVowel && genitive) { buffer = [c("n")] }
      else if endsWithVowel { buffer = [c("y")] }
    } else if body[0] == c("d") || body[0] == c("t") {
      if compound { buffer = [c("n")] }
      body = [compound || !voiceless ? c("d") : c("t")] + body[1...]
    } else if instrumental && (endsWithVowel || compound) {
      buffer = [c("y")]
    }

    let harmonized = harmonize(body, lastVowel!)
    if proper { return term + String(apostrophe) + KotlinText.string(buffer + harmonized) }
    let stem = buffer.isEmpty && isVowel(harmonized[0]) ? soften(term) : term
    return stem + KotlinText.string(buffer + harmonized)
  }

  /// Ekteki a/e ve ı/i/u/ü ünlülerini önceki ünlüye uydurur; "-ki" (Midgard'daki) değişmez.
  static func harmonize(_ body: UTF16Text, _ lastVowel: UInt16) -> UTF16Text {
    var output = UTF16Text()
    output.reserveCapacity(body.count)
    var previous = lastVowel
    let ae = [c("a"), c("e")]
    for i in body.indices {
      var ch = body[i]
      let invariantKi = ch == c("i") && i > 0 && body[i - 1] == c("k") && i == body.count - 1
      if !invariantKi && ae.contains(ch) {
        ch = BACK_VOWELS.contains(previous) ? c("a") : c("e")
      } else if !invariantKi && HIGH_VOWELS.contains(ch) {
        let back = BACK_VOWELS.contains(previous)
        let rounded = ROUNDED_VOWELS.contains(previous)
        ch = back ? (rounded ? c("u") : c("ı")) : (rounded ? c("ü") : c("i"))
      }
      if isVowel(ch) { previous = ch }
      output.append(ch)
    }
    return output
  }

  static func harmonize(_ body: String, _ lastVowel: Character) -> String {
    KotlinText.string(harmonize(KotlinText.units(body), String(lastVowel).utf16.first!))
  }

  /// Cins adın son p/ç/k'si ünlüyle başlayan ekten önce yumuşar (kitap → kitabı, kılıç → kılıcı, bıçak → bıçağı,
  /// renk → rengi). Tek heceli sözcükler yumuşamaz (top → topu); t çoğu sözcükte yumuşamadığı için dokunulmaz.
  static func soften(_ term: String) -> String {
    let units = KotlinText.units(term)
    if units.count < 2 { return term }
    let lower = KotlinText.units(KotlinText.lowercaseTurkish(term))
    let lastSpace = lower.lastIndex(of: c(" ")) ?? -1
    let word = Array(lower[(lastSpace + 1)...])
    let stem = Array(units.dropLast())
    if word.count >= 2 && word[word.count - 2] == c("n") && word[word.count - 1] == c("k") {
      return KotlinText.string(stem) + "g"
    }
    if word.filter({ isVowel($0) }).count < 2 { return term }
    switch units[units.count - 1] {
    case c("p"): return KotlinText.string(stem) + "b"
    case c("ç"): return KotlinText.string(stem) + "c"
    case c("k"): return KotlinText.string(stem) + "ğ"
    default: return term
    }
  }

  static func isVowel(_ ch: UInt16) -> Bool { VOWELS.contains(ch) }
}

/// Sözlük terimlerini çeviriden korur (Windows: TermProtection.cs, aynı kurallar). Terim, çeviri öncesinde uydurma bir
/// özel adla ("Zarmon", "Velkor") değiştirilir: çeviri motorları özel adı olduğu gibi bırakıp Türkçe ekini kesmeyle
/// ekler ("Zarmon'u al"). Çeviriden sonra ad bulunur, yerine Türkçe terim konur ve ek terime göre yeniden kurulur.
/// Bir ad çeviride yoksa sonuç güvenilmez sayılır (null), çağıran korumasız çeviriye döner.
final class TermProtector {
  /// Korunan terim: yer tutucusu ve yerine konacak Türkçe.
  struct Slot: Equatable, Sendable {
    let placeholder: String
    let english: String
    let turkish: String
  }

  private let glossary: Glossary
  private var free: [String]
  private var byTerm: [UTF16Text: Slot] = [:]
  private var byTermOrder: [UTF16Text] = []

  init(_ glossary: Glossary, _ sources: String...) {
    self.glossary = glossary
    let sourceUnits = sources.map { KotlinText.units($0) }
    free = TermProtector.PLACEHOLDERS.filter { p in
      let pu = KotlinText.units(p)
      return !sourceUnits.contains { KotlinText.contains($0, pu, ignoreCase: true) }
    }
  }

  /// Bütün yer tutucular; çıktıda beklenmeyen ad kalmasın diye.
  var allSlots: [Slot] { byTermOrder.map { byTerm[$0]! } }

  /// Terimleri yer tutucularla değiştirir; bu metinde kullanılan yer tutucular döner.
  @discardableResult
  func protect(_ text: String) -> (String, [Slot]) {
    let matches = glossary.find(text)
    if matches.isEmpty { return (text, []) }
    let units = KotlinText.units(text)
    var builder = UTF16Text()
    builder.reserveCapacity(units.count)
    var used: [Slot] = []
    var position = 0
    for match in matches {
      let key = KotlinText.units(KotlinText.lowercaseRoot(match.english))
      var slot = byTerm[key]
      if slot == nil {
        // Ad kalmadıysa geri kalan terimler korunmaz; motor onları kendi çevirir.
        if free.isEmpty { continue }
        let created = Slot(placeholder: free.removeFirst(), english: match.english, turkish: match.turkish)
        byTerm[key] = created
        byTermOrder.append(key)
        slot = created
      }
      builder.append(contentsOf: units[position..<match.start])
      builder.append(contentsOf: slot!.placeholder.utf16)
      position = match.start + match.length
      if !used.contains(slot!) { used.append(slot!) }
    }
    builder.append(contentsOf: units[position...])
    return (KotlinText.string(builder), used)
  }

  /// Yer tutucu adlar: Türkçe ve İngilizcede sözcük değil, birbirinin başı değil, i/I içermez (Türkçe büyük/küçük
  /// harf dönüşümü bozmasın), ünsüzle biter (yumuşamaz) ve kalın ünlülüdür.
  static let PLACEHOLDERS = ["Zarmon", "Velkor", "Dorvan", "Kelmar", "Tolvar", "Brandur", "Halvor", "Feldor"]

  private static let SENTENCE_SKIP = KotlinText.units("\"“'‘(-–—¡¿")
  private static let SENTENCE_END = KotlinText.units(".!?…")

  /// Yer tutucuları Türkçe terimle değiştirir. [expected] çıktıda en az bir kez geçmeli, [all] içindeki diğer
  /// adlar hiç geçmemeli; yoksa null.
  static func restore(_ output: String, _ expected: [Slot], _ all: [Slot]? = nil, _ apostrophe: Character = "'") -> String? {
    if expected.isEmpty && (all ?? []).isEmpty { return output }
    for slot in all ?? [] where !expected.contains(slot) && containsMatch(pattern(slot.placeholder), output) {
      return nil
    }
    var text = output
    for slot in expected {
      let pattern = pattern(slot.placeholder)
      if !containsMatch(pattern, text) { return nil }
      let current = text as NSString
      var result = ""
      var last = 0
      for match in pattern.matches(in: text, options: [], range: NSRange(location: 0, length: current.length)) {
        result += current.substring(with: NSRange(location: last, length: match.range.location - last))
        let suffix = group(match, 1, current) ?? group(match, 2, current) ?? ""
        let term = TurkishSuffix.attach(slot.turkish, suffix, apostrophe)
        result += startsSentence(KotlinText.units(text), match.range.location) ? capitalize(term) : term
        last = match.range.location + match.range.length
      }
      result += current.substring(from: last)
      text = result
    }
    return text
  }

  private static func group(_ match: NSTextCheckingResult, _ index: Int, _ text: NSString) -> String? {
    let range = match.range(at: index)
    return range.location == NSNotFound ? nil : text.substring(with: range)
  }

  private static func containsMatch(_ regex: NSRegularExpression, _ text: String) -> Bool {
    regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length)) != nil
  }

  /// Yer tutucu ve ardındaki ek: kesmeyle ("Zarmon'a", "Zarmon 'a") ya da bitişik ("Zarmona").
  /// Java `\s` yalnız ASCII boşluktur; ICU'da aynı anlam için açık sınıf yazılır.
  private static func pattern(_ placeholder: String) -> NSRegularExpression {
    KotlinText.regex(
      "(?<![\\p{L}\\p{N}])" + placeholder + "(?:[ \\t\\n\\x0B\\f\\r]?['’`´](\\p{L}+)|(\\p{L}+))?(?![\\p{L}\\p{N}])",
      [.caseInsensitive])
  }

  /// Metnin ya da cümlenin başı mı (önünde yalnız boşluk, tırnak, tire ya da cümle sonu var).
  private static func startsSentence(_ text: UTF16Text, _ index: Int) -> Bool {
    var i = index - 1
    while i >= 0 {
      let ch = text[i]
      i -= 1
      if KotlinText.isWhitespace(ch) || SENTENCE_SKIP.contains(ch) { continue }
      return SENTENCE_END.contains(ch)
    }
    return true
  }

  private static func capitalize(_ term: String) -> String {
    let units = KotlinText.units(term)
    if units.isEmpty || !KotlinText.isLowerCase(units[0]) { return term }
    return KotlinText.uppercaseTurkish(KotlinText.string(units[0..<1])) + KotlinText.string(units[1...])
  }
}

/// Çevirmeni sözlükle sarar: terimler korunarak çevrilir; motor bir yer tutucuyu düşürdüyse korumasız çeviriye dönülür
/// (terimsiz ama eksiksiz çeviri, eksik terimli çeviriden iyidir).
final class GlossaryTranslator: TextTranslator {
  private let glossary: Glossary
  private let inner: TextTranslator

  init(_ glossary: Glossary, _ inner: TextTranslator) {
    self.glossary = glossary
    self.inner = inner
  }

  convenience init(_ glossary: Glossary, _ inner: @escaping (String) -> String?) {
    self.init(glossary, FunctionTranslator(inner))
  }

  func translate(_ text: String) -> String? {
    if glossary.isEmpty { return inner.translate(text) }
    let protector = TermProtector(glossary, text)
    let (input, used) = protector.protect(text)
    if used.isEmpty { return inner.translate(text) }
    guard let translated = inner.translate(input) else { return nil }
    return TermProtector.restore(translated, used, protector.allSlots) ?? inner.translate(text)
  }
}
