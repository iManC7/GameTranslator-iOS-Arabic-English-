// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import UIKit

/// Uygulamanın çekirdeği (Android'deki Engine.kt'nin iOS karşılığı): PS5 Remote Play oturumunu açar, gelen kareleri
/// tutar ve altyazı sunucusunu yönetir. Yazı okuma ve çeviri hattı [FrameReader] üzerinden bağlanır.
final class Engine: Native.Listener {
  static let shared = Engine()

  /// Yazı tanıma için saniyede en çok bu kadar kare verilir. Android'de 5; iPhone'da Vision bölgeyi ~70–100 ms'de
  /// okuyor ve çeviri ~80 ms sürüyor, gecikmenin çoğu kareler arası beklemeydi (kararlılık iki kare ister).
  /// Bölge değişmedikçe okuma yeniden kullanıldığı için yük yalnız altyazı değişirken artar.
  static let maxFps = 10
  private static let logLimit = 300

  /// idle, starting, waking, connecting, streaming, reconnecting, stopping, failed
  private(set) var phase = "idle"
  private(set) var message = ""
  private(set) var running = false
  var lastSource = ""
  var lastTranslation = ""
  var lastRead = ""
  private(set) var frameCount = 0
  private(set) var frameWidth = 0
  private(set) var frameHeight = 0
  var translatedCount = 0
  var packHits = 0
  var packGame = ""

  let server = SubtitleServer()

  /// Durum değişince ana iş parçacığında çağrılır.
  var onChanged: (([String: Any?]) -> Void)?

  /// Gelen her karenin okunması (yazı tanıma + çeviri). Verilmediyse kareler yalnız saklanır.
  var reader: FrameReader?

  /// Durum değişkenleri, oturum ve sunucu işleri bu kuyrukta sıralanır (Android'deki gt-control iş parçacığı).
  private let control = DispatchQueue(label: "gt.control")
  private let logLock = NSLock()
  private var logs: [String] = []
  private var notifyPending = false
  private(set) var settings = Settings()
  private var session: Native.Session?
  private var retry: DispatchWorkItem?
  private let stopLock = NSLock()
  private var _stopRequested = false
  /// Durdurma istendi ama denetim kuyruğu henüz işlemedi (uyandırma beklemesini keser).
  private var stopRequested: Bool {
    get { stopLock.lock(); defer { stopLock.unlock() }; return _stopRequested }
    set { stopLock.lock(); _stopRequested = newValue; stopLock.unlock() }
  }

  /// Son kare (BGRA). Okuma ve önizleme kopyasını alır.
  private let frameLock = NSLock()
  private var frame: Frame?

