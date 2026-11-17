// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Android'deki core/PackFuzzy.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Paketteki satırın bulanık imzası: OCR'ın bozduğu satırı (harf hatası, birleşmiş sözcük) bulmak için. canon metnin
/// boşlukları atılır, OCR'ın karıştırdığı harfler birleştirilir (l/1/ı/j → i, 0 → o, 5 → s), kalan dizinin her farklı
/// üçlüsü FNV-1a 64 ile özetlenip m bitten birine düşer (Bloom kümesi; m uzunlukla büyür: 64/128/256). Mac
/// (PackFuzzy.swift), Windows (PackFuzzy.cs) ve paket betiğiyle (augment.py, common.py) birebir aynı; ortak deneme verisi
/// fuzzy-vectors.json. Metinler kod noktası dizileri ([UInt32]) olarak işlenir (Kotlin'deki IntArray).
enum PackFuzzy {
  /// Bundan kısa satırda bulanık arama yok.
  static let MIN_LENGTH = 16
  /// Bloom kümesinin en büyük boyu (32 bayt).
  static let MAX_BITS = 256
  /// Üçlü başına bit.
  static let BITS_PER_GRAM = 3
  /// Türkçesi farklı en yakın ikinci aday en az bu kadar geride olmalı.
  static let MARGIN = 5.0

  /// OCR izi olmayan satır neredeyse aynı olmalı: (uzunluk sınırı, en düşük benzerlik).
  private static let cleanMinimum: [(Int, Double)] = [(24, 90.0), (256, 80.0)]
  /// OCR izi olan satır: (uzunluk sınırı, en düşük benzerlik).
  private static let damagedMinimum: [(Int, Double)] = [(24, 70.0), (40, 60.0), (256, 55.0)]

  /// Tek yönlü kapsama (yarım ya da fazlalıklı okuma); bkz. Kotlin'deki açıklama.
  enum Containment {
    static let minLength = 22
    static let inner = 90.0
    static let partial = 25.0
    static let extra = 55.0
    static let penalty = 10.0
  }

  /// Fazlalıklı okumada yan cümle denetimi ([clauseHashes]).
  enum SentenceCheck {
    static let letters = 6
    static let covered = 30.0
  }

  private static func set(_ s: String) -> Set<UInt32> { Set(s.unicodeScalars.map { $0.value }) }
  private static let CLAUSE_ENDERS = set(".!?…,;:")
  /// Ardından küçük harf gelse de bölen işaretler (yan cümle).
  private static let CLAUSE_MARKS = set(",;:")
  private static let CLAUSE_CLOSERS = set("\"'”’)]")
  private static let ELLIPSIS: UInt32 = 0x2026

  /// Satırın cümle ve yan cümleleri: . ! ? … (yinelenebilir, isteğe bağlı kapanış tırnağı ya da ayraç) ardından boşluk
  /// ve büyük harf, ya da , ; : … ve üç nokta ardından boşluk. Tek noktadan sonra küçük harfle süren yer bölünmez.
  static func clauses(_ text: String) -> [String] {
    let points = KotlinText.codePoints(text)
    var output: [String] = []
    var begin = 0
    var index = 0
    func cut(_ end: Int) {
      let clause = KotlinText.trim(KotlinText.string(codePoints: points[begin..<end]))
      if !clause.isEmpty { output.append(clause) }
    }
    while index < points.count {
      if !CLAUSE_ENDERS.contains(points[index]) { index += 1; continue }
      var end = index
      while end < points.count && CLAUSE_ENDERS.contains(points[end]) { end += 1 }
      while end < points.count && CLAUSE_CLOSERS.contains(points[end]) { end += 1 }
      var next = end
      while next < points.count && isSpace(points[next]) { next += 1 }
      // Üç nokta da küçük harfle süren yan cümleyi ayırır ("to escape... if we're able").
      var dots = 0
      var soft = false
      for position in index..<end {
        if CLAUSE_MARKS.contains(points[position]) || points[position] == ELLIPSIS { soft = true }
        if points[position] == 0x2E { dots += 1 }
      }
      if next > end && next < points.count && (soft || dots > 1 || KotlinText.isUpperCase(codePoint: points[next])) {
        cut(end)
        begin = next
      }
      index = max(next, index + 1)
    }
    cut(points.count)
    // SentenceCheck.letters harften kısa yan cümle ("Bye," "Dad.") sonrakine (sonuncuysa öncekine) eklenir.
    var merged: [String] = []
    var pending = ""
    for clause in output {
      let joined = pending.isEmpty ? clause : pending + " " + clause
      if folded(joined).count < SentenceCheck.letters { pending = joined } else { merged.append(joined); pending = "" }
    }
    if !pending.isEmpty {
      if let last = merged.last { merged[merged.count - 1] = last + " " + pending } else { merged.append(pending) }
    }
    return merged
  }

