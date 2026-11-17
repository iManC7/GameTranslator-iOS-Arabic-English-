// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Network

/// Oyundaki altyazının ekrandaki yeri, kenarlara oranla (0–1).
struct TextBox: Equatable {
  var left: Double
  var top: Double
  var right: Double
  var bottom: Double
}

/// TV'de altyazının görünümü (Android'deki SubtitleStyle ve Windows'taki SubtitleStyle ile aynı alanlar).
struct SubtitleStyle: Equatable {
  var fontSize = 46
  var bottomPercent = 7
  /// cover, above, below, fixed
  var placement = "cover"
  var background = 72
  var bold = false
  /// white, yellow
  var textColor = "white"
  /// inApp, overlay (yalnız Android TV uygulaması kullanır)
  var displayMode = "inApp"
  var stackPrevious = true
  /// Konuşmacı adı ("ENZO:") renkli; bilgisayar sürümündeki "Konuşmacı adı renkli" (yalnız iPhone ayarlarında).
  var speakerColor = false
}

/// TV uygulamasının bağlandığı yerel Server-Sent Events sunucusu. `GET /events` akışında `subtitle`, `clear` ve
/// `style` olaylarını yayınlar; `GET /hello` ile TV telefonu ağda tanır. Android'deki SubtitleServer.kt ve
/// Windows'taki SubtitleServer.cs ile aynı protokol.
final class SubtitleServer {
  static let defaultPort: UInt16 = 8787
  static let pingFrame = ": ping\n\nevent: ping\ndata: {}\n\n"
  /// TV uygulaması yanıtta küçük harfle "gametranslator" arar.
  static let helloBody = "{\"app\":\"gametranslator\"}"

  private final class Client {
    let connection: NWConnection
    let viewer: Bool
    init(connection: NWConnection, viewer: Bool) {
      self.connection = connection
      self.viewer = viewer
    }
  }

  private let queue = DispatchQueue(label: "gt.subtitle-server")
  private let port: UInt16
  private let pingInterval: TimeInterval
  private var listener: NWListener?
  private var pingTimer: DispatchSourceTimer?
  private var clients: [ObjectIdentifier: Client] = [:]
  /// İsteği henüz okunmamış bağlantılar (10 sn içinde istek gelmezse kapatılır).
  private var pending: [ObjectIdentifier: NWConnection] = [:]
  private var lastStyle: SubtitleStyle?
  private var _boundPort: UInt16 = 0
  private var _connected = 0
  private var page: Data?
  /// Sunucu açık olmalı mı (start çağrıldı, stop çağrılmadı); dinleyici düşerse yeniden kurulur.
  private var wanted = false
  private var ready = false
  private var retryScheduled = false

  /// Bağlı TV sayısı ya da dinlenen port değişince çağrılır (sunucu kuyruğunda).
  var onChanged: (() -> Void)?
  /// Sunucu günlüğe yazmak istediğinde (seviye: 0 hata, 1 uyarı, 2 bilgi).
  var onLog: ((Int, String) -> Void)?

  init(port: UInt16 = SubtitleServer.defaultPort, pingInterval: TimeInterval = 15) {
    self.port = port
    self.pingInterval = pingInterval
  }

  /// /obs adresinde sunulan sayfa; verilmediyse adres 404 döner.
  var overlayPage: Data? {
    get { queue.sync { page } }
    set { queue.sync { page = newValue } }
  }

  /// Dinlenen port; başlamadıysa 0.
  var boundPort: Int { queue.sync { Int(_boundPort) } }

  /// Bağlı TV sayısı (OBS/tarayıcı izleyicileri sayılmaz).
  var connectedClients: Int { queue.sync { _connected } }

  var isStarted: Bool { queue.sync { listener != nil } }

  /// Dinleyici kurulmuş ve bağlantı kabul ediyor mu.
  var isReady: Bool { queue.sync { listener != nil && ready } }