  private init() {
    // Uygulama arka plandan dönünce (çeviri kapalıyken iOS uygulamayı askıya almış olabilir) dinleyici bozulmuş olabilir;
    // TV "bekleniyor"da kalıyordu, çeviriyi kapatıp açmak düzeltiyordu. Dönüşte sunucu yeniden kurulur.
    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
      self?.onControl {
        guard let self else { return }
        if !self.running || !self.server.isReady {
          self.log(2, "uygulama önde: altyazı sunucusu yeniden kuruluyor")
          self.server.restart()
          self.server.sendStyle(Store.shared.settings.style)
        }
      }
    }
    server.onChanged = { [weak self] in self?.notifyChanged() }
    server.onLog = { [weak self] level, text in self?.log(level, text) }
    if let url = Bundle.main.url(forResource: "obs-overlay", withExtension: "html") {
      server.overlayPage = try? Data(contentsOf: url)
    }
  }

  // MARK: - Durum

  func state() -> [String: Any?] {
    [
      "phase": phase,
      "message": message,
      "running": running,
      "tvClients": server.connectedClients,
      "serverPort": server.boundPort,
      "localAddress": Network.localAddress(),
      "lastSource": lastSource,
      "lastTranslation": lastTranslation,
      "lastRead": lastRead,
      "frames": frameCount,
      "frameWidth": frameWidth,
      "frameHeight": frameHeight,
      "translated": translatedCount,
      "packHits": packHits,
      "packGame": packGame,
      "nativeAvailable": Native.available,
    ]
  }

  func logLines() -> [String] {
    logLock.lock(); defer { logLock.unlock() }
    return logs
  }

  func log(_ level: Int, _ text: String) {
    let line = "\(level == 0 ? "E" : level == 1 ? "W" : "I") \(text)"
    NSLog("GameTranslator %@", line)
    logLock.lock()
    logs.append(line)
    if logs.count > Self.logLimit { logs.removeFirst(logs.count - Self.logLimit) }
    logLock.unlock()
  }

  private func setPhase(_ value: String, _ text: String = "") {
    phase = value
    message = text
    log(value == "failed" ? 0 : 2, "durum: \(value) \(text)".trimmingCharacters(in: .whitespaces))
    notifyChanged()
  }

  /// Arayüze en çok ~10 Hz bildirim: kare sayacı her karede değişir.
  func notifyChanged() {
    DispatchQueue.main.async {
      if self.notifyPending { return }
      self.notifyPending = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.notifyPending = false
        self.onChanged?(self.state())
      }
    }
  }

  /// Denetim kuyruğunda çalıştırır.
  private func onControl(_ block: @escaping () -> Void) { control.async(execute: block) }

  // MARK: - Başlat / durdur

  /// Uygulama açılınca: altyazı sunucusu çeviri başlamadan da açık olur; TV telefonu hemen bulur.
  func openServer() {
    onControl {
      self.settings = Store.shared.settings
      self.server.start()
      self.server.sendStyle(self.settings.style)
      self.log(2, "altyazı sunucusu: \(Network.localAddress() ?? "?"):\(SubtitleServer.defaultPort)")
    }
  }

  func start() {
    stopRequested = false
    onControl {
      if self.running { return }
      let store = Store.shared
      self.settings = store.settings
      if !Native.available { return self.setPhase("failed", "Yerel kütüphane yüklenemedi") }
      if store.accountId == nil || store.console == nil {
        return self.setPhase("failed", "Önce PSN girişi ve PS5 eşleştirmesi gerekli")
      }
      self.running = true
      self.frameCount = 0
      self.translatedCount = 0
      self.packHits = 0
      self.packGame = ""
      self.setPhase("starting")
      // Ekran kilitliyken de sürsün diye uygulama sessiz bir ses akışıyla arka planda canlı tutulur.
      BackgroundKeeper.shared.log = { [weak self] level, text in self?.log(level, text) }
      BackgroundKeeper.shared.start()
      self.server.start()
      self.log(2, "altyazı sunucusu: \(Network.localAddress() ?? "?"):\(SubtitleServer.defaultPort)")
      self.server.sendStyle(self.settings.style)
      if self.reader == nil { self.reader = VisionReader(engine: self) }
      if self.settings.packsEnabled { Packs.shared.refresh { [weak self] level, text in self?.log(level, text) } }
      self.reader?.rebuild(settings: self.settings)
      self.connect()
    }
  }

  func stop() {
    stopRequested = true
    // Oturumun kapanması birkaç saniye sürebilir; arayüz bu sırada "durduruluyor" gösterir.
    if running || session != nil { setPhase("stopping") }
    onControl {
      if !self.running && self.session == nil { return self.setPhase("idle") }
      self.running = false
      self.retry?.cancel()
      self.retry = nil
      self.closeSession()
      self.reader?.reset()
      // Sunucu açık kalır: TV bağlı kalsın, çeviri yeniden başlayınca altyazılar hemen gitsin.
      self.server.clear()
      self.frameLock.lock(); self.frame = nil; self.frameLock.unlock()
      BackgroundKeeper.shared.stop()
      self.setPhase("idle")
    }
  }

  /// Ayarlar değişti: görünüm hemen TV'ye gider; dil, motor ya da bölge değiştiyse okuma hattı yenilenir.
  func applySettings() {
    onControl {
      let before = self.settings
      let now = Store.shared.settings
      self.settings = now
      if now.style != before.style, self.server.isStarted { self.server.sendStyle(now.style) }
      guard self.running else { return }
      if now.engine != before.engine || now.deepLKey != before.deepLKey || now.geminiKey != before.geminiKey || now.sourceLanguage != before.sourceLanguage
        || now.targetLanguage != before.targetLanguage || now.glossary != before.glossary || now.packsEnabled != before.packsEnabled
        || now.packChoice != before.packChoice {
        self.reader?.rebuild(settings: now)
      } else if now.region != before.region || now.hideButtonHints != before.hideButtonHints {
        self.reader?.reset()
      }
    }
  }

  /// TV'de deneme altyazısı; sunucu kapalıysa açılır (TV telefonu bulsun diye açık kalır).
  func sendTestSubtitle() {
    onControl {
      self.settings = Store.shared.settings
      if !self.server.isStarted {
        self.server.start()
        self.log(2, "altyazı sunucusu: \(Network.localAddress() ?? "?"):\(SubtitleServer.defaultPort)")
      }
      self.server.sendStyle(self.settings.style)
      let r = self.settings.region
      self.server.sendSubtitle("Bu bir deneme altyazısıdır. Oyunun üstünde görüyor musunuz?", durationMs: 8000,
                               box: TextBox(left: 0.3, top: r.bottom - 0.1, right: 0.7, bottom: r.bottom - 0.03))
    }
  }

  // MARK: - PS5 oturumu

  /// [relocated]: adres bu denemede zaten yenilendi; ağ ikinci kez taranmaz.
  private func connect(relocated: Bool = false) {
    guard running else { return }
    let store = Store.shared
    guard let console = store.console else { return setPhase("failed", "PS5 eşleştirmesi yok") }
    guard let account = store.accountId else { return setPhase("failed", "PSN hesabı yok") }
    setPhase("connecting", console.host)

    // PS5 açık mı? Kapalıysa (dinlenme modu) ayara göre uyandırılır.
    switch probe(console.host) {
    case true?:
      break
    case false?:
      guard settings.autoWake, let credential = console.wakeCredential else {
        setPhase("failed", "PS5 dinlenme modunda")
        return scheduleRetry(10)
      }
      setPhase("waking", console.host)
      Native.wake(host: console.host, credential: credential)
      let deadline = Date().addingTimeInterval(60)
      var awake = false
      while !stopRequested && !awake && Date() < deadline { awake = probe(console.host) == true }
      if stopRequested { return }
      if !awake {
        setPhase("failed", "PS5 uyanmadı")
        return scheduleRetry(10)
      }
      setPhase("connecting", console.host)
    case nil:
      // Modem PS5'e yeni adres vermiş olabilir: ağ taranır, aynı adlı konsol bulunursa kayıt güncellenir.
      let moved = relocated ? nil : relocate(console)
      if stopRequested { return }
      if let moved {
        log(2, "PS5 yeni adreste bulundu: \(console.host) → \(moved)")
        store.console = Console(host: moved, name: console.name, registKey: console.registKey, morning: console.morning)
        return connect(relocated: true)
      }
      setPhase("failed", "PS5 ağda bulunamadı (\(console.host))")
      return scheduleRetry(5)
    }

    log(2, "PS5 oturumu: \(console.name) \(console.host)")
    session = Native.startSession(host: console.host, registKey: console.registKey, morning: console.morning,
                                  accountId: account, maxFps: Self.maxFps, listener: self)
    if session == nil {
      setPhase("failed", "Oturum başlatılamadı")
      scheduleRetry(5)
    }
  }

  /// Kayıtlı adres yanıt vermiyorsa konsolu ağda arar. Aynı adlı tek konsol varsa adresini döner; yoksa ya da
  /// birden çok aday varsa nil (başka bir PS5'in adresi kayda yazılmasın).
  private func relocate(_ console: Console) -> String? {
    let sameName = discover(hosts: [], timeoutMs: 2500).filter { $0["host"] as? String != console.host && $0["name"] as? String == console.name }
    return sameName.count == 1 ? sameName[0]["host"] as? String : nil
  }

  /// true: açık, false: dinlenme modunda, nil: yanıt yok.
  private func probe(_ host: String) -> Bool? {
    let lock = NSLock()
    var result: Bool?
    Native.discover(targets: [host], timeoutMs: 1500) { _, _, awake in
      lock.lock()
      if result != true { result = awake }
      lock.unlock()
    }
    lock.lock(); defer { lock.unlock() }
    return result
  }

  private func closeSession() {
    let current = session
    session = nil
    current?.stop()
  }

  private func scheduleRetry(_ seconds: Double) {
    guard running else { return }
    retry?.cancel()
    let item = DispatchWorkItem { [weak self] in
      guard let self, self.running, self.session == nil else { return }
      self.connect()
    }
    retry = item
    control.asyncAfter(deadline: .now() + seconds, execute: item)
  }

  // MARK: - Native.Listener (libchiaki'nin iş parçacıklarından)

  func onLog(_ level: Int, _ message: String) {
    // Bilgi satırları (her 5 sn'de kalp atışı, paket dökümleri) günlüğü doldurur; hata ve uyarılar tutulur.
    if level < 2 || message.hasPrefix("Session") || message.hasPrefix("Starting") || message.hasPrefix("Switched") {
      log(level, "chiaki: \(message)")
    }
  }

  func onEvent(_ event: Int32, quitReason: Int32, reasonText: String?) {
    switch event {
    case Native.eventConnected:
      onControl { self.setPhase("streaming") }
    case Native.eventLoginPin:
      onControl {
        self.closeSession()
        self.running = false
        self.setPhase("failed", "PS5 kullanıcısının giriş şifresi var; şifresiz bir kullanıcı kullanın")
      }
    case Native.eventQuit:
      onControl {
        // Oturum kendi iş parçacığından kapatılamaz; denetim kuyruğunda bırakılır.
        self.closeSession()
        guard self.running else { return }
        switch quitReason {
        case Native.quitStopped:
          break
        case Native.quitInUse:
          self.setPhase("failed", "Remote Play başka bir cihazda kullanılıyor")
          self.scheduleRetry(10)
        case Native.quitRefused:
          self.running = false
          self.setPhase("failed", "PS5 bağlantıyı reddetti; yeniden eşleştirin")
        default:
          self.setPhase("reconnecting", reasonText ?? "bağlantı koptu")
          self.scheduleRetry(3)
        }
      }
    default:
      break
    }
  }

  func onFrame(base: UnsafePointer<UInt8>, width: Int, height: Int, stride: Int) {
    let copy = Frame(width: width, height: height, stride: stride, pixels: Data(bytes: base, count: stride * height))
    frameLock.lock()
    frame = copy
    frameLock.unlock()
    frameWidth = width
    frameHeight = height
    frameCount += 1
    if frameCount % Self.maxFps == 1 { notifyChanged() }
    reader?.offer(copy)
  }

  /// Son karenin kopyası; kare yoksa nil.
  func currentFrame() -> Frame? {
    frameLock.lock(); defer { frameLock.unlock() }
    return frame
  }

  // MARK: - Arayüz için yardımcılar

  /// Son karenin JPEG görüntüsü (bölge ayarı ve önizleme için); kare yoksa nil.
  func snapshot(width maxWidth: Int) -> Data? {
    guard let frame = currentFrame(), let image = frame.cgImage() else { return nil }
    let width = min(maxWidth, frame.width)
    let height = frame.height * width / frame.width
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return format
    }())
    return renderer.jpegData(withCompressionQuality: 0.8) { _ in
      UIImage(cgImage: image).draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    }
  }

  /// Aramada sorulacak adresler: yayın adresleri ve /24 ağlardaki tüm adresler. iOS yayın paketlerini ayrı bir
  /// izin olmadan göndermez; tek tek adres taraması her ağda çalışır.
  private func discoveryTargets(_ extra: [String]) -> [String] {
    var targets: [String] = ["255.255.255.255"]
    func add(_ value: String) { if !value.isEmpty && !targets.contains(value) { targets.append(value) } }
    extra.forEach(add)
    for network in Network.ipv4Networks() {
      add(network.broadcast)
      if network.prefixLength >= 24 {
        for i in 1...254 { add(network.prefix24 + String(i)) }
      }
    }
    return targets
  }

  /// Ağdaki PS5'leri arar (bloklar). [hosts]: elle girilen adresler.
  func discover(hosts: [String], timeoutMs: Int) -> [[String: Any]] {
    guard Native.available else { return [] }
    let lock = NSLock()
    var order: [String] = []
    var found: [String: [String: Any]] = [:]
    Native.discover(targets: discoveryTargets(hosts), timeoutMs: timeoutMs) { host, name, awake in
      lock.lock()
      if found[host] == nil { order.append(host) }
      found[host] = ["host": host, "name": name, "awake": awake]
      lock.unlock()
    }
    lock.lock(); defer { lock.unlock() }
    return order.compactMap { found[$0] }
  }

  /// PS5'in "Cihaz Eşleştir" koduyla kayıt (bloklar, en çok ~30 sn). Başarılıysa kaydı saklar.
  func register(host: String, pin: Int) -> [String: Any] {
    let store = Store.shared
    guard let account = store.accountId else { return ["ok": false, "detail": "Önce PSN girişi gerekli"] }
    guard Native.available else { return ["ok": false, "detail": "Yerel kütüphane yüklenemedi"] }
    let errorLock = NSLock()
    var errors: [String] = []
    log(2, "PS5 kaydı başlıyor: \(host)")
    let outcome = Native.register(host: host, accountId: account, pin: UInt32(pin)) { [weak self] level, message in
      self?.log(level, "chiaki: \(message)")
      if level == 0 { errorLock.lock(); errors.append(message); errorLock.unlock() }
    }
    guard outcome.result == 0, let registered = outcome.registered else {
      let code = outcome.reason
      errorLock.lock()
      let seen = errors
      errorLock.unlock()
      let detail: String
      if code == 0x80108b02 {
        detail = "PS5 bu PSN hesabını tanımadı. PS5'te oturum açık olan kullanıcıyla aynı hesapla giriş yapın."
      } else if code == 0x80108b09 || code == 0x80108b12 {
        detail = "Kod yanlış ya da süresi dolmuş. PS5'te Cihaz Eşleştir'i yeniden açıp yeni kodu girin."
      } else if outcome.result == 2 {
        detail = "İptal edildi"
      } else if seen.contains(where: { $0.range(of: "search", options: .caseInsensitive) != nil }) {
        // PS5 "Cihaz Eşleştir" ekranında değilken kayıt aramasını reddeder ya da hiç yanıtlamaz.
        detail = "PS5 eşleştirmeye hazır değil. PS5'te Ayarlar › Sistem › Uzaktan Oynatma › Cihaz Eşleştir ekranını açık tutup yeniden deneyin."
      } else {
        detail = seen.first ?? "PS5 yanıt vermedi. Konsolun açık ve Cihaz Eşleştir ekranında olduğunu kontrol edin."
      }
      log(0, "PS5 kaydı başarısız: \(detail)")
      return ["ok": false, "reason": Int(Int32(bitPattern: code)), "detail": detail]
    }
    let name = registered.name.trimmingCharacters(in: .whitespaces).isEmpty ? "PS5" : registered.name
    store.console = Console(host: host, name: name, registKey: registered.registKey, morning: registered.morning)
    log(2, "PS5 kaydı tamam: \(name)")
    return ["ok": true, "name": name, "host": host]
  }
}