  /// Fazlalıklı okumanın denetlenecek yan cümleleri: her biri için üçlü kümesi seçenekleri. Okuma tek yan cümleyse boş.
  static func clauseHashes(_ text: String) -> [[[UInt64]]] {
    let parts = clauses(text)
    if parts.count < 2 { return [] }
    var output: [[[UInt64]]] = []
    for (position, part) in parts.enumerated() {
      if overlayLike(part) { continue }
      let tokens = words(part).map { KotlinText.string(codePoints: $0) }
      var options = [part]
      for count in 1...3 {
        if count >= tokens.count { break }
        if position == 0 && tokens.prefix(count).allSatisfy(capitalized) {
          options.append(tokens.dropFirst(count).joined(separator: " "))
        }
        if position == parts.count - 1 && tokens.suffix(count).allSatisfy(capitalized) {
          options.append(tokens.dropLast(count).joined(separator: " "))
        }
      }
      let folds = options.map(folded)
      if folds.contains(where: { $0.count < SentenceCheck.letters }) { continue }
      output.append(folds.map(trigramHashes))
    }
    return output
  }

  /// Büyük harfle başlayan, yalnız harf ve rakamlı sözcük (köşe yazısı sözcüğü: "Vinewood", "LOSNN").
  static func capitalized(_ word: String) -> Bool {
    let points = KotlinText.codePoints(word)
    return !points.isEmpty && KotlinText.isUpperCase(codePoint: points[0]) && points.allSatisfy { isLetter($0) || isDigit($0) }
  }

  /// Köşe yazısına benzeyen parça: "•" içerir ya da en çok dört sözcük, noktalama yok ve her sözcük büyük harfle başlar.
  static func overlayLike(_ text: String) -> Bool {
    if text.utf16.contains(0x2022) { return true }
    let tokens = words(text).map { KotlinText.string(codePoints: $0) }
    return !tokens.isEmpty && tokens.count <= 4 && tokens.allSatisfy(capitalized)
  }

  /// Her yan cümlenin seçeneklerinden birinin üçlülerinin en az [SentenceCheck.covered]'ı adayın Bloom'unda mı.
  /// [entry]: dizindeki kelimeler, [offset]ten başlayarak bits / 64 tane; [inEntry]: adaydaki 1 bit.
  static func coversClauses(_ clauses: [[[UInt64]]], _ entry: UnsafeBufferPointer<UInt64>, _ offset: Int, _ bits: Int,
                            _ inEntry: Int) -> Bool {
    let fill = Double(inEntry) / Double(bits)
    if fill >= 1 { return false }
    func covered(_ hashes: [UInt64]) -> Bool {
      let words = bloom(hashes, bits)
      var both = 0
      var inClause = 0
      for index in words.indices {
        both += (words[index] & entry[offset + index]).nonzeroBitCount
        inClause += words[index].nonzeroBitCount
      }
      if inClause == 0 { return true }
      return 100.0 * (Double(both) / Double(inClause) - fill) / (1 - fill) >= SentenceCheck.covered
    }
    return clauses.allSatisfy { options in options.contains(where: covered) }
  }

  static func coversClauses(_ clauses: [[[UInt64]]], _ entry: [UInt64], _ offset: Int, _ bits: Int, _ inEntry: Int) -> Bool {
    entry.withUnsafeBufferPointer { coversClauses(clauses, $0, offset, bits, inEntry) }
  }

  private static let fold: [UInt32: UInt32] = [
    0x6C: 0x69, 0x31: 0x69, 0x131: 0x69, 0x6A: 0x69, 0x30: 0x6F,
    0x35: 0x73, 0xE6: 0x61, 0xF8: 0x6F, 0x153: 0x6F, 0xDF: 0x73,
  ]

