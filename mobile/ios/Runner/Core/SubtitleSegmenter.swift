// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Android'deki core/SubtitleSegmenter.kt'nin (SubtitleSegmenter ve PackLookup) Swift portu; onunla birebir aynı
// tutulmalıdır. Desenlerdeki `\s` ve `\d` Java'daki gibi ASCII'dir (ICU'da Unicode olurdu), açık sınıf yazılır.
import Foundation

/// Altyazıyı modele cümle cümle verir; konuşmacı etiketi ("ATREUS:", "Kratos:") ve diyalog tirelerine dokunulmaz.
enum SubtitleSegmenter {
  /// Çevrilecek bir parça ya da olduğu gibi kalacak ayraç/etiket.
  struct Piece: Equatable, Sendable {
    let text: String
    let translate: Bool

    init(_ text: String, _ translate: Bool) {
      self.text = text
      self.translate = translate
    }

    static func == (a: Piece, b: Piece) -> Bool { KotlinText.same(a.text, b.text) && a.translate == b.translate }
  }

  private static let SPACE = "[ \\t\\n\\x0B\\f\\r]"

  // Etiket: satır ya da cümle başında, en çok üç sözcüklü ad ve iki nokta. Ya tümü büyük harf ("ATREUS:", "OLD MAN:")
  // ya da her sözcüğü büyük harfle başlayan ("Kratos:", "Mimir Head:").
  private static let speakerLabelPattern = KotlinText.regex(
    "^(?<label>(?<name>\\p{Lu}[\\p{Lu}0-9'’.\\-]+(?:[ ]\\p{Lu}[\\p{Lu}0-9'’.\\-]*){0,2}|\\p{Lu}\\p{Ll}[\\p{L}'’.\\-]*(?:[ ]\\p{Lu}[\\p{L}'’.\\-]*){0,2}):)"
      + SPACE + "+"
  )

  /// Büyük harfle başlayıp iki noktayla biten ama ad olmayan oyun başlıkları; bunlar çevrilir.
  private static let notNames: Set<String> = [
    "note", "warning", "tip", "hint", "objective", "objectives", "quest", "goal", "new", "reward", "rewards",
    "location", "chapter", "mission", "task", "tutorial", "update", "info", "status", "level", "controls",
    "press", "hold", "tap", "remember", "example", "question", "answer", "result", "results", "time",
    "listen", "look", "wait", "okay", "ok", "well", "so", "yes", "no", "now", "then", "and", "but",
  ]

  private static let dialogueDash = KotlinText.regex("^(?<dash>[-–—]+)" + SPACE + "*")
  // Cümle sonu: . ! ? … ardından isteğe bağlı kapanış tırnağı/parantez ve boşluk (Java'daki sınırlı geriye bakış).
  private static let sentenceGap = KotlinText.regex("(?<=[.!?…][\"'”’)\\]]{0,10})" + SPACE + "+")
  private static let whitespace = KotlinText.regex(SPACE + "+")

  /// Noktadan sonra cümle bitmeyen kısaltmalar ("Mr. Smith").
  private static let abbreviations: Set<String> = [
    "mr", "mrs", "ms", "dr", "st", "jr", "sr", "prof", "mt", "vs", "etc", "e.g", "i.e", "lt", "sgt", "capt", "gen", "col",
  ]

  private static func whole(_ s: String) -> NSRange { NSRange(location: 0, length: s.utf16.count) }

  /// (etiket "ATREUS:", eşleşmenin boyu UTF-16) — satır başındaki konuşmacı etiketi; tek sözcüklü başlıklar ad sayılmaz.
  private static func speakerLabel(_ text: String) -> (label: String, length: Int)? {
    guard let match = speakerLabelPattern.firstMatch(in: text, options: [], range: whole(text)) else { return nil }
    let ns = text as NSString
    let name = ns.substring(with: match.range(withName: "name"))
    if !name.utf16.contains(0x20) && notNames.contains(KotlinText.lowercaseRoot(name)) { return nil }
    return (ns.substring(with: match.range(withName: "label")), match.range.length)
  }

  /// Etiket parçasındaki ad ("ATREUS: " → "ATREUS"); etiket değilse null.
  static func labelName(_ piece: Piece) -> String? {
    if piece.translate || !piece.text.hasSuffix(": ") { return nil }
    let units = KotlinText.units(piece.text)
    return KotlinText.string(units.dropLast(2))
  }