/// Çözülmüş bir kare (BGRA, satır başına [stride] bayt).
struct Frame {
  let width: Int
  let height: Int
  let stride: Int
  let pixels: Data

  func cgImage() -> CGImage? {
    guard let provider = CGDataProvider(data: pixels as CFData) else { return nil }
    let info = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
    return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: stride,
                   space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info, provider: provider, decode: nil,
                   shouldInterpolate: true, intent: .defaultIntent)
  }
}

/// Gelen kareleri okuyan hat (yazı tanıma + çeviri); Engine yalnız bu arayüzü bilir.
protocol FrameReader: AnyObject {
  /// Ayarlara göre hattı yeniden kurar (denetim kuyruğunda).
  func rebuild(settings: Settings)
  /// Bölge ya da oturum değişti: geçmiş unutulur.
  func reset()
  /// Yeni kare; okuma sürüyorsa kare atlanabilir (libchiaki iş parçacığından).
  func offer(_ frame: Frame)
}

/// Ağ yardımcıları.
enum Network {
  struct IPv4 {
    let address: String
    let broadcast: String
    let prefixLength: Int
    /// "192.168.1." biçiminde ilk üç bayt.
    let prefix24: String
  }

  /// Telefonun yerel ağdaki IPv4 adresi (Wi-Fi, yani en0, öncelikli).
  static func localAddress() -> String? {
    let networks = ipv4Networks(includeCellular: false)
    return networks.first(where: { $0.name == "en0" })?.network.address ?? networks.first?.network.address
  }

