// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Android'deki core/GamePacks.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Compression
import CryptoKit
import Foundation

/// Oyun paketinin anahtarı: ekranda okunan İngilizce satırın sadeleştirilmiş hâlinin SHA-256'sının ilk 8 baytı (hex).
/// Mac (GamePacks.swift), Windows (GamePacks.cs) ve paket hazırlayan Python betiğiyle (canon.py) birebir aynı adımlar;
/// ortak deneme verisi golden-vectors.json.
enum PackKey {
  /// Biçim etiketi: en çok 40 karakterlik `<…>` ("<b>", "</>").
  static let MAX_TAG_LENGTH = 40

  /// 1. etiketler boşluk olur, 2. NFKC, 3. küçük harf, 4. NFD ile aksan ve işaretler atılır,
  /// 5. harf ve rakam dışındaki her şey boşluk olur, 6. boşluklar teklenir, baş ve son kırpılır.
  static func canon(_ text: String) -> String {
    // Locale.ROOT küçük harfi Python'un str.lower()'ı gibi tam eşlemedir: "İ" → "i" + üst nokta (nokta 4. adımda atılır).
    let lowered = KotlinText.lowercaseRoot(stripTags(text).precomposedStringWithCompatibilityMapping)
    let decomposed = lowered.decomposedStringWithCanonicalMapping
    var output = String.UnicodeScalarView()
    var gap = false
    for scalar in decomposed.unicodeScalars {
      switch scalar.properties.generalCategory {
      case .nonspacingMark, .spacingMark, .enclosingMark:
        continue
      case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
           .decimalNumber, .letterNumber, .otherNumber:
        if gap && !output.isEmpty { output.append(" ") }
        gap = false
        output.append(scalar)
      default:
        gap = true
      }
    }
    return String(output)
  }