  static func split(_ text: String) -> [Piece] {
    var pieces: [Piece] = []
    var block = UTF16Text()
    var pendingSeparator = ""
    func flushBlock() {
      if block.isEmpty { return }
      if !pendingSeparator.isEmpty { pieces.append(Piece(pendingSeparator, false)) }
      addBlock(&pieces, KotlinText.string(block))
      block.removeAll()
      pendingSeparator = "\n"
    }
    for raw in KotlinText.split(replacingCRLF(KotlinText.units(text)), 0x0A) {
      let line = KotlinText.trim(raw)
      if line.isEmpty { continue }
      let lineText = KotlinText.string(line)
      // Etiketli ya da tireli satır yeni bir konuşmadır; diğer satırlar sarmadır, birleştirilir.
      if speakerLabel(lineText) != nil || dialogueDash.firstMatch(in: lineText, options: [], range: whole(lineText)) != nil {
        flushBlock()
      }
      if !block.isEmpty { block.append(0x20) }
      block.append(contentsOf: line)
    }
    flushBlock()
    return pieces
  }

  /// Kotlin `replace("\r\n", "\n")`.
  static func replacingCRLF(_ s: UTF16Text) -> UTF16Text {
    if !s.contains(0x0D) { return s }
    var out = UTF16Text()
    out.reserveCapacity(s.count)
    var i = 0
    while i < s.count {
      if s[i] == 0x0D && i + 1 < s.count && s[i + 1] == 0x0A {
        out.append(0x0A)
        i += 2
      } else {
        out.append(s[i])
        i += 1
      }
    }
    return out
  }

  private static func addBlock(_ pieces: inout [Piece], _ original: String) {
    var block = whitespace.stringByReplacingMatches(in: original, options: [], range: whole(original), withTemplate: " ")
    if let dash = dialogueDash.firstMatch(in: block, options: [], range: whole(block)) {
      let ns = block as NSString
      pieces.append(Piece(ns.substring(with: dash.range(withName: "dash")) + " ", false))
      block = ns.substring(from: dash.range.length)
    }
    var first = true
    for sentence in splitSentences(block) {
      if !first { pieces.append(Piece(" ", false)) }
      first = false
      var body = sentence
      if let label = speakerLabel(body) {
        pieces.append(Piece(label.label + " ", false))
        body = (body as NSString).substring(from: label.length)
      }
      if !body.isEmpty { pieces.append(Piece(body, body.utf16.contains { KotlinText.isLetter($0) })) }
    }
  }

  private static func splitSentences(_ block: String) -> [String] {
    var result: [String] = []
    let ns = block as NSString
    let units = KotlinText.units(block)
    var start = 0
    for gap in sentenceGap.matches(in: block, options: [], range: whole(block)) {
      let candidate = ns.substring(with: NSRange(location: start, length: gap.range.location - start))
      let after = gap.range.location + gap.range.length
      let next: UInt16 = after < units.count ? units[after] : 0
      // "wait... what" gibi küçük harfle süren yer ve kısaltmalar cümle sonu değildir.
      if KotlinText.isLowerCase(next) || endsWithAbbreviation(candidate) { continue }
      result.append(candidate)
      start = after
    }
    if start < units.count { result.append(ns.substring(from: start)) }
    return result
  }

  private static func endsWithAbbreviation(_ sentence: String) -> Bool {
    let units = KotlinText.units(sentence)
    guard units.last == 0x2E else { return false }
    let space = units.lastIndex(of: 0x20).map { $0 + 1 } ?? 0
    let word = Array(units[space..<(units.count - 1)])
    // Tek harf ad baş harfidir ("J. R. R.").
    return (word.count == 1 && KotlinText.isUpperCase(word[0]))
      || abbreviations.contains(KotlinText.lowercaseRoot(KotlinText.string(word)))
  }

  /// Tümü büyük harfli cümleyi ("THE GATE WILL NOT HOLD.") cümle düzenine çevirir; model büyük harfli sözcükleri ad
  /// sanıp çevirmeden bırakıyordu. Bilinen adlar (konuşmacı etiketlerinden öğrenilen) büyük harfle başlar.
  static func normalizeCase(_ sentence: String, _ names: Set<String> = []) -> String {
    let units = KotlinText.units(sentence)
    var letters = 0
    for c in units {
      if KotlinText.isLowerCase(c) { return sentence }
      if KotlinText.isLetter(c) { letters += 1 }
    }
    if letters < 2 || !KotlinText.trim(units).contains(0x20) { return sentence }
    var output = UTF16Text()
    output.reserveCapacity(units.count)
    var word = UTF16Text()
    var startOfSentence = true
    func flushWord() {
      if word.isEmpty { return }
      let lower = KotlinText.lowercaseRoot(KotlinText.string(word))
      let lowerUnits = KotlinText.units(lower)
      let capital = startOfSentence || lower == "i" || names.contains(lower)
      if capital, let head = lowerUnits.first {
        output.append(KotlinText.uppercaseChar(head))
        output.append(contentsOf: lowerUnits.dropFirst())
      } else {
        output.append(contentsOf: lowerUnits)
      }
      startOfSentence = false
      word.removeAll()
    }
    for c in units {
      if KotlinText.isLetter(c) || c == 0x27 || c == 0x2019 {
        word.append(c)
        continue
      }
      flushWord()
      if c == 0x2E || c == 0x21 || c == 0x3F || c == 0x2026 { startOfSentence = true }
      output.append(c)
    }
    flushWord()
    return KotlinText.string(output)
  }
}

