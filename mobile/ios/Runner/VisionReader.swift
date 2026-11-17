// SPDX-License-Identifier: AGPL-3.0-only
import CoreGraphics
import Foundation
import Vision

/// Karelerde altyazı bölgesini okuyan ve çeviri hattına veren [FrameReader] (Android'deki Engine.readFrame,
/// rows ve buildPipeline'ın karşılığı). Yazı tanıma ML Kit yerine Apple'ın Vision çatısıyla, cihaz üstünde.
final class VisionReader: FrameReader {
  private unowned let engine: Engine
  private let queue = DispatchQueue(label: "gt.reader")
  private let translating = DispatchQueue(label: "gt.translate")
  private let busyLock = NSLock()
  private var busy = false
  private let scheduler = ReadScheduler()
  private var pipeline: SubtitlePipeline?
  private var region = Region()
  private var language = "en"
  private var hideButtonHints = true
  private var lastLines: [String] = []
  private var lastBox: TextBox?
  private var ocrTimes: [Int] = []
  private let sink: ServerSink

  init(engine: Engine) {
    self.engine = engine
    sink = ServerSink(server: engine.server)
  }

  // MARK: - FrameReader

  func rebuild(settings s: Settings) {
    queue.async {
      self.pipeline?.reset()
      self.region = s.region
      self.language = s.sourceLanguage
      self.hideButtonHints = s.hideButtonHints
      // Cihaz üstü çeviri (Apple) arka planda hazırlanır: internet koptuğunda yedek olur (Android'deki ML Kit gibi).
      let local = AppleTranslator(source: s.sourceLanguage, target: s.targetLanguage) { level, text in self.engine.log(level, text) }
      self.translating.async { _ = local.prepare() }
      let online: TextTranslator?
      switch s.engine {
      case "deepl":
        online = s.deepLKey.trimmingCharacters(in: .whitespaces).isEmpty
          ? GoogleGtxTranslator(source: s.sourceLanguage, target: s.targetLanguage)
          : FallbackTranslator(DeepLTranslator(key: s.deepLKey, source: s.sourceLanguage, target: s.targetLanguage),
                               GoogleGtxTranslator(source: s.sourceLanguage, target: s.targetLanguage))
      case "gemini":
        let google = GoogleGtxTranslator(source: s.sourceLanguage, target: s.targetLanguage)
        online = s.geminiKey.trimmingCharacters(in: .whitespaces).isEmpty || s.targetLanguage != "tr"
          ? google
          : FallbackTranslator(GeminiTranslator(key: s.geminiKey) { level, text in self.engine.log(level, text) }, google)
      case "mlkit":
        online = nil
      default:
        online = GoogleGtxTranslator(source: s.sourceLanguage, target: s.targetLanguage)
      }
      let engineTranslator: TextTranslator = online.map { FallbackTranslator($0, local) } ?? local
      // Sözlüğün ek kuralları Türkçeye göredir; bilgisayarda da yalnız İngilizce→Türkçe için çalışır.
      let glossary = s.sourceLanguage == "en" && s.targetLanguage == "tr" ? s.parsedGlossary() : Glossary.EMPTY
      if !glossary.isEmpty { self.engine.log(2, "terim sözlüğü: \(glossary.count) terim") }
      let withGlossary: TextTranslator = glossary.isEmpty ? engineTranslator : GlossaryTranslator(glossary, engineTranslator)
      // Baştaki konuşmacı işareti ("- ", ">>") motorlara gönderilmez; hangi motor çevirirse çevirsin korunur.
      // Konuşmacı adı ("ENZO: ", "MINE GUARD: ") çevrilmez: satırdan satıra tutarsız çıkıyordu.
      let translator = PrefixTranslator(SpeakerNameTranslator(withGlossary))
      let engine = self.engine
      let built = SubtitlePipeline(translator: translator, sink: self.sink, translateQueue: self.translating)
      built.onPair = { source, translation in
        engine.lastSource = source
        engine.lastTranslation = translation
        engine.translatedCount += 1
        engine.log(2, "çeviri: \"\(source.replacingOccurrences(of: "\n", with: " "))\" → \"\(translation)\"")
        engine.notifyChanged()
      }
      built.onTranslateFailed = { source in
        engine.log(1, "çevrilemedi: \"\(source.replacingOccurrences(of: "\n", with: " "))\"")
      }
      // Oyun paketi: satır paketteyse motora gidilmez. Bulanık arama yalnız son tam eşleşmenin paketinde (oynanan oyun).
      if s.packsEnabled && PackTranslation.applies(s.sourceLanguage, s.targetLanguage) {
        let library = Packs.shared.library
        library.setPinned(s.packChoice.isEmpty ? nil : s.packChoice)
        // Paketler çeviri kuyruğunda ilk istekten önce açılır (~1 sn; okuma beklemez).
        self.translating.async {
          let started = DispatchTime.now().uptimeNanoseconds
          let infos = library.infos
          engine.log(2, "oyun paketleri: \(infos.count) paket, \(infos.reduce(0) { $0 + $1.entries }) satır (\((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000) ms)")
        }
        built.packLookup = { text in PackTranslation.match(library, text) }
        built.onPackHit = { source, match in
          engine.packHits += 1
          engine.packGame = library.scopeTitle ?? match.packId ?? ""
          engine.log(2, "paket (\(match.packId ?? "?")): \"\(source.replacingOccurrences(of: "\n", with: " "))\"")
        }
      }
      built.onReadText = { text in
        if text != engine.lastRead {
          engine.lastRead = text
          engine.notifyChanged()
        }
      }
      self.scheduler.reset()
      self.lastLines = []
      self.lastBox = nil
      self.pipeline = built
    }
  }