  /// 16 haneli küçük harf hex anahtar; satırda harf ya da rakam yoksa null.
  static func key(_ text: String) -> String? {
    let canon = canon(text)
    if canon.isEmpty { return nil }
    return SHA256.hash(data: Array(canon.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
  }

  /// Anahtarın sayı hâli doğrudan (hex dizesi kurulmadan; `number(key(text))` ile aynı); harf ya da rakam yoksa null.
  static func keyNumber(_ text: String) -> Int64? { canonNumber(canon(text)) }

  /// Zaten canon olan metnin anahtar sayısı; boşsa null.
  static func canonNumber(_ canon: String) -> Int64? {
    if canon.isEmpty { return nil }
    var value: UInt64 = 0
    for byte in SHA256.hash(data: Array(canon.utf8)).prefix(8) { value = value << 8 | UInt64(byte) }
    return Int64(bitPattern: value)
  }

  /// Anahtarın sayı hâli (sözlükte daha az yer tutar); geçersizse null.
  static func number(_ key: String) -> Int64? {
    let units = key.utf16
    if units.count != 16 { return nil }
    var value: UInt64 = 0
    for unit in units {
      let digit: UInt16
      switch unit {
      case 0x30...0x39: digit = unit - 0x30
      case 0x61...0x66: digit = unit - 0x61 + 10
      case 0x41...0x46: digit = unit - 0x41 + 10
      default: return nil
      }
      value = value << 4 | UInt64(digit)
    }
    return Int64(bitPattern: value)
  }

  /// `<…>` etiketlerini (en çok 40 karakter, içinde < ya da > yok) [replacement] ile değiştirir. Python'daki
  /// `re.sub(r"<[^<>]{0,40}>", " ", s)` ile aynı: kod noktası sayılır.
  static func stripTags(_ text: String, _ replacement: String = " ") -> String {
    if !text.utf16.contains(0x3C) { return text }
    let points = Array(text.unicodeScalars)
    var output = String.UnicodeScalarView()
    let lt: Unicode.Scalar = "<"
    let gt: Unicode.Scalar = ">"
    var index = 0
    while index < points.count {
      if points[index] == lt {
        var end = index + 1
        while end < points.count && end - index - 1 <= MAX_TAG_LENGTH && points[end] != lt && points[end] != gt { end += 1 }
        if end < points.count && points[end] == gt && end - index - 1 <= MAX_TAG_LENGTH {
          output.append(contentsOf: replacement.unicodeScalars)
          index = end + 1
          continue
        }
      }
      output.append(points[index])
      index += 1
    }
    return String(output)
  }
}

/// Dosya paket değil ya da bozuk (Kotlin'deki InvalidPackException: IOException).
struct InvalidPackException: Error, CustomStringConvertible {
  let message: String
  init(_ message: String) { self.message = message }
  var description: String { "InvalidPackException: \(message)" }
}

/// Bir oyunun çeviri paketi. Dosya gzip'li JSON'dur: `{"format":1|2,"id":…,"title":…,"entries":{anahtar: Türkçe}}`;
/// yalnız `{anahtar: Türkçe}` nesnesi de kabul edilir (adı dosya adından gelir). Biçim 2 ayrıca `segments` taşır (oyunun
/// ayrı gösterdiği parçalar ve çok cümleli satırların cümleleri; aynı düzen) ve `fuzzy` (OCR'ın bozduğu satırı bulmak
/// için imzalar, bkz. [PackFuzzy]) taşır.
///
/// Telefonda bellek sınırlıdır: satırlar sıralı anahtar dizisi ve tek bir UTF-8 bayt bloğunda tutulur, ikili aramayla
/// bulunur. Dosya da akış hâlinde okunur ([PackJson]); bütün JSON bir nesne ağacına dönüştürülmez.
final class GamePack: @unchecked Sendable {
  let id: String
  let title: String
  private let entries: Table
  private let segments: Table
  /// Bulanık imzalar (biçim 2); yoksa ya da bozuksa null.
  let fuzzy: PackFuzzyIndex?

  private init(_ id: String, _ title: String, _ entries: Table, _ segments: Table, _ fuzzy: PackFuzzyIndex?) {
    self.id = id
    self.title = title
    self.entries = entries
    self.segments = segments
    self.fuzzy = fuzzy
  }

  /// Sıralı anahtarlar ve UTF-8 metin bloğu.
  final class Table: Sendable {
    private let keys: [Int64]
    private let offsets: [Int32]
    private let blob: [UInt8]

    init(_ keys: [Int64], _ offsets: [Int32], _ blob: [UInt8]) {
      self.keys = keys
      self.offsets = offsets
      self.blob = blob
    }

    var size: Int { keys.count }

    /// Bellekte tuttuğu bayt (ölçüm için).
    var bytes: Int { keys.count * 8 + offsets.count * 4 + blob.count }

    /// java.util.Arrays.binarySearch (işaretli sıra); yoksa -1.
    private func find(_ key: Int64) -> Int {
      var low = 0
      var high = keys.count - 1
      while low <= high {
        let mid = (low + high) >> 1
        let value = keys[mid]
        if value < key { low = mid + 1 } else if value > key { high = mid - 1 } else { return mid }
      }
      return -1
    }

    subscript(key: Int64) -> String? {
      let index = find(key)
      if index < 0 { return nil }
      return String(decoding: blob[Int(offsets[index])..<Int(offsets[index + 1])], as: UTF8.self)
    }

    func contains(_ key: Int64) -> Bool { find(key) >= 0 }

    static let EMPTY = Table([], [0], [])
  }

  /// Satırları geldiği sırayla düz dizilere yazar, sonunda anahtara göre sıralı [Table] kurar.
  final class TableBuilder {
    private var keys: [Int64] = []
    private var ends: [Int32] = []
    private var blob: [UInt8] = []

    init() {
      keys.reserveCapacity(1024)
      ends.reserveCapacity(1024)
      blob.reserveCapacity(1 << 16)
    }

    var isEmpty: Bool { keys.isEmpty }

    func add(_ key: Int64, _ text: String) {
      blob.append(contentsOf: text.utf8)
      keys.append(key)
      ends.append(Int32(blob.count))
    }

    func build() -> Table {
      let count = keys.count
      if count == 0 { return Table.EMPTY }
      // Kararlı sıralama: aynı anahtarın kayıtları geliş sırasıyla yan yana kalır, sonuncusu alınır.
      var order = Array(0..<Int32(count))
      keys.withUnsafeBufferPointer { k in
        order.sort { a, b in
          let x = k[Int(a)], y = k[Int(b)]
          return x != y ? x < y : a < b
        }
      }
      var unique = 0
      var total = 0
      for position in 0..<count {
        let index = Int(order[position])
        if position + 1 < count && keys[Int(order[position + 1])] == keys[index] { continue }
        unique += 1
        total += Int(ends[index]) - start(index)
      }
      var sortedKeys = [Int64]()
      sortedKeys.reserveCapacity(unique)
      var offsets = [Int32]()
      offsets.reserveCapacity(unique + 1)
      var text = [UInt8]()
      text.reserveCapacity(total)
      for position in 0..<count {
        let index = Int(order[position])
        if position + 1 < count && keys[Int(order[position + 1])] == keys[index] { continue }
        let from = start(index)
        offsets.append(Int32(text.count))
        text.append(contentsOf: blob[from..<Int(ends[index])])
        sortedKeys.append(keys[index])
      }
      offsets.append(Int32(text.count))
      return Table(sortedKeys, offsets, text)
    }

    private func start(_ index: Int) -> Int { index == 0 ? 0 : Int(ends[index - 1]) }
  }

  /// Tam satır sayısı (parçalar hariç).
  var size: Int { entries.size }

  /// Bellekte tuttuğu bayt: satırlar, parçalar ve bulanık dizin (ölçüm için).
  var bytes: Int { entries.bytes + segments.bytes + (fuzzy?.bytes ?? 0) }

  /// Anahtarın (sayı hâli) tam satır Türkçesi.
  subscript(key: Int64) -> String? { entries[key] }

  /// Anahtarın parça ("segments") Türkçesi.
  func segment(_ key: Int64) -> String? { segments[key] }

  /// Anahtar pakette (tam satır ya da parça) var mı.
  func contains(_ key: Int64) -> Bool { entries.contains(key) || segments.contains(key) }

  /// [name]: dosya adı uzantısız ("mafia-the-old-country"); düz biçimde kimlik ve başlık olur.
  /// [data] gzip'li ya da açılmış JSON olabilir (ilk iki bayt 1f 8b ise açılır).
  static func decode(_ data: Data, _ name: String) throws -> GamePack {
    let isGzip = data.count >= 2 && data[data.startIndex] == 0x1f && data[data.startIndex + 1] == 0x8b
    if isGzip {
      let json = try Gzip.decompress(data)
      return try json.withUnsafeBufferPointer { try decode(json: $0, name) }
    }
    return try data.withUnsafeBytes { raw in
      try decode(json: raw.bindMemory(to: UInt8.self), name)
    }
  }

  static func decode(_ data: [UInt8], _ name: String) throws -> GamePack { try decode(Data(data), name) }

  private static func decode(json raw: UnsafeBufferPointer<UInt8>, _ name: String) throws -> GamePack {
    // Windows'ta kaydedilen yamaların başında UTF-8 BOM (EF BB BF) olabiliyor (ör. final-fantasy-vii-rebirth.json);
    // bilgisayar sürümü bunu yok sayıyor. Yalnız iOS'ta: Kotlin'deki karşılığı BOM'lu dosyayı reddeder.
    let hasBom = raw.count >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF
    let json = hasBom ? UnsafeBufferPointer(rebasing: raw[3...]) : raw
    let entries = TableBuilder()
    let segments = TableBuilder()
    // İmzaların sırası: dosyadaki bütün geçerli anahtarlar (Türkçesi boş kalanlar da); imzalar yoksa atılır.
    var order: [Int64] = []
    order.reserveCapacity(1024)
    func add(_ target: TableBuilder, _ key: String, _ value: String) {
      // Kotlin: PackKey.number(key.lowercase(Locale.ROOT)); küçük harfe çevirme hex rakamlarına yeni eşleşme katmaz.
      guard let number = PackKey.number(key) else { return }
      order.append(number)
      let text = cleaned(value)
      // Aynı anahtar iki kez varsa sonraki kazanır (TableBuilder.build).
      if !text.isEmpty { target.add(number, text) }
    }
    let parsed = try PackJson.parse(json, { add(entries, $0, $1) }, { add(segments, $0, $1) })
    if !parsed.wrapped {
      // Düz biçim: anahtarlar paket anahtarı (onaltılık) ya da doğrudan İngilizce satırdır (topluluk yamaları,
      // ör. patches/final-fantasy-vii-rebirth.json: {"Press any button to continue": "Devam etmek için..."}).
      // İngilizce anahtar burada paket anahtarına çevrilir. Yalnız iOS'ta: Kotlin yalnız onaltılık anahtarı okur.
      // İngilizce anahtarlı satırlar ancak en az 10 tane varsa alınır: rastgele bir JSON nesnesi paket sayılmasın.
      var english: [(Int64, String)] = []
      for (key, value) in parsed.rootStrings {
        if PackKey.number(key) != nil {
          add(entries, key, value)
        } else if let number = PackKey.keyNumber(key) {
          english.append((number, value))
        }
      }
      if english.count >= 10 {
        for (number, value) in english {
          let text = cleaned(value)
          if !text.isEmpty { entries.add(number, text) }
        }
      }
      return try build(name, english.count >= 10 ? title(fromFileName: name) : name, entries, TableBuilder())
    }
    if let format = parsed.format, format != 1.0 && format != 2.0 { throw InvalidPackException("Desteklenmeyen paket biçimi") }
    let id = parsed.id.flatMap { $0.isEmpty ? nil : $0 } ?? name
    if entries.isEmpty { throw InvalidPackException("Pakette satır yok") }
    let fuzzy = parsed.fuzzy.flatMap { PackFuzzyIndex.decode($0, unsignedUnique(order)) }
    let title = parsed.title.flatMap { $0.isEmpty ? nil : $0 } ?? id
    return GamePack(id, title, entries.build(), segments.build(), fuzzy)
  }

  /// Dosya adından okunur başlık: "final-fantasy-vii-rebirth" → "Final Fantasy VII Rebirth".
  static func title(fromFileName name: String) -> String {
    let roman: Set<String> = ["ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi"]
    return name.split(whereSeparator: { $0 == "-" || $0 == "_" }).map { word -> String in
      let w = String(word)
      if roman.contains(w.lowercased()) { return w.uppercased() }
      return w.prefix(1).uppercased() + w.dropFirst()
    }.joined(separator: " ")
  }

  private static func build(_ id: String, _ title: String, _ entries: TableBuilder, _ segments: TableBuilder) throws -> GamePack {
    if entries.isEmpty { throw InvalidPackException("Pakette satır yok") }
    return GamePack(id, title, entries.build(), segments.build(), nil)
  }

  /// Anahtarlar işaretsiz sayı sırasıyla, tekrarsız (paket betiği anahtarları UInt64 olarak sıralar).
  private static func unsignedUnique(_ keys: [Int64]) -> [Int64] {
    var sorted = keys.map { UInt64(bitPattern: $0) }
    sorted.sort()
    var unique = 0
    for index in sorted.indices {
      if unique > 0 && sorted[unique - 1] == sorted[index] { continue }
      sorted[unique] = sorted[index]
      unique += 1
    }
    return sorted[0..<unique].map { Int64(bitPattern: $0) }
  }

  /// Paketteki Türkçede de oyunun biçim etiketleri kalmış olabilir ("<b><h>…</>"); TV'de görünmesinler.
  static func cleaned(_ text: String) -> String {
    if !text.utf16.contains(0x3C) { return trimmed(text) }
    let parts = KotlinText.split(KotlinText.units(PackKey.stripTags(text, "")), 0x20).filter { !$0.isEmpty }
    return KotlinText.trim(KotlinText.string(KotlinText.join(parts, [0x20])))
  }

  /// Kotlin `trim()`; baş ve son ASCII görünür karakterse dize kopyalanmaz (paket açılırken satır başına çağrılır).
  private static func trimmed(_ text: String) -> String {
    let utf8 = text.utf8
    guard let first = utf8.first, let last = utf8.last else { return text }
    if first > 0x20 && first < 0x80 && last > 0x20 && last < 0x80 { return text }
    return KotlinText.trim(text)
  }
}

/// Oyun paketinden bulunan satır ve hangi paketten geldiği; tanımı SubtitlePipeline.swift'te (`PackMatch`).

/// Uygulamayla gelen ve kullanıcının klasörüne bırakılan paketler (Windows: GamePackLibrary). Sıra: uygulamanınkiler,
/// sonra kullanıcınınkiler (dosya adına göre); aynı anahtarda sonraki kazanır, aynı kimlikli pakette kullanıcının dosyası
/// uygulamanınkinin yerine geçer. Ayarlarda kapatılan paketlere bakılmaz.
///
/// Her paket ayrı tutulur ve sondan başa aranır, böylece satırın hangi oyunun paketinden geldiği bilinir.
/// İlk aramada (ya da [warmUp]'ta) yüklenir; yükleme saniyeler sürebilir, ana iş parçacığından çağrılmamalıdır.
final class GamePackLibrary: @unchecked Sendable {
  /// Uygulamayla gelen bir paket: dosya adı ("gta-v.json.gz" ya da "gta-v.json") ve baytlarını okuyan kapanış.
  /// Dosyalar sırayla, biri çözülüp bırakıldıktan sonra okunur (hepsi birden belleğe alınmaz).
  typealias Bundled = (name: String, read: () throws -> Data)

  struct Info: Equatable, Sendable {
    let id: String
    let title: String
    let entries: Int
    let builtIn: Bool
  }

  private let bundled: (() -> [Bundled])?
  private let userDirectory: URL?
  /// Ek klasörler (ör. GitLab'den inen topluluk yamaları); sırayla, userDirectory'den sonra okunur, aynı kimlikli
  /// paketin yerine geçer. Bilgisayar sürümündeki extraDirectories karşılığı.
  private let extraDirectories: [URL]

  private let lock = NSRecursiveLock()
  private var loaded = false
  private var packs: [(pack: GamePack, builtIn: Bool)] = []
  /// [packs] her yüklemede yenilenir; Kotlin'deki liste kimliği (`packs !== current`) karşılığı.
  private var generation = 0
  private let disabledLock = NSLock()
  private var _disabled: Set<String> = []
  /// Son tam eşleşmenin geldiği paket ([packs] sırası): bulanık arama yalnız orada yapılır (oynanan oyun).
  private var scope: Int?

  /// [bundled]: uygulamayla gelen paketlerin adları ve okuyucuları (iOS: uygulama paketindeki dosyalar);
  /// [userDirectory]: indirilen paketlerin klasörü (PackStore.folder).
  init(bundled: (() -> [Bundled])?, userDirectory: URL?, extraDirectories: [URL] = []) {
    self.bundled = bundled
    self.userDirectory = userDirectory
    self.extraDirectories = extraDirectories
  }

  /// Uygulama paketindeki bir klasörün (ör. `Bundle.main.url(forResource: "packs", withExtension: nil)`) dosyaları.
  /// Okuma bellek eşlemesiyle yapılır (`.alwaysMapped`): sıkıştırılmış dosya ayrıca belleğe kopyalanmaz.
  static func files(in directory: URL) -> [Bundled] {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
    return names.map { name in
      let url = directory.appendingPathComponent(name)
      return (name: name, read: { try Data(contentsOf: url, options: .alwaysMapped) })
    }
  }

  /// Elle seçilen oyun (bilgisayar sürümündeki "Oyun" seçimi): verildiyse yalnız o paket kullanılır ve bulanık arama ilk
  /// satırdan itibaren onda yapılır. Yalnız iOS'ta (henüz); Kotlin'de karşılığı yok.
  private var _pinned: String?

  private var disabled: Set<String> {
    disabledLock.lock()
    defer { disabledLock.unlock() }
    return _disabled
  }

  private var pinned: String? {
    disabledLock.lock()
    defer { disabledLock.unlock() }
    return _pinned
  }

  /// Oyunu elle seçer; nil: otomatik (oynanan oyun tam eşleşmelerden bulunur).
  func setPinned(_ id: String?) {
    disabledLock.lock()
    _pinned = id
    disabledLock.unlock()
  }

  var infos: [Info] {
    lock.lock()
    defer { lock.unlock() }
    loadIfNeeded()
    return packs.map { Info(id: $0.pack.id, title: $0.pack.title, entries: $0.pack.size, builtIn: $0.builtIn) }
  }

  /// Kapatılan paket kimlikleri (ayarlardan).
  func setDisabled(_ ids: Set<String>) {
    disabledLock.lock()
    _disabled = ids
    disabledLock.unlock()
  }

  func reload() {
    lock.lock()
    defer { lock.unlock() }
    loaded = false
    // Eski paketler yenileri açılmadan bırakılır: ikisi birden bellekte tutulmasın.
    packs = []
    generation += 1
    loadIfNeeded()
  }

  /// Yüklemeyi şimdi yapar (açılışta arka planda; ilk altyazı beklemesin).
  func warmUp() { _ = infos }

  private func snapshot() -> (packs: [(pack: GamePack, builtIn: Bool)], generation: Int, scope: Int?) {
    lock.lock()
    defer { lock.unlock() }
    loadIfNeeded()
    return (packs, generation, pinnedIndex() ?? scope)
  }

  /// Kilit altında: elle seçilen oyunun [packs] sırası; seçim yoksa ya da paket yoksa nil.
  private func pinnedIndex() -> Int? {
    guard let id = pinned else { return nil }
    return packs.firstIndex { $0.pack.id == id }
  }

  /// Satırın tamamı için paketteki Türkçe ve paketin kimliği (parçalara bölme yok; bkz. [PackLookup]).
  func findWithPack(_ text: String) -> PackMatch? {
    let (current, generation, _) = snapshot()
    if current.isEmpty { return nil }
    guard let number = PackKey.keyNumber(text) else { return nil }
    guard let found = lookup(current, number) else { return nil }
    noteHit(current, generation, number)
    return found
  }

  /// Tam anahtar yoksa oynanan oyunun (son tam eşleşmenin paketi) paketinde en yakın satırın Türkçesi: önce tek OCR
  /// düzeltmesiyle ([PackFuzzy.variants]) tam anahtar, sonra bulanık imza. Hiç tam eşleşme olmadıysa null.
  func nearestWithPack(_ text: String) -> PackMatch? {
    let (current, _, chosen) = snapshot()
    guard let chosen = chosen, chosen >= 0, chosen < current.count else { return nil }
    let pack = current[chosen].pack
    if disabled.contains(pack.id) { return nil }
    if let found = corrected(text, pack, current) { return found }
    guard let key = pack.fuzzy?.nearest(text, { self.lookup(current, $0)?.text }) else { return nil }
    return lookup(current, key)
  }

  /// Bulanık aramanın yapılacağı paketin kimliği (son tam eşleşmenin paketi); yoksa null.
  var searchScope: String? {
    lock.lock()
    defer { lock.unlock() }
    guard let scope = pinnedIndex() ?? scope, scope < packs.count else { return nil }
    return packs[scope].pack.id
  }

  /// Oynanan oyunun adı: son tam eşleşmenin geldiği paketin başlığı; yoksa null.
  var scopeTitle: String? {
    lock.lock()
    defer { lock.unlock() }
    guard let scope = pinnedIndex() ?? scope, scope < packs.count else { return nil }
    return packs[scope].pack.title
  }

  /// Tek OCR düzeltmesiyle [pack]'te tam bulunan satırın Türkçesi; düzeltmelerin hepsi aynı Türkçeye çıkmıyorsa null.
  private func corrected(_ text: String, _ pack: GamePack, _ current: [(pack: GamePack, builtIn: Bool)]) -> PackMatch? {
    var found: PackMatch?
    for variant in PackFuzzy.variants(text) {
      // ASCII canon metin yeniden sadeleştirilince değişmez; normalleştirmeye gitmeden özetlenir.
      let ascii = variant.utf16.allSatisfy { $0 < 128 }
      guard let number = ascii ? PackKey.canonNumber(variant) : PackKey.keyNumber(variant) else { continue }
      if !pack.contains(number) { continue }
      guard let turkish = lookup(current, number) else { continue }
      if let previous = found, !KotlinText.same(previous.text, turkish.text) { return nil }
      found = turkish
    }
    return found
  }

  private func noteHit(_ current: [(pack: GamePack, builtIn: Bool)], _ generation: Int, _ number: Int64) {
    let off = disabled
    let owners = current.indices.filter { !off.contains(current[$0].pack.id) && current[$0].pack.contains(number) }
    guard let first = owners.first else { return }
    lock.lock()
    defer { lock.unlock() }
    if self.generation != generation { return }
    if owners.count == 1 || !(scope.map { owners.contains($0) } ?? false) { scope = first }
  }

  /// Anahtarın Türkçesi: açık paketlerde sondan başa tam satır, yoksa parça (masaüstünün birleşik sözlüğüyle aynı).
  private func lookup(_ current: [(pack: GamePack, builtIn: Bool)], _ number: Int64) -> PackMatch? {
    var off = disabled
    // Oyun elle seçildiyse diğer oyunların satırları kullanılmaz (seçilen paket hâlâ varsa).
    if let id = pinned, current.contains(where: { $0.pack.id == id }) {
      off.formUnion(current.map(\.pack.id).filter { $0 != id })
    }
    for entry in current.reversed() where !off.contains(entry.pack.id) {
      if let text = entry.pack[number] { return PackMatch(text: text, packId: entry.pack.id) }
    }
    // Tam satır yoksa parçalar: bir oyunun tam satırı başka oyunun parçasına yenilmez (masaüstüyle aynı öncelik).
    for entry in current.reversed() where !off.contains(entry.pack.id) {
      if let text = entry.pack.segment(number) { return PackMatch(text: text, packId: entry.pack.id) }
    }
    return nil
  }

  func find(_ text: String) -> String? { findWithPack(text)?.text }

  /// Kilit altında çağrılır.
  private func loadIfNeeded() {
    if loaded { return }
    loaded = true
    var list: [(pack: GamePack, builtIn: Bool)] = []
    func add(_ fileName: String, _ data: Data, _ builtIn: Bool) {
      guard let pack = try? GamePack.decode(data, GamePackLibrary.baseName(fileName)) else { return }
      list.removeAll { $0.pack.id == pack.id }
      list.append((pack, builtIn))
    }
    if let bundled = bundled {
      // sortedBy { it.first }: kararlı, UTF-16 sırası.
      let sorted = bundled().enumerated().sorted { a, b in
        let order = KotlinText.compare(KotlinText.units(a.element.name), KotlinText.units(b.element.name))
        return order != 0 ? order < 0 : a.offset < b.offset
      }
      for (_, item) in sorted {
        if !GamePackLibrary.isPackFile(item.name) { continue }
        // Her dosya ayrı bir autoreleasepool'da: çözülen paketin geçici baytları sonrakinden önce bırakılır.
        autoreleasepool {
          guard let data = try? item.read() else { return }
          add(item.name, data, true)
        }
      }
    }
    for directory in [userDirectory].compactMap({ $0 }) + extraDirectories {
      let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
      let files = names.filter { name in
        var isDirectory: ObjCBool = false
        let path = directory.appendingPathComponent(name).path
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && !isDirectory.boolValue
          && GamePackLibrary.isPackFile(name)
      }.sorted { KotlinText.compare(KotlinText.units($0), KotlinText.units($1)) < 0 }
      for name in files {
        autoreleasepool {
          guard let data = try? Data(contentsOf: directory.appendingPathComponent(name)) else { return }
          add(name, data, false)
        }
      }
    }
    packs = list
    generation += 1
    scope = nil
  }

  static func isPackFile(_ name: String) -> Bool { name.hasSuffix(".json.gz") || name.hasSuffix(".json") }

  /// "mafia.json.gz" → "mafia"
  static func baseName(_ fileName: String) -> String {
    var name = fileName.split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? fileName
    for suffix in [".gz", ".json"] where name.hasSuffix(suffix) { name = String(name.dropLast(suffix.count)) }
    return name
  }
}

/// gzip (RFC 1952) çözücü: java.util.zip.GZIPInputStream'in davranışı. Başlık (FEXTRA, FNAME, FCOMMENT, FHCRC) burada
/// okunur, DEFLATE akışı Compression çerçevesiyle (COMPRESSION_ZLIB: ham DEFLATE) açılır, sonra CRC32 ve ISIZE denetlenir.
/// Ardışık gzip üyeleri birleştirilir; son üyeden sonra gelen gzip olmayan baytlar yok sayılır (Java'daki gibi).
enum Gzip {
  static func decompress(_ data: Data) throws -> [UInt8] {
    try data.withUnsafeBytes { raw in try decompress(raw.bindMemory(to: UInt8.self)) }
  }

  static func decompress(_ input: UnsafeBufferPointer<UInt8>) throws -> [UInt8] {
    let size = input.count
    // Açılmış boyut son 4 baytta yazar (ISIZE); dizi bir kerede o boyutta ayrılır (tek üyeli pakette tam boy).
    var output = [UInt8]()
    if size >= 18 {
      let hint = Int(input[size - 4]) | Int(input[size - 3]) << 8 | Int(input[size - 2]) << 16 | Int(input[size - 1]) << 24
      if hint <= 256 << 20 { output.reserveCapacity(hint) }
    }
    var position = 0
    var first = true
    while true {
      let headerEnd: Int
      do {
        headerEnd = try header(input, position)
      } catch {
        // Sonraki üye gzip değilse (dosya sonundaki fazlalık) Java okumayı orada bitirir.
        if first { throw error }
        break
      }
      first = false
      let memberStart = output.count
      try inflate(input, from: headerEnd, into: &output)
      let produced = output.count - memberStart
      let crc = output.withUnsafeBufferPointer { CRC32.checksum(UnsafeBufferPointer(rebasing: $0[memberStart...])) }
      // Compression akışın nerede bittiğini bildirmez: üyenin sonu, açılan veriyle tutan ilk CRC32 + ISIZE'dır.
      guard let trailer = findTrailer(input, after: headerEnd, crc: crc, size: UInt32(truncatingIfNeeded: produced)) else {
        throw InvalidPackException("Paket açılamadı")
      }
      position = trailer + 8
      // GZIPInputStream yeni üyeye ancak 18 bayttan fazla veri kaldıysa bakar.
      if size - position <= 18 { break }
    }
    return output
  }

  /// Üye başlığını okur; DEFLATE verisinin başladığı yer.
  private static func header(_ input: UnsafeBufferPointer<UInt8>, _ start: Int) throws -> Int {
    var at = start
    var crc = CRC32()
    func byte() throws -> UInt8 {
      guard at < input.count else { throw InvalidPackException("Paket açılamadı") }
      let value = input[at]
      crc.update(value)
      at += 1
      return value
    }
    func ushort() throws -> Int { let low = Int(try byte()); return low | Int(try byte()) << 8 }
    if try byte() != 0x1f || byte() != 0x8b { throw InvalidPackException("Paket açılamadı") }
    if try byte() != 8 { throw InvalidPackException("Paket açılamadı") }
    let flags = try byte()
    for _ in 0..<6 { _ = try byte() }
    if flags & 4 != 0 { for _ in 0..<(try ushort()) { _ = try byte() } }
    if flags & 8 != 0 { while try byte() != 0 {} }
    if flags & 16 != 0 { while try byte() != 0 {} }
    if flags & 2 != 0 {
      let expected = Int(crc.value & 0xffff)
      let low = Int(try byte())
      let stored = low | Int(try byte()) << 8
      if stored != expected { throw InvalidPackException("Paket açılamadı") }
    }
    return at
  }

  /// [from]'dan başlayan DEFLATE akışını sonuna kadar açar; akış bitmeden veri biterse ya da bozuksa hata.
  private static func inflate(_ input: UnsafeBufferPointer<UInt8>, from: Int, into output: inout [UInt8]) throws {
    guard from < input.count, let base = input.baseAddress else { throw InvalidPackException("Paket açılamadı") }
    let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
    defer { streamPointer.deallocate() }
    guard compression_stream_init(streamPointer, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else {
      throw InvalidPackException("Paket açılamadı")
    }
    defer { compression_stream_destroy(streamPointer) }
    let chunk = 1 << 16
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunk)
    defer { buffer.deallocate() }
    streamPointer.pointee.src_ptr = base + from
    streamPointer.pointee.src_size = input.count - from
    while true {
      streamPointer.pointee.dst_ptr = buffer
      streamPointer.pointee.dst_size = chunk
      let sourceBefore = streamPointer.pointee.src_size
      let status = compression_stream_process(streamPointer, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
      let written = chunk - streamPointer.pointee.dst_size
      if written > 0 { output.append(contentsOf: UnsafeBufferPointer(start: buffer, count: written)) }
      switch status {
      case COMPRESSION_STATUS_END:
        return
      case COMPRESSION_STATUS_OK:
        // İlerleme yoksa girdi bitti ama akış bitmedi ("Unexpected end of ZLIB input stream").
        if written == 0 && streamPointer.pointee.src_size == sourceBefore { throw InvalidPackException("Paket açılamadı") }
      default:
        throw InvalidPackException("Paket açılamadı")
      }
    }
  }

  /// [after]'dan sonra CRC32 ve ISIZE'ı (küçük endian) tutan ilk 8 bayt (DEFLATE verisinin içinde rastlantıyla 64 bitin
  /// tutması yok sayılabilir).
  private static func findTrailer(_ input: UnsafeBufferPointer<UInt8>, after: Int, crc: UInt32, size: UInt32) -> Int? {
    let first = UInt8(crc & 0xff)
    var at = after
    while at + 8 <= input.count {
      if input[at] == first {
        let storedCrc = UInt32(input[at]) | UInt32(input[at + 1]) << 8 | UInt32(input[at + 2]) << 16 | UInt32(input[at + 3]) << 24
        let storedSize = UInt32(input[at + 4]) | UInt32(input[at + 5]) << 8 | UInt32(input[at + 6]) << 16
          | UInt32(input[at + 7]) << 24
        if storedCrc == crc && storedSize == size { return at }
      }
      at += 1
    }
    return nil
  }
}

/// CRC-32 (IEEE 802.3, gzip'in kullandığı), dilimleme-8 tablosuyla.
struct CRC32 {
  private(set) var value: UInt32 = 0
  private var state: UInt32 = 0xffffffff

  /// 8 tablo arka arkaya (tablo k, k. bayttan sonraki kalan için).
  private static let table: [UInt32] = {
    var t = [UInt32](repeating: 0, count: 8 * 256)
    for n in 0..<256 {
      var c = UInt32(n)
      for _ in 0..<8 { c = c & 1 != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1 }
      t[n] = c
    }
    for n in 0..<256 {
      var c = t[n]
      for k in 1..<8 {
        c = t[Int(c & 0xff)] ^ (c >> 8)
        t[k * 256 + n] = c
      }
    }
    return t
  }()

  mutating func update(_ byte: UInt8) {
    state = CRC32.table[Int((state ^ UInt32(byte)) & 0xff)] ^ (state >> 8)
    value = ~state
  }

  static func checksum(_ data: UnsafeBufferPointer<UInt8>) -> UInt32 {
    var crc: UInt32 = 0xffffffff
    table.withUnsafeBufferPointer { t in
      var i = 0
      let n = data.count
      while i + 8 <= n {
        let one = crc ^ (UInt32(data[i]) | UInt32(data[i + 1]) << 8 | UInt32(data[i + 2]) << 16 | UInt32(data[i + 3]) << 24)
        let two = UInt32(data[i + 4]) | UInt32(data[i + 5]) << 8 | UInt32(data[i + 6]) << 16 | UInt32(data[i + 7]) << 24
        crc = t[7 * 256 + Int(one & 0xff)] ^ t[6 * 256 + Int((one >> 8) & 0xff)]
          ^ t[5 * 256 + Int((one >> 16) & 0xff)] ^ t[4 * 256 + Int(one >> 24)]
          ^ t[3 * 256 + Int(two & 0xff)] ^ t[2 * 256 + Int((two >> 8) & 0xff)]
          ^ t[1 * 256 + Int((two >> 16) & 0xff)] ^ t[Int(two >> 24)]
        i += 8
      }
      while i < n {
        crc = t[Int((crc ^ UInt32(data[i])) & 0xff)] ^ (crc >> 8)
        i += 1
      }
    }
    return ~crc
  }
}
