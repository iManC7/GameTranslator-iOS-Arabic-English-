// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki core/SubtitlePipeline.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Metni çevirir; bloklar. Çevrilemezse null.
/// (Kotlin'de çevirmenin fırlattığı istisna hatta null sayılır; Swift'te çevirmen hata fırlatmaz, hatayı null'a çevirir.)
protocol TextTranslator {
  func translate(_ text: String) -> String?
}

/// Kotlin'deki `fun interface` lambdası: kapanışı çevirmen olarak kullanır.
struct FunctionTranslator: TextTranslator {
  private let body: (String) -> String?

  init(_ body: @escaping (String) -> String?) { self.body = body }

  func translate(_ text: String) -> String? { body(text) }
}

/// Çevirinin gittiği yer (TV sunucusu ve telefondaki ekran).
protocol SubtitleSink {
  func show(_ text: String, durationMs: Int, box: TextBox?, replaces: Bool)
  func clear()
}

/// Oyun paketinden bulunan satır (Android'deki GamePacks.kt: `data class PackMatch(val text: String, val packId: String? = null)`).
/// Paketler: GamePacks.swift (GamePackLibrary), arama: PackTranslation.match.
struct PackMatch: Equatable, Sendable {
  let text: String
  let packId: String?

  init(text: String, packId: String? = nil) {
    self.text = text
    self.packId = packId
  }
}

/// Kotlin'deki `java.util.concurrent.Executor` karşılığı: verilen işi (şimdi ya da sonra) çalıştırır.
typealias TranslateExecutor = (@escaping @Sendable () -> Void) -> Void

/// Okunan altyazıyı çevirip gönderen hat: gürültü temizliği → kararlılık → önbellek → oyun paketi/çeviri → TV.
/// Windows'taki SubtitlePipeline.cs'in çekirdeği (bekletme ve dublaj yok).
/// [onRead] tek bir iş parçacığından çağrılır; çeviri [translateExecutor]'da yapılır, sonuçlar kilit altında işlenir.
final class SubtitlePipeline: @unchecked Sendable {
  /// Satır ekranda durdukça çeviri de durur; kalkınca TV'den silinir.
  static let ON_SCREEN_MS = 15000
  private static let CACHE_SIZE = 300

  /// Çevirisi geldiğinde ekrandan kalkmış satırın TV'de kalacağı süre.
  static func readingTime(_ text: String) -> Int { min(8000, max(2000, 1200 + 60 * text.utf16.count)) }

  private let translator: TextTranslator
  private let sink: SubtitleSink
  private let translateExecutor: TranslateExecutor
  private let stabilizer: SubtitleStabilizer

  // Kotlin'deki `synchronized` yeniden girilebilir; doğrudan çalıştıran yürütücüyle (testler) kilitlenmesin diye
  // NSRecursiveLock kullanılır.
  private let lock = NSRecursiveLock()
  private let cache = LruCache(capacity: SubtitlePipeline.CACHE_SIZE)
  private var latest = 0
  /// Ekranda duran satırın numarası; satır kalktıysa -1.
  private var onScreen = -1
  private var lastShownSource: String?

  /// Çeviri gösterildiğinde (kaynak, çeviri).
  var onPair: ((String, String) -> Void)?
  /// Çeviri başarısız olduğunda kaynak satır.
  var onTranslateFailed: ((String) -> Void)?
  /// Okunan ve temizlenen ham metin (boş olabilir); tanılama için.
  var onReadText: ((String) -> Void)?
  /// Oyun paketi: kararlı satırın hazır Türkçesi (yoksa null). Çeviri motorundan önce, çeviri iş parçacığında bakılır;
  /// bulunursa motora gidilmez ve paketteki metin olduğu gibi gösterilir (sözlük de uygulanmaz).
  var packLookup: ((String) throws -> PackMatch?)? {
    get { lock.lock(); defer { lock.unlock() }; return _packLookup }
    set { lock.lock(); defer { lock.unlock() }; _packLookup = newValue }
  }
  private var _packLookup: ((String) throws -> PackMatch?)?
  /// Paketten gösterilen satır (kaynak, paket).
  var onPackHit: ((String, PackMatch) -> Void)?
  /// Paketten gösterilen satır sayısı.
  var packHits: Int { lock.lock(); defer { lock.unlock() }; return _packHits }
  private var _packHits = 0

  /// [translateQueue] seri bir kuyruk olmalıdır (Android'deki tek iş parçacıklı çeviri yürütücüsü).
  convenience init(
    translator: TextTranslator, sink: SubtitleSink, translateQueue: DispatchQueue,
    stabilizer: SubtitleStabilizer = SubtitleStabilizer()
  ) {
    self.init(translator: translator, sink: sink, translateExecutor: { translateQueue.async(execute: $0) },
              stabilizer: stabilizer)
  }

  init(
    translator: TextTranslator, sink: SubtitleSink, translateExecutor: @escaping TranslateExecutor,
    stabilizer: SubtitleStabilizer = SubtitleStabilizer()
  ) {
    self.translator = translator
    self.sink = sink
    self.translateExecutor = translateExecutor
    self.stabilizer = stabilizer
  }

