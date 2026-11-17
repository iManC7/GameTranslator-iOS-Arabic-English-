// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Android'deki core/PackStore.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import CryptoKit
import Foundation

/// Sunucudaki bir paket (GET /v1/packs).
struct RemotePack: Equatable, Sendable {
  let id: String
  let title: String
  let version: Int64
  let sha256: String
  let size: Int64
  let entries: Int
}

/// Paket indirilemedi; [status] HTTP kodu (429: sınır aşıldı), ağ hatasında null.
struct PackDownloadException: Error, CustomStringConvertible {
  let status: Int?
  let message: String
  init(_ status: Int?, _ message: String) {
    self.status = status
    self.message = message
  }
  var description: String { "PackDownloadException(\(status.map(String.init) ?? "nil")): \(message)" }
}

/// Paket deposuna yazılamadı (Kotlin'deki `IOException("cannot store …")`).
struct PackStoreException: Error, CustomStringConvertible {
  let message: String
  var description: String { "PackStoreException: \(message)" }
}

/// Paket sunucusu (gerçeği [HttpPackServer]; testlerde sahtesi). Bloklayan çağrılar.
protocol PackServer {
  func list() throws -> [RemotePack]
  func download(_ id: String) throws -> Data
}

/// Sunucudaki yeni ve güncellenen oyun paketleri (ücretsiz, hesapsız): sunucudan indirilir, SHA-256 ile doğrulanıp
/// uygulamanın klasöründe saklanır, haftada bir yenilenir. Sürümü değişmeyen paket yeniden indirilmez; sunucudan kalkan
/// paket silinir. Bozuk ya da yarım dosya hiçbir zaman yüklenmez (önce geçici dosyaya yazılır, doğrulanınca yerine
/// konur). Uygulamayla gelen paketlerle aynı kimlikteki indirilmiş paket onların yerine geçer (bkz. GamePackLibrary).
///
/// [bundledHashes]: uygulamayla gelen paket dosyalarının SHA-256'ları (küçük harf hex). Sunucudaki paket bunlardan
/// biriyle aynıysa indirilmez; yalnız gerekince ve yenileme başına bir kez hesaplanır.
final class PackStore: @unchecked Sendable {
  static let REFRESH_INTERVAL_MS: Int64 = 7 * 24 * 60 * 60 * 1000
  /// CouchSubs'ın paket sunucusu (yazarının izniyle; aynı paket biçimi).
  static let DEFAULT_URL = "https://couchsubs-packs.enmera.workers.dev"
  private static let MANIFEST = "packs.state"