  /// Açık, geri döngü olmayan IPv4 arayüzleri. Hücresel (pdp_ip) ve VPN arayüzleri TV'ye ve PS5'e ulaşmaz.
  static func ipv4Networks() -> [IPv4] { ipv4Networks(includeCellular: false).map(\.network) }

  private static func ipv4Networks(includeCellular: Bool) -> [(name: String, network: IPv4)] {
    var result: [(String, IPv4)] = []
    var list: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&list) == 0, let first = list else { return [] }
    defer { freeifaddrs(list) }
    for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
      let entry = pointer.pointee
      let flags = Int32(entry.ifa_flags)
      guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_INET), let mask = entry.ifa_netmask,
            flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
      let name = String(cString: entry.ifa_name)
      if !includeCellular, name.hasPrefix("pdp_ip") || name.hasPrefix("utun") || name.hasPrefix("ipsec") { continue }
      let ip = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
      let netmask = mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
      func text(_ value: UInt32) -> String { "\(value >> 24 & 0xff).\(value >> 16 & 0xff).\(value >> 8 & 0xff).\(value & 0xff)" }
      let prefix = "\(ip >> 24 & 0xff).\(ip >> 16 & 0xff).\(ip >> 8 & 0xff)."
      result.append((name, IPv4(address: text(ip), broadcast: text(ip | ~netmask), prefixLength: netmask.nonzeroBitCount, prefix24: prefix)))
    }
    return result
  }
}