  /// Bir karenin okuması: [lines] yukarıdan aşağı satırlar, [box] yazının ekrandaki yeri.
  func onRead(_ lines: [String], _ box: TextBox?) {
    let text = lines.map { OcrNoise.clean($0) }.filter { !$0.isEmpty }.joined(separator: "\n")
    onReadText?(text)
    lock.lock()
    defer { lock.unlock() }
    let action = stabilizer.feed(text)
    switch action.kind {
    case .none:
      break
    case .clear:
      onScreen = -1
      sink.clear()
    case .restore:
      guard let source = action.text else { return }
      latest += 1
      let number = latest
      onScreen = number
      if let cached = cache.get(key(source)) {
        show(source, cached, box, SubtitlePipeline.ON_SCREEN_MS, replaces: false)
      } else {
        request(number, source, box)
      }
    case .translate:
      guard let source = action.text else { return }
      latest += 1
      let number = latest
      onScreen = number
      if let cached = cache.get(key(source)) { deliver(number, source, cached, box) } else { request(number, source, box) }
    }
  }

  private func request(_ number: Int, _ source: String, _ box: TextBox?) {
    translateExecutor { [self] in
      let packed: PackMatch? = (try? packLookup?(source)).flatMap { KotlinText.isBlank($0.text) ? nil : $0 }
      // İki satırlık altyazı tek cümledir; çevirmene tek satır olarak gider.
      let translated: String? = packed.map { KotlinText.trim($0.text) }
        ?? (translator.translate(KotlinText.string(source.utf16.map { $0 == 0x0A ? 0x20 : $0 })))
          .map { KotlinText.trim($0) }
      lock.lock()
      defer { lock.unlock() }
      if let packed = packed {
        _packHits += 1
        onPackHit?(source, packed)
      }
      guard let translated = translated, !translated.isEmpty else {
        if number == onScreen { stabilizer.forgetSent() }
        onTranslateFailed?(source)
        return
      }
      cache.set(key(source), translated)
      deliver(number, source, translated, box)
    }
  }

  /// Kilit altında çağrılır. Yerine yenisi gelmiş satırın geç kalan çevirisi gösterilmez.
  private func deliver(_ number: Int, _ source: String, _ translated: String, _ box: TextBox?) {
    if number != latest { return }
    // Çeviri kaynağıyla neredeyse aynıysa metin zaten hedef dildedir.
    if !stabilizer.shouldSend(source, translated) { return }
    let duration = number == onScreen ? SubtitlePipeline.ON_SCREEN_MS : SubtitlePipeline.readingTime(translated)
    let replaces = lastShownSource.map { TextMatch.isRevision(source, $0) } ?? false
    show(source, translated, box, duration, replaces: replaces)
  }

  private func show(_ source: String, _ translated: String, _ box: TextBox?, _ duration: Int, replaces: Bool) {
    lastShownSource = source
    sink.show(translated, durationMs: duration, box: box, replaces: replaces)
    onPair?(source, translated)
  }

  private func key(_ source: String) -> UTF16Text { KotlinText.units(TextMatch.normalize(source)) }

  func reset() {
    lock.lock()
    defer { lock.unlock() }
    latest += 1
    onScreen = -1
    lastShownSource = nil
    if stabilizer.reset().kind == .clear { sink.clear() }
  }
}

/// Kotlin'deki erişim sıralı `LinkedHashMap` + `removeEldestEntry`: en uzun süredir dokunulmayan kayıt atılır.
/// Anahtarlar UTF-16 birimleridir (Kotlin String eşitliği; Swift String'in kanonik eşdeğerliği değil).
private final class LruCache {
  private let capacity: Int
  private var values: [UTF16Text: String] = [:]
  /// En eskiden en yeniye erişim sırası.
  private var order: [UTF16Text] = []

  init(capacity: Int) { self.capacity = capacity }

  func get(_ key: UTF16Text) -> String? {
    guard let value = values[key] else { return nil }
    touch(key)
    return value
  }

  func set(_ key: UTF16Text, _ value: String) {
    if values.updateValue(value, forKey: key) != nil { touch(key) } else { order.append(key) }
    if values.count > capacity {
      let eldest = order.removeFirst()
      values[eldest] = nil
    }
  }

  private func touch(_ key: UTF16Text) {
    if let index = order.firstIndex(of: key) { order.remove(at: index) }
    order.append(key)
  }
}

/// Hangi karede yazı tanıma yapılacağını seçer: bölge değişmediyse son okuma yeniden kullanılır.
/// Oyun süresinin çoğunda bölge boştur ya da değişmez; telefonda bu pil ve ısı demektir (Windows'taki ReadScheduler).
final class ReadScheduler {
  private let changeThreshold: Int
  private let maxReuse: Int
  private var previous: [UInt8]?
  private var reused = 0

  init(changeThreshold: Int = 16, maxReuse: Int = 20) {
    self.changeThreshold = changeThreshold
    self.maxReuse = maxReuse
  }

  /// true ise bölge değişmedi; son okuma geçerli.
  func canReuse(_ signature: [UInt8]) -> Bool {
    let before = previous
    previous = signature
    if let before = before, reused < maxReuse, !changed(before, signature) {
      reused += 1
      return true
    }
    reused = 0
    return false
  }

  func reset() {
    previous = nil
    reused = 0
  }

  private func changed(_ a: [UInt8], _ b: [UInt8]) -> Bool {
    if a.count != b.count { return true }
    for i in a.indices where abs(Int(a[i]) - Int(b[i])) > changeThreshold { return true }
    return false
  }
}
