// SPDX-License-Identifier: AGPL-3.0-only
import CryptoKit
import Foundation

/// Topluluk yamaları: yayıncının GitLab deposundaki patches/ klasörü (bilgisayar sürümü de buradan okur). Uygulamayı
/// yeniden derlemeden yeni ve değişen yamalar indirilir; uygulamayla gelen sürümüyle aynı olanlar inmez.
/// - Liste GitLab API'sinden alınır; her dosya Git'in blob özetiyle (SHA-1) doğrulanır, sonra paket olarak açılabildiği
///   denenir. Bozuk ya da yarım inen dosya kaydedilmez.
/// - Dosyalar Application Support/patches-community'ye yazılır; GamePackLibrary bu klasörü ek klasör olarak okur ve
///   aynı kimlikli gömülü paketin yerine koyar. Depodan kaldırılan yama telefondan da silinir.
final class CommunityPatches {
  static let shared = CommunityPatches()

  /// sefflex/GameTranslator (gitlab.com/sefflex/GameTranslator)
  static let project = "88821849"
  static let branch = "main"
  static let folderName = "patches"
  /// Kendiliğinden kontrol en çok bu sıklıkta; düğme her zaman kontrol eder.
  static let interval: TimeInterval = 7 * 24 * 3600

  struct Result {
    var added: [String] = []
    var updated: [String] = []
    var removed: [String] = []
    var failed: [String] = []
    var changed: Bool { !added.isEmpty || !updated.isEmpty || !removed.isEmpty }
  }

  let folder: URL

  /// [folder]: deneme için başka klasör; verilmezse Application Support/patches-community.
  init(folder: URL? = nil) {
    self.folder = folder ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("patches-community")
  }

  private let lock = NSLock()
  private var running = false
  private var manifestURL: URL { folder.appendingPathComponent("patches.state") }
  private let defaults = UserDefaults.standard

  var lastCheck: Date? { defaults.object(forKey: "communityPatchesLastCheck") as? Date }


  /// Kontrol eder ve indirir (bloklar). [force] değilse son kontrolden bu yana bir hafta geçmediyse hiçbir şey yapmaz.
  func update(force: Bool, log: (Int, String) -> Void) throws -> Result? {
    lock.lock()
    if running { lock.unlock(); return nil }
    running = true
    lock.unlock()
    defer { lock.lock(); running = false; lock.unlock() }

    if !force, let last = lastCheck, Date().timeIntervalSince(last) < Self.interval { return nil }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    let remote = try listRemote()
    let bundled = Self.bundledHashes()
    var manifest = loadManifest()
    var result = Result()

    for (name, sha) in remote {
      let file = folder.appendingPathComponent(name)
      let present = FileManager.default.fileExists(atPath: file.path)
      // Uygulamayla gelen sürümle aynıysa indirilmez; eski bir indirme varsa silinir (gömülü olan kullanılsın).
      if bundled[name] == sha {
        if present {
          try? FileManager.default.removeItem(at: file)
          manifest[name] = nil
        }
        continue
      }
      if present, manifest[name] == sha { continue }
      do {
        let data = try download(name)
        guard Self.blobSha1(data) == sha else { throw PatchError("özet tutmadı") }
        // Paket olarak açılabiliyor mu: açılamayan dosya kitaplığa hiç girmesin.
        _ = try GamePack.decode(data, GamePackLibrary.baseName(name))
        let temporary = folder.appendingPathComponent(name + ".download")
        try data.write(to: temporary, options: .atomic)
        if present { try? FileManager.default.removeItem(at: file) }
        try FileManager.default.moveItem(at: temporary, to: file)
        manifest[name] = sha
        if present || bundled[name] != nil { result.updated.append(name) } else { result.added.append(name) }
      } catch {
        log(1, "topluluk yaması inemedi: \(name) (\(error))")
        result.failed.append(name)
      }
    }
    // Depodan kaldırılanlar.
    for name in manifest.keys where remote[name] == nil {
      try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
      manifest[name] = nil
      result.removed.append(name)
    }
    saveManifest(manifest)
    if result.failed.isEmpty { defaults.set(Date(), forKey: "communityPatchesLastCheck") }
    log(2, "topluluk yamaları: \(result.added.count) yeni, \(result.updated.count) güncellendi, \(result.removed.count) kaldırıldı")
    return result
  }

  // MARK: - GitLab

  struct PatchError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
  }

  /// patches/ klasöründeki .json dosyaları: ad → Git blob özeti.
  private func listRemote() throws -> [String: String] {
    var result: [String: String] = [:]
    var page = 1
    while page <= 10 {
      let path = "https://gitlab.com/api/v4/projects/\(Self.project)/repository/tree?path=\(Self.folderName)&ref=\(Self.branch)&per_page=100&page=\(page)"
      let (status, data) = try get(path, timeout: 20)
      guard status == 200, let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        throw PatchError("liste alınamadı (HTTP \(status))")
      }
      for item in items {
        guard item["type"] as? String == "blob", let name = item["name"] as? String, let sha = item["id"] as? String,
              name.hasSuffix(".json"), !name.contains("/") else { continue }
        result[name] = sha.lowercased()
      }
      if items.count < 100 { break }
      page += 1
    }
    return result
  }

  private func download(_ name: String) throws -> Data {
    let encoded = "\(Self.folderName)/\(name)".addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._"))) ?? name
    let (status, data) = try get("https://gitlab.com/api/v4/projects/\(Self.project)/repository/files/\(encoded)/raw?ref=\(Self.branch)", timeout: 120)
    guard status == 200 else { throw PatchError("HTTP \(status)") }
    return data
  }

  private func get(_ text: String, timeout: TimeInterval) throws -> (Int, Data) {
    guard let url = URL(string: text) else { throw PatchError("adres") }
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
    let semaphore = DispatchSemaphore(value: 0)
    var result: (Int, Data)?
    var failure: Error?
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let data, let http = response as? HTTPURLResponse { result = (http.statusCode, data) } else { failure = error }
      semaphore.signal()
    }
    task.resume()
    if semaphore.wait(timeout: .now() + timeout + 5) == .timedOut {
      task.cancel()
      throw PatchError("zaman aşımı")
    }
    if let result { return result }
    throw PatchError(failure.map { "\($0.localizedDescription)" } ?? "bağlantı yok")
  }

  // MARK: - Özetler

  /// Git'in blob özeti: SHA-1("blob <boyut>\0" + içerik). GitLab listesindeki "id" budur.
  static func blobSha1(_ data: Data) -> String {
    var hasher = Insecure.SHA1()
    hasher.update(data: Data("blob \(data.count)\0".utf8))
    hasher.update(data: data)
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  /// Derlemede yazılan liste (packs/patches-sha1.txt): uygulamayla gelen patches/ dosyalarının blob özetleri.
  static func bundledHashes() -> [String: String] {
    guard let url = Bundle.main.url(forResource: "packs", withExtension: nil)?.appendingPathComponent("patches-sha1.txt"),
          let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
    var result: [String: String] = [:]
    for line in text.split(separator: "\n") {
      let parts = line.split(separator: " ", maxSplits: 1)
      if parts.count == 2 { result[String(parts[1])] = String(parts[0]).lowercased() }
    }
    return result
  }

  private func loadManifest() -> [String: String] {
    guard let data = try? Data(contentsOf: manifestURL),
          let map = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return [:] }
    return map
  }

  private func saveManifest(_ map: [String: String]) {
    if let data = try? JSONSerialization.data(withJSONObject: map, options: [.sortedKeys]) {
      try? data.write(to: manifestURL, options: .atomic)
    }
  }
}