  /// Sunucuyu başlatır. TV yalnız 8787'yi taradığı için port hep 8787'dir; doluysa (ör. uygulama yeniden açılırken
  /// eski dinleyici henüz kapanmadıysa) birkaç saniyede bir yeniden denenir.
  func start() {
    queue.async {
      self.wanted = true
      self.startLocked()
    }
  }

  /// Dinleyiciyi ve bağlantıları kapatıp yeniden kurar (uygulama arka plandan dönünce dinleyici bozulmuş olabilir).
  func restart() {
    queue.async {
      self.closeLocked()
      self.wanted = true
      self.startLocked()
    }
  }

  func stop() {
    queue.async {
      self.wanted = false
      self.closeLocked()
      self.updateCount()
      self.onChanged?()
    }
  }

  private func closeLocked() {
    pingTimer?.cancel()
    pingTimer = nil
    listener?.cancel()
    listener = nil
    ready = false
    _boundPort = 0
    let closing = Array(clients.values)
    clients.removeAll()
    for client in closing { client.connection.cancel() }
    for connection in pending.values { connection.cancel() }
    pending.removeAll()
    updateCount()
  }

  func sendSubtitle(_ text: String, durationMs: Int = 15000, box: TextBox? = nil, replaces: Bool = false,
                    source: TextBox? = nil, line: Double? = nil) {
    let at = Int64(Date().timeIntervalSince1970 * 1000)
    broadcast(Self.subtitleFrame(text, durationMs: durationMs, box: box, replaces: replaces, at: at, source: source, line: line))
  }

  func clear() { broadcast(Self.frame("clear", "{}")) }

  func sendStyle(_ style: SubtitleStyle) {
    queue.async { self.lastStyle = style }
    broadcast(Self.styleFrame(style))
  }

  // MARK: - Çerçeveler (Android'dekiyle bayt bayt aynı)

  static func jsonString(_ text: String) -> String {
    var out = "\""
    for scalar in text.unicodeScalars {
      switch scalar {
      case "\"": out += "\\\""
      case "\\": out += "\\\\"
      case "\n": out += "\\n"
      case "\r": out += "\\r"
      case "\t": out += "\\t"
      default:
        if scalar.value < 0x20 {
          out += String(format: "\\u%04x", scalar.value)
        } else {
          out.unicodeScalars.append(scalar)
        }
      }
    }
    return out + "\""
  }