  func reset() {
    queue.async {
      self.region = Store.shared.settings.region
      self.scheduler.reset()
      self.pipeline?.reset()
    }
  }

  func offer(_ frame: Frame) {
    // Önceki kare hâlâ okunuyorsa bu kare atlanır; okuma kareleri biriktirmez.
    busyLock.lock()
    if busy { busyLock.unlock(); return }
    busy = true
    busyLock.unlock()
    queue.async {
      defer { self.busyLock.lock(); self.busy = false; self.busyLock.unlock() }
      self.read(frame)
    }
  }

  // MARK: - Okuma

  private func read(_ frame: Frame) {
    guard let pipeline, let image = frame.cgImage() else { return }
    let r = region
    let fullWidth = frame.width, fullHeight = frame.height
    let cropX = min(max(Int(r.left * Double(fullWidth)), 0), fullWidth - 2)
    let cropY = min(max(Int(r.top * Double(fullHeight)), 0), fullHeight - 2)
    let w = min(max(Int((r.right - r.left) * Double(fullWidth)), 1), fullWidth - cropX)
    let h = min(max(Int((r.bottom - r.top) * Double(fullHeight)), 1), fullHeight - cropY)
    guard let crop = image.cropping(to: CGRect(x: cropX, y: cropY, width: w, height: h)) else { return }

    if let signature = Self.signature(crop), scheduler.canReuse(signature) {
      pipeline.onRead(lastLines, lastBox)
      return
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = [language]
    do {
      let started = DispatchTime.now().uptimeNanoseconds
      try VNImageRequestHandler(cgImage: crop, options: [:]).perform([request])
      ocrTimes.append(Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000))
      if ocrTimes.count >= 100 {
        let sorted = ocrTimes.sorted()
        engine.log(2, "ölçüm: yazı tanıma \(w)x\(h) ortanca \(sorted[sorted.count / 2]) ms, en çok \(sorted.last!) ms")
        ocrTimes.removeAll()
      }
    } catch {
      engine.log(1, "yazı tanıma başarısız: \(error.localizedDescription)")
      return
    }
    let pieces: [Piece] = (request.results ?? []).compactMap { observation in
      guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
      // Vision kutusu 0–1 ve sol alttan; piksel ve sol üstten koordinata çevrilir.
      let b = observation.boundingBox
      let left = Int((b.minX * CGFloat(w)).rounded()), right = Int((b.maxX * CGFloat(w)).rounded())
      let top = Int(((1 - b.maxY) * CGFloat(h)).rounded()), bottom = Int(((1 - b.minY) * CGFloat(h)).rounded())
      return Piece(text: text, left: left, top: top, right: right, bottom: bottom)
    }
    var (lines, box) = Self.rows(pieces, cropX: cropX, cropY: cropY, fullWidth: fullWidth, fullHeight: fullHeight)
    if hideButtonHints {
      // Oyun düğmesi yazıları ("RESUME BA", "SKIP") çeviriye karışmasın.
      lines = lines.map(ButtonHints.strip).filter { !$0.isEmpty }
      if lines.isEmpty { box = nil }
    }
    if let box, !pieces.isEmpty {
      // Satır yüksekliği: okunan satırların ortanca yüksekliği, ekran yüksekliğine oranla.
      let heights = pieces.map { $0.bottom - $0.top }.sorted()
      sink.remember(box, line: Double(heights[heights.count / 2]) / Double(fullHeight),
                    characters: lines.reduce(0) { $0 + $1.count })
    }
    lastLines = lines
    lastBox = box
    pipeline.onRead(lines, box)
  }

  struct Piece {
    let text: String
    let left: Int, top: Int, right: Int, bottom: Int
  }