  static func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  static func currentTimeMillis() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)) }

  /// [bundled]: sunucudaki sürüm uygulamayla gelenle aynı; dosyası yok.
  struct Local: Equatable, Sendable {
    let id: String
    let title: String
    let version: Int64
    let sha256: String
    let bundled: Bool

    init(_ id: String, _ title: String, _ version: Int64, _ sha256: String, bundled: Bool = false) {
      self.id = id
      self.title = title
      self.version = version
      self.sha256 = sha256
      self.bundled = bundled
    }
  }

  /// Yenilemenin sonucu: indirilen ve silinen paketler; [skipped] true ise süresi gelmediği için bakılmadı.
  struct Refresh: Equatable, Sendable {
    var downloaded: [String] = []
    var removed: [String] = []
    var skipped = false
  }

  private let directory: URL
  private let server: PackServer
  private let clock: () -> Int64
  private let bundledHashes: () throws -> Set<String>
  private let lock = NSRecursiveLock()

  init(directory: URL, server: PackServer, clock: @escaping () -> Int64 = PackStore.currentTimeMillis,
       bundledHashes: @escaping () throws -> Set<String> = { [] }) {
    self.directory = directory
    self.server = server
    self.clock = clock
    self.bundledHashes = bundledHashes
  }

  /// Uygulama paketindeki `packs-sha256.txt` biçimi ("<sha256> <dosya>" satırları; Android'deki copyGamePacks yazar).
  static func parseHashes(_ text: String) -> Set<String> {
    var hashes = Set<String>()
    for line in text.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r" }) {
      let hash = KotlinText.trim(String(line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""))
        .lowercased()
      if hash.utf16.count == 64 { hashes.insert(hash) }
    }
    return hashes
  }

  /// Klasör (GamePackLibrary'nin kullanıcı klasörü olarak verilir).
  var folder: URL { directory }

  /// Doğrulanmış, yüklenmeye hazır paket dosyaları.
  func files() -> [URL] {
    lock.lock()
    defer { lock.unlock() }
    return manifest().packs.filter { !$0.bundled }.compactMap { local in
      let file = packFile(local.id)
      return isFile(file) ? file : nil
    }
  }

  func installed() -> [Local] {
    lock.lock()
    defer { lock.unlock() }
    return manifest().packs.filter { !$0.bundled }
  }

  var lastCheck: Int64 {
    lock.lock()
    defer { lock.unlock() }
    return manifest().checked
  }

  /// Süresi geldiyse (ya da [force]) sunucuya bakar ve değişen paketleri indirir (bloklar; ana iş parçacığında
  /// çağrılmamalı). Liste alınamazsa hata fırlatır, elde olanlar kalır; inemeyen paket bir sonraki açılışta yeniden denenir.
  func refresh(force: Bool = false) throws -> Refresh {
    lock.lock()
    defer { lock.unlock() }
    let (checked, current) = manifest()
    if !force && !current.isEmpty && clock() - checked < PackStore.REFRESH_INTERVAL_MS { return Refresh(skipped: true) }
    let remote = try server.list()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var kept: [Local] = []
    var downloaded: [String] = []
    var bundled: Set<String>?
    func same(_ a: String, _ b: String) -> Bool { a.lowercased() == b.lowercased() }
    for pack in remote {
      let existing = current.first { $0.id == pack.id }
      let file = packFile(pack.id)
      if let existing = existing, existing.bundled, existing.version == pack.version, same(existing.sha256, pack.sha256) {
        kept.append(existing)
        continue
      }
      if let existing = existing, !existing.bundled, existing.version == pack.version, same(existing.sha256, pack.sha256),
         isFile(file), let bytes = try? Data(contentsOf: file), same(PackStore.sha256(bytes), pack.sha256) {
        kept.append(existing)
        continue
      }
      // Uygulamayla gelen paketin aynısı indirilmez.
      let inApp: Set<String>
      if let known = bundled {
        inApp = known
      } else {
        inApp = (try? bundledHashes()) ?? []
        bundled = inApp
      }
      if inApp.contains(pack.sha256.lowercased()) {
        try? FileManager.default.removeItem(at: file)
        kept.append(Local(pack.id, pack.title, pack.version, pack.sha256.lowercased(), bundled: true))
        continue
      }
      let keepOld = { () -> Void in
        if let existing = existing, !existing.bundled, self.isFile(file) {
          kept.append(Local(existing.id, existing.title, -1, existing.sha256, bundled: existing.bundled))
        }
      }
      let data: Data
      do {
        data = try server.download(pack.id)
      } catch is PackDownloadException {
        // Bu paket şimdi inmedi: eski sürümü varsa o kalır, sonraki yenilemede yeniden denenir.
        keepOld()
        continue
      }
      if !same(PackStore.sha256(data), pack.sha256) {
        keepOld()
        continue
      }
      let temporary = directory.appendingPathComponent("\(pack.id).download")
      try data.write(to: temporary)
      if !move(temporary, file) {
        try? FileManager.default.removeItem(at: file)
        if !move(temporary, file) { throw PackStoreException(message: "cannot store \(pack.id)") }
      }
      kept.append(Local(pack.id, pack.title, pack.version, pack.sha256.lowercased()))
      downloaded.append(pack.id)
    }
    let removed = current.filter { local in !local.bundled && !remote.contains { $0.id == local.id } }.map { $0.id }
    for id in removed { try? FileManager.default.removeItem(at: packFile(id)) }
    // Bir paket inemediyse (sürüm -1) bir sonraki açılışta yeniden denensin diye kontrol zamanı ilerletilmez.
    let retry = kept.contains { $0.version == -1 }
    try writeManifest(retry ? checked : clock(), kept)
    return Refresh(downloaded: downloaded, removed: removed)
  }

  /// "İndirilen paketleri sil" (Java File.delete gibi: dosyalar ve boş klasörler).
  func clear() {
    lock.lock()
    defer { lock.unlock() }
    let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
    for name in names { _ = remove(directory.appendingPathComponent(name).path) }
  }

  private func packFile(_ id: String) -> URL { directory.appendingPathComponent("\(id).json.gz") }

  private func isFile(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
  }

  /// Java File.renameTo (POSIX rename: hedef varsa üzerine yazar).
  private func move(_ from: URL, _ to: URL) -> Bool { rename(from.path, to.path) == 0 }

  private func manifest() -> (checked: Int64, packs: [Local]) {
    let file = directory.appendingPathComponent(PackStore.MANIFEST)
    guard isFile(file), let data = try? Data(contentsOf: file),
          let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return (0, []) }
    var list: [Local] = []
    for item in (json["packs"] as? [Any]) ?? [] {
      guard let object = item as? [String: Any] else { continue }
      // org.json getString: alan dize olmalı; yoksa bütün durum dosyası geçersiz sayılır.
      guard let id = object["id"] as? String else { return (0, []) }
      list.append(Local(id, JSON.optString(object["title"]) ?? id, JSON.optLong(object["version"]),
                        JSON.optString(object["sha256"]) ?? "", bundled: JSON.optBoolean(object["bundled"])))
    }
    return (JSON.optLong(json["checked"]), list)
  }

  private func writeManifest(_ checked: Int64, _ packs: [Local]) throws {
    let json: [String: Any] = [
      "checked": NSNumber(value: checked),
      "packs": packs.map { pack -> [String: Any] in
        ["id": pack.id, "title": pack.title, "version": NSNumber(value: pack.version), "sha256": pack.sha256,
         "bundled": pack.bundled]
      },
    ]
    let data = try JSONSerialization.data(withJSONObject: json)
    let temporary = directory.appendingPathComponent("\(PackStore.MANIFEST).tmp")
    try data.write(to: temporary)
    let target = directory.appendingPathComponent(PackStore.MANIFEST)
    if !move(temporary, target) {
      try? FileManager.default.removeItem(at: target)
      _ = move(temporary, target)
    }
  }

  /// org.json'un opt… dönüşümleri (yalnız burada gereken kadarı).
  fileprivate enum JSON {
    static func optString(_ value: Any?) -> String? {
      switch value {
      case nil, is NSNull: return nil
      case let string as String: return string
      case let number as NSNumber: return number.stringValue
      case let other?: return "\(other)"
      }
    }

    static func optLong(_ value: Any?) -> Int64 {
      switch value {
      case let number as NSNumber:
        let double = number.doubleValue
        return double == double.rounded(.towardZero) ? number.int64Value : Int64(double)
      case let string as String: return Int64(string) ?? Double(string).map { Int64($0) } ?? 0
      default: return 0
      }
    }

    static func optInt(_ value: Any?) -> Int { Int(truncatingIfNeeded: optLong(value)) }

    static func optBoolean(_ value: Any?) -> Bool {
      switch value {
      case let string as String: return string.lowercased() == "true"
      case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID(): return number.boolValue
      default: return false
      }
    }
  }
}