/// Satırı oyun paketinde arar (Windows: PackLookup.cs, Mac: GamePacks.swift). Sırayla: satırın tamamı; konuşmacı
/// etiketi ya da diyalog tiresi varsa onsuz hâli (etiket çeviriye eklenir); birden çok satırsa her satır ayrı; birden çok
/// cümleyse her cümle ayrı. Parçalı aramada parçaların hepsi bulunmalıdır, yoksa satır motorla çevrilir. Tam anahtarla
/// hiçbir yol tutmazsa aynı sıra bir kez daha denenir; bu kez her parça önce tam, sonra `nearest` ile aranır.
enum PackLookup {
  typealias Pieces = (pieces: [SubtitleSegmenter.Piece], translations: [String?])

  /// Kütüphanedeki (açık) paketlerde arar (bulanık arama oynanan oyunun paketinde); sonuçta satırın son bulunan parçasının
  /// paketi yazılır.
  static func match(_ library: GamePackLibrary, _ text: String) -> PackMatch? {
    var lastPack: String?
    // Aynı parça bir aramada birkaç yoldan sorulabilir; bulanık sonuç bir kez hesaplanır.
    var asked: [UTF16Text: PackMatch?] = [:]
    let nearest = { (line: String) -> String? in
      let key = KotlinText.units(line)
      let near: PackMatch?
      if let cached = asked[key] {
        near = cached
      } else {
        near = library.nearestWithPack(line)
        asked[key] = .some(near)
      }
      if let near = near { lastPack = near.packId }
      return near?.text
    }
    let found = match(text, nearest) { line in
      guard let hit = library.findWithPack(line) else { return nil }
      lastPack = hit.packId
      return hit.text
    }
    return found.map { PackMatch(text: $0.text, packId: lastPack) }
  }

  /// [find]: tek bir metnin (tamamının) paketteki Türkçesi. [nearest]: tam anahtar yoksa en benzer satırın Türkçesi
  /// (bulanık arama); verilmezse yapılmaz.
  static func match(_ text: String, _ nearest: ((String) -> String?)? = nil, _ find: (String) -> String?) -> PackMatch? {
    let trimmed = KotlinText.trim(text)
    if trimmed.isEmpty { return nil }
    if let found = phase(trimmed, find) { return found }
    guard let nearest = nearest else { return nil }
    return phase(trimmed) { line in find(line) ?? nearest(line) }
  }

  private static func phase(_ trimmed: String, _ find: (String) -> String?) -> PackMatch? {
    if let found = single(trimmed, find) { return result(found.pieces, found.translations) }

    // Her satır ayrı bir altyazı olabilir (iki konuşmacı alt alta).
    let lines = KotlinText.split(SubtitleSegmenter.replacingCRLF(KotlinText.units(trimmed)), 0x0A)
      .map { KotlinText.trim($0) }.filter { !$0.isEmpty }.map { KotlinText.string($0) }
    if lines.count > 1 {
      var pieces: [SubtitleSegmenter.Piece] = []
      var translations: [String?] = []
      var all = true
      for line in lines {
        guard let found = single(line, find) else {
          // Altyazıyla aynı bloğa düşen köşe yazısı ("San Andreas", "First Person • zoom") atlanır.
          if isOverlay(line) { continue }
          all = false
          break
        }
        if !pieces.isEmpty {
          pieces.append(SubtitleSegmenter.Piece("\n", false))
          translations.append(nil)
        }
        pieces.append(contentsOf: found.pieces)
        translations.append(contentsOf: found.translations)
      }
      if all && !pieces.isEmpty { return result(pieces, translations) }
    }

    // Cümle cümle (etiket, tire ve ayraçlar olduğu gibi kalır).
    let split = SubtitleSegmenter.split(trimmed)
    if split.filter({ $0.translate }).count <= 1 { return nil }
    var sentences: [String?] = []
    sentences.reserveCapacity(split.count)
    for piece in split {
      if !piece.translate {
        sentences.append(nil)
        continue
      }
      guard let found = find(piece.text) else { return nil }
      sentences.append(found)
    }
    return result(split, sentences)
  }