  /// Yazı tanımanın sık karıştırdığı harf dizileri (canon metinde, küçük harf): okunan → asıl olabilecek.
  static let confusions: [(String, String)] = [
    ("rn", "m"), ("m", "rn"), ("cl", "d"), ("d", "cl"), ("vv", "w"), ("ri", "n"), ("n", "ri"), ("li", "h"),
    ("l", "i"), ("i", "l"), ("1", "l"), ("1", "i"), ("0", "o"), ("5", "s"), ("j", "i"), ("c", "e"), ("e", "c"),
    ("a", "o"), ("o", "a"), ("h", "b"), ("b", "h"), ("f", "t"), ("t", "f"), ("u", "v"), ("v", "u"), ("y", "v"),
    ("v", "y"), ("q", "g"), ("g", "q"),
  ]
  private static let confusionUnits: [(UTF16Text, UTF16Text)] = confusions.map { (KotlinText.units($0.0), KotlinText.units($0.1)) }

  /// Tek düzeltmeyle denenecek en kısa ve en uzun canon satır (harf sayısı); daha uzun satırda bulanık imza yeter.
  static let VARIANT_MINIMUM = 6
  static let VARIANT_MAXIMUM = 48

  /// Satırın tek bir OCR düzeltmesiyle olabileceği canon hâller: karıştırılan harf dizisi değişir, bir harf düşer,
  /// sözcük ikiye bölünür ya da iki sözcük birleşir. Sonuç UTF-16 sırasıyla sıralı.
  static func variants(_ text: String) -> [String] {
    let canonText = PackKey.canon(text)
    let canon = KotlinText.units(canonText)
    let points = KotlinText.codePoints(canonText)
    let count = points.count
    if count < VARIANT_MINIMUM || count > VARIANT_MAXIMUM { return [] }
    // at[i]: i. harfin metindeki yeri (UTF-16), at[count] = metnin boyu.
    var at = [Int](repeating: 0, count: count + 1)
    for index in 1...count { at[index] = at[index - 1] + (points[index - 1] > 0xFFFF ? 2 : 1) }
    var output = Set<UTF16Text>()
    func add(_ cut: Int, _ middle: UTF16Text, _ resume: Int) {
      var value = UTF16Text()
      value.reserveCapacity(canon.count + 2)
      value.append(contentsOf: canon[0..<at[cut]])
      value.append(contentsOf: middle)
      value.append(contentsOf: canon[at[resume]...])
      if value.isEmpty || value.first == 0x20 || value.last == 0x20 { return }
      for i in 1..<value.count where value[i] == 0x20 && value[i - 1] == 0x20 { return }
      output.insert(value)
    }
    for index in 0..<count {
      for (read, real) in confusionUnits {
        // Karışan diziler ASCII: harf sayısı UTF-16 boyuna eşit.
        if index + read.count > count || at[index + read.count] - at[index] != read.count
          || !canon[at[index]..<(at[index] + read.count)].elementsEqual(read) { continue }
        add(index, real, index + read.count)
      }
      add(index, [], index + 1)
      if points[index] != 0x20 && index > 0 && points[index - 1] != 0x20 { add(index, [0x20], index) }
    }
    output.remove(canon)
    return output.sorted { KotlinText.compare($0, $1) < 0 }.map { KotlinText.string($0) }
  }

  /// canon metin, boşluksuz ve OCR'ın karıştırdığı harfler birleşmiş (kod noktaları).
  static func folded(_ text: String) -> [UInt32] {
    PackKey.canon(text).unicodeScalars.compactMap { scalar in
      let cp = scalar.value
      return cp == 0x20 ? nil : (fold[cp] ?? cp)
    }
  }

  /// Uzunluğa göre Bloom boyu (bit).
  static func bits(_ length: Int) -> Int {
    var bits = 64
    while bits < MAX_BITS && length * BITS_PER_GRAM > bits { bits *= 2 }
    return bits
  }