  /// Tanınan satırları yukarıdan aşağı sıralar, aynı hizadakileri birleştirir; yazının tüm ekrandaki yerini verir
  /// (Android'deki Engine.rows ile aynı kural).
  static func rows(_ input: [Piece], cropX: Int, cropY: Int, fullWidth: Int, fullHeight: Int) -> ([String], TextBox?) {
    let pieces = input.sorted { $0.top < $1.top }
    guard !pieces.isEmpty else { return ([], nil) }
    var grouped: [[Piece]] = []
    for piece in pieces {
      if let reference = grouped.last?.first,
         abs((piece.top + piece.bottom) / 2 - (reference.top + reference.bottom) / 2)
           < max(reference.bottom - reference.top, piece.bottom - piece.top) / 2 {
        grouped[grouped.count - 1].append(piece)
      } else {
        grouped.append([piece])
      }
    }
    let lines = grouped.map { row in row.sorted { $0.left < $1.left }.map(\.text).joined(separator: " ") }
    let left = pieces.map(\.left).min()!, top = pieces.map(\.top).min()!
    let right = pieces.map(\.right).max()!, bottom = pieces.map(\.bottom).max()!
    let box = TextBox(left: Double(cropX + left) / Double(fullWidth), top: Double(cropY + top) / Double(fullHeight),
                      right: Double(cropX + right) / Double(fullWidth), bottom: Double(cropY + bottom) / Double(fullHeight))
    return (lines, box)
  }

  /// Bölgenin 32×8 küçültülmüş parlaklık özeti; iki karenin aynı olup olmadığını anlamak için.
  static func signature(_ image: CGImage) -> [UInt8]? {
    let width = 32, height = 8
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let drawn: Bool = pixels.withUnsafeMutableBytes { raw in
      guard let context = CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
      context.interpolationQuality = .medium
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else { return nil }
    return (0..<(width * height)).map { i in
      let r = Int(pixels[i * 4]), g = Int(pixels[i * 4 + 1]), b = Int(pixels[i * 4 + 2])
      return UInt8((r * 3 + g * 6 + b) / 10)
    }
  }
}

/// Çevirinin gittiği yer: TV sunucusu. Okunan yazının yeri ve satır yüksekliği de gider: TV "cover" yerleşiminde
/// çeviriyi oyunun altyazısının alanına, onun boyunda sığdırır ve alanı opak bantla örter.
private final class ServerSink: SubtitleSink {
  private let server: SubtitleServer
  private let lock = NSLock()
  /// Son okumaların kutusu → (satır yüksekliği, okunan İngilizce metnin karakter sayısı); hat aynı kutuyu çeviriyle
  /// birlikte geri verir.
  private var lines: [(box: TextBox, line: Double, characters: Int)] = []

  init(server: SubtitleServer) { self.server = server }

  func remember(_ box: TextBox, line: Double, characters: Int) {
    lock.lock(); defer { lock.unlock() }
    if let last = lines.last, last.box == box { return }
    lines.append((box, line, characters))
    if lines.count > 32 { lines.removeFirst(lines.count - 32) }
  }

  func show(_ text: String, durationMs: Int, box: TextBox?, replaces: Bool) {
    var line: Double?
    var source = box
    if let box {
      lock.lock()
      let known = lines.last(where: { $0.box == box })
      lock.unlock()
      line = known?.line
      if let known, known.characters > 0 {
        source = Self.widened(box, ratio: Double(text.count) / Double(known.characters))
      }
    }
    server.sendSubtitle(text, durationMs: durationMs, box: box, replaces: replaces, source: source, line: line)
  }

  /// Türkçe çoğu zaman İngilizceden uzundur: TV çeviriyi oyunun altyazısının genişliğine sığdıramayınca iki satıra
  /// bölüp küçültüyordu. Alan, çevirinin uzunluk oranında (%8 payla) iki yana genişletilir; ekranın %90'ını ve
  /// kenarları (%5) aşmaz. Çeviri daha kısaysa alan küçültülmez (oyunun altyazısı tamamen örtülsün).
  static func widened(_ box: TextBox, ratio: Double) -> TextBox {
    let width = box.right - box.left
    guard width > 0, ratio.isFinite else { return box }
    let target = min(0.9, width * ratio * 1.08)
    guard target > width else { return box }
    let center = (box.left + box.right) / 2
    var left = center - target / 2
    var right = center + target / 2
    // Bir kenara dayanırsa öbür yana kaydırılır.
    if left < 0.05 { right += 0.05 - left; left = 0.05 }
    if right > 0.95 { left -= right - 0.95; right = 0.95 }
    return TextBox(left: max(0.05, left), top: box.top, right: min(0.95, right), bottom: box.bottom)
  }

  func clear() { server.clear() }
}