  /// Tek satır: başında konuşmacı etiketi ya da diyalog tiresi varsa önce onlarsız hâli (etiket/tire çeviriye eklenir),
  /// sonra tamamı, sonra OCR'ın bozduğu etiketsiz hâli ([looseLabel]).
  private static func single(_ line: String, _ find: (String) -> String?) -> Pieces? {
    let split = SubtitleSegmenter.split(line)
    let lead = Array(split.prefix { !$0.translate })
    if !lead.isEmpty && lead.count < split.count && !split.contains(where: { $0.text == "\n" }) {
      let body = split.dropFirst(lead.count).map { $0.text }.joined()
      if let turkish = find(body) {
        return (lead + [SubtitleSegmenter.Piece(body, true)], [String?](repeating: nil, count: lead.count) + [turkish])
      }
    }
    if let turkish = find(line) { return ([SubtitleSegmenter.Piece(line, true)], [turkish]) }
    guard let (label, body) = looseLabel(line), let turkish = find(body) else { return nil }
    return ([SubtitleSegmenter.Piece(label, false), SubtitleSegmenter.Piece(body, true)], [nil, turkish])
  }

  /// Altyazı olmayan köşe yazısı satırı: "•" içerir ya da en çok dört sözcük, noktalama yok ve her sözcük büyük harfle
  /// başlar ("San Andreas", "Mirror Park", "LOSNN"). Yalnız başka satırlar pakette bulunduysa atlanır.
  static func isOverlay(_ line: String) -> Bool {
    if line.utf16.contains(0x2022) { return true }
    let words = PackFuzzy.words(line)
    if words.isEmpty || words.count > 4 { return false }
    return words.allSatisfy { word in
      KotlinText.isUpperCase(codePoint: word[0]) && word.allSatisfy { PackFuzzy.isLetter($0) || PackFuzzy.isDigit($0) }
    }
  }

  /// OCR'ın bozduğu konuşmacı etiketi: "-GAETANO:", "M]:", "li LUCA:", "MİNE GUARD•" (ilk 32 karakterde iki nokta ya da
  /// • ve önündeki sözcükte küçük harf yok) ya da iki noktasız "SEBASTIAN Where…" (en çok üç büyük harfli sözcük, ardından
  /// büyük harfle başlayan küçük harfli sözcük). (ekranda kalacak etiket, aranacak gövde) ya da null.
  static func looseLabel(_ line: String) -> (String, String)? {
    let points = KotlinText.codePoints(line)
    func text(_ start: Int, _ end: Int) -> String { KotlinText.string(codePoints: points[start..<end]) }
    func nameLike(_ token: ArraySlice<UInt32>, _ minimum: Int) -> Bool {
      let letters = token.filter { PackFuzzy.isLetter($0) }
      return letters.count >= minimum && !letters.contains { KotlinText.isLowerCase(codePoint: $0) }
    }
    func isNumber(_ cp: UInt32) -> Bool {
      switch KotlinText.category(codePoint: cp) {
      case .decimalNumber, .letterNumber, .otherNumber: return true
      default: return false
      }
    }
    if points.count > 1 {
      for index in 1..<min(points.count, 33) {
        if points[index] != 0x3A && points[index] != 0x2022 { continue }
        guard let last = PackFuzzy.words(text(0, index)).last else { continue }
        if !nameLike(last[...], 1) { continue }
        var start = index + 1
        while start < points.count && !PackFuzzy.isLetter(points[start]) && !isNumber(points[start]) { start += 1 }
        let body = KotlinText.trim(text(start, points.count))
        if !body.unicodeScalars.contains(where: { PackFuzzy.isLetter($0.value) }) { return nil }
        return (KotlinText.trim(text(0, index + 1)) + " ", body)
      }
    }
    var position = 0
    while position < points.count && !PackFuzzy.isLetter(points[position]) { position += 1 }
    for _ in 0..<3 {
      var end = position
      while end < points.count && !PackFuzzy.isSpace(points[end]) { end += 1 }
      if end >= points.count || !KotlinText.isUpperCase(codePoint: points[position]) || !nameLike(points[position..<end], 2) {
        return nil
      }
      while end < points.count && PackFuzzy.isSpace(points[end]) { end += 1 }
      position = end
      if position + 1 < points.count && KotlinText.isUpperCase(codePoint: points[position])
        && KotlinText.isLowerCase(codePoint: points[position + 1]) {
        return (KotlinText.trim(text(0, position)) + " ", KotlinText.trim(text(position, points.count)))
      }
    }
    return nil
  }

  private static func result(_ pieces: [SubtitleSegmenter.Piece], _ translations: [String?]) -> PackMatch {
    PackMatch(text: pieces.indices.map { translations[$0] ?? pieces[$0].text }.joined())
  }
}