  /// Her farklı üçlünün FNV-1a 64 özeti (ilk görülme sırasıyla).
  static func trigramHashes(_ points: [UInt32]) -> [UInt64] {
    if points.count < 3 { return [] }
    var seen = Set<UInt64>()
    var hashes: [UInt64] = []
    var buffer: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)
    for index in 0...(points.count - 3) {
      var hash: UInt64 = 0xcbf29ce484222325
      for offset in 0..<3 {
        let written = utf8(points[index + offset], &buffer)
        withUnsafeBytes(of: &buffer) { bytes in
          for b in 0..<written {
            hash ^= UInt64(bytes[b])
            hash = hash &* 0x100000001b3
          }
        }
      }
      if seen.insert(hash).inserted { hashes.append(hash) }
    }
    return hashes
  }

  private static func utf8(_ cp: UInt32, _ out: inout (UInt8, UInt8, UInt8, UInt8)) -> Int {
    if cp < 0x80 {
      out.0 = UInt8(cp)
      return 1
    }
    if cp < 0x800 {
      out.0 = UInt8(0xC0 | (cp >> 6)); out.1 = UInt8(0x80 | (cp & 0x3F))
      return 2
    }
    if cp < 0x10000 {
      out.0 = UInt8(0xE0 | (cp >> 12)); out.1 = UInt8(0x80 | ((cp >> 6) & 0x3F)); out.2 = UInt8(0x80 | (cp & 0x3F))
      return 3
    }
    out.0 = UInt8(0xF0 | (cp >> 18)); out.1 = UInt8(0x80 | ((cp >> 12) & 0x3F))
    out.2 = UInt8(0x80 | ((cp >> 6) & 0x3F)); out.3 = UInt8(0x80 | (cp & 0x3F))
    return 4
  }

  static func bloom(_ hashes: [UInt64], _ bits: Int) -> [UInt64] {
    var words = [UInt64](repeating: 0, count: bits / 64)
    for hash in hashes {
      let bit = Int(hash & UInt64(bits - 1))
      words[bit >> 6] |= 1 << UInt64(bit & 63)
    }
    return words
  }

  /// İki yönlü, rastlantıdan arındırılmış kapsama (0-100). [entry]: dizindeki kelimeler, [offset]ten başlayarak.
  static func similarity(_ query: [UInt64], _ entry: [UInt64], _ offset: Int, _ bits: Int) -> Double {
    var both = 0
    var inQuery = 0
    var inEntry = 0
    for index in 0..<(bits / 64) {
      let q = query[index]
      let e = entry[offset + index]
      both += (q & e).nonzeroBitCount
      inQuery += q.nonzeroBitCount
      inEntry += e.nonzeroBitCount
    }
    return score(both, inQuery, inEntry, bits)
  }

  /// Benzerlik, bit sayılarından (ortak, sorgudaki, adaydaki).
  @inline(__always) static func score(_ both: Int, _ inQuery: Int, _ inEntry: Int, _ bits: Int) -> Double {
    if inQuery == 0 || inEntry == 0 { return 0.0 }
    let fillQuery = Double(inQuery) / Double(bits)
    let fillEntry = Double(inEntry) / Double(bits)
    if fillQuery >= 1 || fillEntry >= 1 { return 0.0 }
    return 100.0 * min(
      (Double(both) / Double(inQuery) - fillEntry) / (1 - fillEntry),
      (Double(both) / Double(inEntry) - fillQuery) / (1 - fillQuery)
    )
  }

  /// Rastlantıdan arındırılmış tek yönlü kapsamalar (0-100).
  struct Coverage {
    let query: Double
    let entry: Double
  }

  static func coverage(_ both: Int, _ inQuery: Int, _ inEntry: Int, _ bits: Int) -> Coverage {
    if inQuery == 0 || inEntry == 0 { return Coverage(query: 0, entry: 0) }
    let fillQuery = Double(inQuery) / Double(bits)
    let fillEntry = Double(inEntry) / Double(bits)
    if fillQuery >= 1 || fillEntry >= 1 { return Coverage(query: 0, entry: 0) }
    return Coverage(
      query: 100.0 * (Double(both) / Double(inQuery) - fillEntry) / (1 - fillEntry),
      entry: 100.0 * (Double(both) / Double(inEntry) - fillQuery) / (1 - fillQuery)
    )
  }

  /// (uzunluk, Bloom baytları) — paket betiğinin yazdığıyla aynı; satır çok kısaysa null.
  static func signature(_ text: String) -> (Int, [UInt8])? {
    let points = folded(text)
    if points.count < MIN_LENGTH { return nil }
    let length = min(points.count, 255)
    let words = bloom(trigramHashes(points), bits(length))
    var bytes: [UInt8] = []
    bytes.reserveCapacity(words.count * 8)
    for word in words { for shift in stride(from: 0, to: 64, by: 8) { bytes.append(UInt8(truncatingIfNeeded: word >> UInt64(shift))) } }
    return (length, bytes)
  }

  /// Kabul için en düşük benzerlik (0-100), OCR izine ve uzunluğa göre.
  static func required(_ length: Int, _ damaged: Bool) -> Double {
    let table = damaged ? damagedMinimum : cleanMinimum
    return table.first { length < $0.0 }?.1 ?? table.last!.1
  }

  private static let EDGE = set(".,!?;:'\"()[]-…“”’‘")
  private static let TYPOGRAPHIC = set("’‘“”—–…")

  static func isLetter(_ cp: UInt32) -> Bool { KotlinText.isLetter(codePoint: cp) }

  /// Ondalık rakam ya da rakam değerli işaret ("²", "①"): Character.isDigit ya da OTHER_NUMBER ve
  /// Character.getNumericValue 0..9.
  static func isDigit(_ cp: UInt32) -> Bool {
    guard let p = KotlinText.codePointProperties(cp) else { return false }
    if p.generalCategory == .decimalNumber { return true }
    guard p.generalCategory == .otherNumber, let value = p.numericValue else { return false }
    return value >= 0 && value <= 9 && value == value.rounded()
  }

  /// Boşluk karakteri (Unicode; Mac'teki isWhitespace).
  static func isSpace(_ cp: UInt32) -> Bool { KotlinText.isWhitespace(codePoint: cp) }

  /// Boşluklarla ayrılan sözcükler (kod noktası dizileri).
  static func words(_ text: String) -> [[UInt32]] {
    let points = KotlinText.codePoints(text)
    var words: [[UInt32]] = []
    var start = -1
    for index in 0...points.count {
      let space = index == points.count || isSpace(points[index])
      if space && start >= 0 {
        words.append(Array(points[start..<index]))
        start = -1
      } else if !space && start < 0 {
        start = index
      }
    }
    return words
  }

  private static let SHORT_WORDS: Set<UInt32> = [0x61, 0x41, 0x49, 0x6F, 0x4F]

  /// OCR izi: İngilizce satırda ASCII dışı harf ya da işaret, sözcük içinde harf olmayan işaret ya da rakam, tek harfli
  /// garip sözcük, çok uzun (birleşmiş) sözcük.
  static func damaged(_ text: String) -> Bool {
    if text.unicodeScalars.contains(where: { $0.value > 127 && ($0.value > 0xFFFF || !TYPOGRAPHIC.contains($0.value)) }) {
      return true
    }
    for word in words(text) {
      var from = 0
      var to = word.count
      while from < to && EDGE.contains(word[from]) { from += 1 }
      while to > from && EDGE.contains(word[to - 1]) { to -= 1 }
      let core = Array(word[from..<to])
      if core.isEmpty { continue }
      if core.count > 2 {
        for index in 1..<(core.count - 1) {
          if isLetter(core[index - 1]) && isLetter(core[index + 1]) && !isLetter(core[index])
            && core[index] != 0x27 && core[index] != 0x2019 && core[index] != 0x2D { return true }
        }
      }
      for index in 1..<max(core.count, 1) {
        let previous = core[index - 1]
        let current = core[index]
        if (isLetter(previous) && isDigit(current)) || (isDigit(previous) && isLetter(current)) { return true }
      }
      if core.count == 1 && isLetter(core[0]) && !SHORT_WORDS.contains(core[0]) { return true }
      if core.count > 14 { return true }
    }
    return false
  }
}