  /// Dört basamağa yuvarlanır, sondaki sıfırlar atılır (0.8750 → 0.875).
  static func number(_ value: Double) -> String {
    var text = String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), min(1.0, max(0.0, value)))
    while text.hasSuffix("0") { text.removeLast() }
    if text.hasSuffix(".") { text.removeLast() }
    return text.isEmpty ? "0" : text
  }

  static func boxJson(_ b: TextBox) -> String {
    "{\"bottom\":\(number(b.bottom)),\"left\":\(number(b.left)),\"right\":\(number(b.right)),\"top\":\(number(b.top))}"
  }

  static func frame(_ name: String, _ json: String) -> String { "event: \(name)\ndata: \(json)\n\n" }

  /// Alanlar alfabetik sırada (Windows'taki SortedDictionary gibi); source ve line yalnız verildiyse yazılır.
  static func subtitleFrame(_ text: String, durationMs: Int, box: TextBox?, replaces: Bool, at: Int64,
                            source: TextBox? = nil, line: Double? = nil) -> String {
    var json = "{\"at\":\(at)"
    if let box { json += ",\"box\":" + boxJson(box) }
    json += ",\"duration\":\(durationMs)"
    if let line, line > 0 { json += ",\"line\":" + number(line) }
    if replaces { json += ",\"replace\":true" }
    if let source { json += ",\"source\":" + boxJson(source) }
    json += ",\"text\":" + jsonString(text) + "}"
    return frame("subtitle", json)
  }

  static func styleFrame(_ s: SubtitleStyle) -> String {
    frame("style",
          "{\"background\":\(min(100, max(0, s.background))),\"bold\":\(s.bold),\"bottomPercent\":\(s.bottomPercent),"
            + "\"displayMode\":\(jsonString(s.displayMode)),\"fontSize\":\(s.fontSize),\"placement\":\(jsonString(s.placement)),"
            + "\"speakerColor\":\(jsonString(speakerColorValue(s))),"
            + "\"stackPrevious\":\(s.stackPrevious),\"textColor\":\(jsonString(s.textColor))}")
  }

  /// Bilgisayar sürümüyle aynı: kapalıysa "", yazı sarıysa ad açık mavi, değilse sarı.
  static func speakerColorValue(_ s: SubtitleStyle) -> String {
    guard s.speakerColor else { return "" }
    return s.textColor == "yellow" ? "#64D2FF" : "#FFD60A"
  }

  // MARK: - Dinleme

  private func startLocked() {
    guard wanted, listener == nil else { return }
    let parameters = NWParameters.tcp
    parameters.allowLocalEndpointReuse = true
    if let tcp = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
      // Altyazı çerçeveleri küçüktür; Nagle beklemesi her satırı TV'ye geç ulaştırmasın.
      tcp.noDelay = true
      tcp.enableKeepalive = true
    }
    let created: NWListener
    do {
      created = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
    } catch {
      onLog?(0, "altyazı sunucusu açılamadı: \(error)")
      return retryLater()
    }
    listener = created
    created.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
    created.stateUpdateHandler = { [weak self, weak created] state in
      guard let self, let created, self.listener === created else { return }
      switch state {
      case .ready:
        self.ready = true
        self._boundPort = created.port?.rawValue ?? 0
        self.onLog?(2, "altyazı sunucusu dinliyor: \(self._boundPort)")
        self.onChanged?()
      case .failed(let error), .waiting(let error):
        // Port dolu, ağ değişti ya da iOS dinleyiciyi kapattı: kapatılıp birkaç saniye sonra yeniden kurulur.
        self.onLog?(1, "altyazı sunucusu düştü (\(error)); yeniden kuruluyor")
        created.cancel()
        self.listener = nil
        self.ready = false
        self._boundPort = 0
        self.onChanged?()
        self.retryLater()
      default:
        break
      }
    }
    created.start(queue: queue)
    if pingTimer == nil {
      let timer = DispatchSource.makeTimerSource(queue: queue)
      timer.schedule(deadline: .now() + pingInterval, repeating: pingInterval)
      timer.setEventHandler { [weak self] in self?.broadcastLocked(Self.pingFrame) }
      timer.resume()
      pingTimer = timer
    }
  }

  private func retryLater() {
    guard wanted, !retryScheduled else { return }
    retryScheduled = true
    queue.asyncAfter(deadline: .now() + 2) { [weak self] in
      guard let self else { return }
      self.retryScheduled = false
      self.startLocked()
    }
  }

  private func accept(_ connection: NWConnection) {
    let id = ObjectIdentifier(connection)
    pending[id] = connection
    connection.start(queue: queue)
    readHead(connection, buffer: Data())
    // İstek 10 sn içinde gelmezse bağlantı kapatılır.
    queue.asyncAfter(deadline: .now() + 10) { [weak self] in
      self?.pending.removeValue(forKey: id)?.cancel()
    }
  }

  /// Başlıkların sonuna (boş satır) kadar okur. 64 KB'yi aşan istek kapatılır.
  private func readHead(_ connection: NWConnection, buffer: Data) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, complete, error in
      guard let self else { return }
      var head = buffer
      if let data { head.append(data) }
      if let end = head.range(of: Data("\r\n\r\n".utf8)) {
        self.pending.removeValue(forKey: ObjectIdentifier(connection))
        let text = String(decoding: head[..<end.lowerBound], as: UTF8.self)
        let requestLine = text.components(separatedBy: "\r\n").first ?? ""
        self.route(connection, requestLine: requestLine)
      } else if error != nil || complete || head.count >= 65536 {
        self.pending.removeValue(forKey: ObjectIdentifier(connection))
        connection.cancel()
      } else {
        self.readHead(connection, buffer: head)
      }
    }
  }

  private func route(_ connection: NWConnection, requestLine: String) {
    let parts = requestLine.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
    let method = parts.count > 0 ? parts[0] : ""
    let target = parts.count > 1 ? parts[1] : ""
    let path = target.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
    switch (method, path) {
    case ("OPTIONS", _): respondAndClose(connection, status: "204 No Content", body: "")
    case ("GET", "/events"): openStream(connection, viewer: target.contains("viewer=obs"))
    case ("GET", "/hello"): respondAndClose(connection, status: "200 OK", body: Self.helloBody)
    case ("GET", "/obs"):
      if let page { respondPage(connection, page) } else { respondAndClose(connection, status: "404 Not Found", body: "") }
    default: respondAndClose(connection, status: "404 Not Found", body: "")
    }
  }

  /// Tarayıcıda ya da OBS'te açılan altyazı sayfası (Windows'taki /obs ile aynı dosya).
  private func respondPage(_ connection: NWConnection, _ page: Data) {
    var out = Data(("HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text/html; charset=utf-8\r\n"
      + "Cache-Control: no-cache\r\nContent-Length: \(page.count)\r\nConnection: close\r\n\r\n").utf8)
    out.append(page)
    connection.send(content: out, completion: .contentProcessed { _ in connection.cancel() })
  }

  private func respondAndClose(_ connection: NWConnection, status: String, body: String) {
    let bytes = Data(body.utf8)
    var out = Data("HTTP/1.1 \(status)\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: \(bytes.count)\r\nConnection: close\r\n\r\n".utf8)
    out.append(bytes)
    connection.send(content: out, completion: .contentProcessed { _ in connection.cancel() })
  }

  private func openStream(_ connection: NWConnection, viewer: Bool) {
    var head = "HTTP/1.1 200 OK\r\n"
      + "Content-Type: text/event-stream; charset=utf-8\r\n"
      + "Cache-Control: no-cache\r\n"
      + "Connection: keep-alive\r\n"
      + "Access-Control-Allow-Origin: *\r\n\r\n"
      + "retry: 2000\n\n"
    if let lastStyle { head += Self.styleFrame(lastStyle) }
    let client = Client(connection: connection, viewer: viewer)
    clients[ObjectIdentifier(connection)] = client
    write(client, head)
    updateCount()
    onChanged?()
    connection.stateUpdateHandler = { [weak self] state in
      switch state {
      case .failed, .cancelled: self?.remove(client)
      default: break
      }
    }
    drain(client)
  }

  /// İstemciden gelen veri yok sayılır; bağlantı kapanınca listeden çıkarılır.
  private func drain(_ client: Client) {
    client.connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] _, _, complete, error in
      guard let self else { return }
      if complete || error != nil { self.remove(client) } else { self.drain(client) }
    }
  }

  private func remove(_ client: Client) {
    guard clients.removeValue(forKey: ObjectIdentifier(client.connection)) != nil else { return }
    client.connection.cancel()
    updateCount()
    onChanged?()
  }

  private func updateCount() { _connected = clients.values.filter { !$0.viewer }.count }

  private func broadcast(_ frame: String) { queue.async { self.broadcastLocked(frame) } }

  /// Gönderim hatası alan bağlantı kopmuş sayılır ve listeden çıkarılır.
  private func broadcastLocked(_ frame: String) {
    for client in clients.values { write(client, frame) }
  }

  private func write(_ client: Client, _ text: String) {
    client.connection.send(content: Data(text.utf8), completion: .contentProcessed { [weak self] error in
      guard error != nil, let self else { return }
      self.queue.async { self.remove(client) }
    })
  }
}