/// Paket sunucusu: GET /v1/packs (liste), GET /v1/packs/{id} (gzip'li paket). URLSession ile, bloklayarak (çağıran
/// iş parçacığı yanıtı bekler; ana iş parçacığından çağrılmamalı).
final class HttpPackServer: PackServer, @unchecked Sendable {
  private let baseUrl: String
  private let session: URLSession

  init(_ baseUrl: String = PackStore.DEFAULT_URL) {
    self.baseUrl = baseUrl
    let configuration = URLSessionConfiguration.ephemeral
    // HttpURLConnection: bağlantı 15 sn, okuma 60 sn. URLSession bağlantıyı ayrı sınırlamaz; istek başına boşta kalma
    // süresi 60 sn, bütün indirme en çok 10 dk.
    configuration.timeoutIntervalForRequest = 60
    configuration.timeoutIntervalForResource = 600
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    session = URLSession(configuration: configuration)
  }

  func list() throws -> [RemotePack] {
    let body = try request("\(baseUrl)/v1/packs")
    // org.json gibi: kök nesne değilse hata, "packs" yoksa boş liste, öğede "id"/"sha256" dize değilse hata.
    guard let root = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] else {
      throw PackDownloadException(nil, "invalid pack list")
    }
    guard let packs = root["packs"] as? [Any] else { return [] }
    typealias JSON = PackStore.JSON
    return try packs.map { item in
      guard let object = item as? [String: Any], let id = object["id"] as? String, let sha = object["sha256"] as? String else {
        throw PackDownloadException(nil, "invalid pack list")
      }
      return RemotePack(id: id, title: JSON.optString(object["title"]) ?? "", version: JSON.optLong(object["version"]),
                        sha256: sha, size: JSON.optLong(object["size"]), entries: JSON.optInt(object["entries"]))
    }
  }

  func download(_ id: String) throws -> Data { try request("\(baseUrl)/v1/packs/\(id)") }

  private final class Box: @unchecked Sendable {
    var data: Data?
    var response: URLResponse?
    var error: Error?
  }

  private func request(_ url: String) throws -> Data {
    guard let target = URL(string: url) else { throw PackDownloadException(nil, "bad url") }
    let box = Box()
    let done = DispatchSemaphore(value: 0)
    let task = session.dataTask(with: target) { data, response, error in
      box.data = data
      box.response = response
      box.error = error
      done.signal()
    }
    task.resume()
    done.wait()
    if let error = box.error { throw PackDownloadException(nil, error.localizedDescription) }
    guard let http = box.response as? HTTPURLResponse else { throw PackDownloadException(nil, "network") }
    if !(200...299).contains(http.statusCode) { throw PackDownloadException(http.statusCode, "HTTP \(http.statusCode)") }
    return box.data ?? Data()
  }
}