/// Bir paketin bulanık dizini: imzalı satırlar uzunluğa göre sıralı (aynı uzunlukta anahtar sırasıyla), Bloom kelimeleri
/// ardışık. Satır başına yalnız anahtar (8 bayt) ve Bloom kelimeleri tutulur; uzunluk ve kelime yeri uzunluk
/// kovalarından ([start], [wordStart]) çıkar.
final class PackFuzzyIndex: @unchecked Sendable {
  private let keys: [Int64]
  private let words: [UInt64]
  /// `start[n]`: uzunluğu n olan ilk satırın sırası (`start[256]` = satır sayısı).
  private let start: [Int]
  /// `wordStart[n]`: uzunluğu n olan ilk satırın ilk Bloom kelimesi.
  private let wordStart: [Int]

  private init(_ keys: [Int64], _ words: [UInt64], _ start: [Int], _ wordStart: [Int]) {
    self.keys = keys
    self.words = words
    self.start = start
    self.wordStart = wordStart
  }

  var count: Int { keys.count }

  /// Bellekte tuttuğu bayt (ölçüm için).
  var bytes: Int { keys.count * 8 + words.count * 8 + (start.count + wordStart.count) * 4 }

  /// Paketteki "fuzzy" nesnesi ([PackJson.Fuzzy]). [order]: paketteki bütün anahtarlar (entries + segments, Türkçesi
  /// boş olanlar da), işaretsiz sayı sırasıyla. Biçim tutmazsa null (paket yine de tam eşleşmeyle çalışır).
  static func decode(_ fuzzy: PackJson.Fuzzy, _ order: [Int64]) -> PackFuzzyIndex? {
    guard let mask = fuzzy.mask, let lengths = fuzzy.lengths, let blooms = fuzzy.blooms else { return nil }
    if fuzzy.version != 1.0 || fuzzy.count != Double(order.count) || mask.count != (order.count + 7) / 8 { return nil }
    let total = lengths.count
    var start = [Int](repeating: 0, count: 257)
    for length in lengths { start[Int(length) + 1] += 1 }
    for length in 1...256 { start[length] += start[length - 1] }
    var wordStart = [Int](repeating: 0, count: 257)
    for length in 1...256 {
      wordStart[length] = wordStart[length - 1] + (start[length] - start[length - 1]) * (PackFuzzy.bits(length - 1) / 64)
    }
    var expectedBytes = 0
    for length in lengths { expectedBytes += PackFuzzy.bits(Int(length)) / 8 }
    if expectedBytes != blooms.count { return nil }
    var keys = [Int64](repeating: 0, count: total)
    var words = [UInt64](repeating: 0, count: blooms.count / 8)
    var next = start
    // Dosyadaki sıra: imzalı anahtarlar sayı sırasıyla, Bloom'ları ardışık; uzunluğa göre sayarak sıralanır.
    var signed = 0
    var byteOffset = 0
    let ok: Bool = blooms.withUnsafeBufferPointer { source in
      for index in order.indices {
        if (Int(mask[index >> 3]) >> (index & 7)) & 1 == 0 { continue }
        if signed >= total { return false }
        let length = Int(lengths[signed])
        let perLine = PackFuzzy.bits(length) / 64
        let position = next[length]
        next[length] += 1
        keys[position] = order[index]
        let wordOffset = wordStart[length] + (position - start[length]) * perLine
        for word in 0..<perLine {
          var value: UInt64 = 0
          let at = byteOffset + word * 8
          for b in 0..<8 { value |= UInt64(source[at + b]) << UInt64(b * 8) }
          words[wordOffset + word] = value
        }
        byteOffset += perLine * 8
        signed += 1
      }
      return true
    }
    if !ok || signed != total { return nil }
    return PackFuzzyIndex(keys, words, start, wordStart)
  }

  private struct Candidate {
    let score: Double
    let key: Int64
  }

  /// Eşik, uzunluk ve ikinci aday şartlarını sağlayan en benzer satırın anahtarı; yoksa null. [translation]: anahtarın
  /// Türkçesi (aynı Türkçeli iki aday birbirinin rakibi sayılmaz). Önce boyu yakın adaylar (iki yönlü benzerlik); hiçbiri
  /// eşiği geçmezse boyu çok farklı adaylarda tek yönlü kapsamaya bakılır ([PackFuzzy.Containment]).
  func nearest(_ text: String, _ translation: (Int64) -> String?) -> Int64? {
    let points = PackFuzzy.folded(text)
    if points.count < PackFuzzy.MIN_LENGTH || keys.isEmpty { return nil }
    let length = min(points.count, 255)
    let need = PackFuzzy.required(length, PackFuzzy.damaged(text))
    let floor = need - PackFuzzy.MARGIN
    let hashes = PackFuzzy.trigramHashes(points)
    // Sorgunun üç boydaki Bloom'u (64, 128, 256 bit) ve bit sayıları.
    let queries = [PackFuzzy.bloom(hashes, 64), PackFuzzy.bloom(hashes, 128), PackFuzzy.bloom(hashes, 256)]
    let queryOnes = queries.map { $0.reduce(0) { $0 + $1.nonzeroBitCount } }
    typealias Contain = PackFuzzy.Containment
    var close: [Candidate] = []
    var contained: [Candidate] = []
    // Okumanın yan cümle üçlüleri (PackFuzzy.clauseHashes); ilk fazlalıklı adayda hesaplanır.
    var clauses: [[[UInt64]]]?
    var decided: (key: Int64?, ambiguous: Bool) = (nil, false)

    words.withUnsafeBufferPointer { words in
      keys.withUnsafeBufferPointer { keys in
        /// Boyu [lower]..[upper] olan adaylar: [wide] false ise iki yönlü benzerlik ([close]), true ise tek yönlü.
        func scan(_ lower: Int, _ upper: Int, wide: Bool) {
          if lower > upper { return }
          for entryLength in lower...upper {
            let first = start[entryLength]
            let end = start[entryLength + 1]
            if first == end { continue }
            let bits = PackFuzzy.bits(entryLength)
            let perLine = bits / 64
            let tier = bits == 64 ? 0 : bits == 128 ? 1 : 2
            let query = queries[tier]
            let inQuery = queryOnes[tier]
            if wide && (entryLength < Contain.minLength || entryLength == length) { continue }
            var offset = wordStart[entryLength]
            for index in first..<end {
              var both = 0
              var inEntry = 0
              for word in 0..<perLine {
                let value = words[offset + word]
                both += (query[word] & value).nonzeroBitCount
                inEntry += value.nonzeroBitCount
              }
              offset += perLine
              if !wide {
                let score = PackFuzzy.score(both, inQuery, inEntry, bits)
                if score >= floor { close.append(Candidate(score: score, key: keys[index])) }
                continue
              }
              // Kısa tarafın bitlerinin en az %90'ı ortak olmalı (hızlı eleme).
              if both * 10 < 9 * (entryLength > length ? inQuery : inEntry) { continue }
              let cover = PackFuzzy.coverage(both, inQuery, inEntry, bits)
              let longer = entryLength > length
              let inner = longer ? cover.query : cover.entry
              let outer = longer ? cover.entry : cover.query
              let least = longer ? Contain.partial : Contain.extra
              if inner < Contain.inner || outer < least || inner - Contain.penalty < floor { continue }
              // Fazlalıklı okumada her yan cümle adayda olmalı: ikinci bir altyazının cümlesi fazlalık sayılmaz.
              if !longer {
                let found = clauses ?? PackFuzzy.clauseHashes(text)
                clauses = found
                if !found.isEmpty && !PackFuzzy.coversClauses(found, words, offset - perLine, bits, inEntry) { continue }
              }
              contained.append(Candidate(score: inner - Contain.penalty, key: keys[index]))
            }
          }
        }

        // İki yönlü aday: boyu en çok ±%25 farklı (|aday - satır| * 4 <= satır).
        scan(length - length / 4, min(255, length + length / 4), wide: false)
        // Tek yönlü adaylara yalnız iki yönlü hiçbir aday eşiği geçmediyse bakılır: satırın 11/20'si ile 5/2'si arası.
        decided = pick(close, need, translation)
        if decided.key != nil || decided.ambiguous || length < Contain.minLength { return }
        scan(max(Contain.minLength, length * 11 / 20), min(255, length * 5 / 2), wide: true)
      }
    }

    if decided.key != nil || decided.ambiguous || length < Contain.minLength { return decided.key }
    if contained.isEmpty { return nil }
    return pick(close + contained, need, translation).key
  }

  /// En iyi aday; eşiği geçmiyorsa (null, false), Türkçesi farklı rakibi yakınsa (null, true).
  private func pick(_ found: [Candidate], _ need: Double, _ translation: (Int64) -> String?) -> (key: Int64?, ambiguous: Bool) {
    var best: Candidate?
    for candidate in found {
      if let current = best {
        if candidate.score > current.score
          || (candidate.score == current.score && UInt64(bitPattern: candidate.key) > UInt64(bitPattern: current.key)) {
          best = candidate
        }
      } else {
        best = candidate
      }
    }
    guard let chosen = best, chosen.score >= need else { return (nil, false) }
    let turkish = translation(chosen.key)
    for other in found where other.key != chosen.key && other.score > chosen.score - PackFuzzy.MARGIN {
      if !KotlinText.same(translation(other.key), turkish) { return (nil, true) }
    }
    return (chosen.key, false)
  }
}
