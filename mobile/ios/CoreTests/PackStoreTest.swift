// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/PackStoreTest.kt'nin Swift portu (CouchSubs'tan uyarlanan denemeler); onunla birebir aynı
// tutulmalıdır.
import Foundation

enum PackStoreTest {
  final class FakeServer: PackServer {
    var packs: [RemotePack]
    var files: [String: Data]
    var downloads: [String] = []
    var status: Int?

    init(_ packs: [RemotePack], _ files: [String: Data]) {
      self.packs = packs
      self.files = files
    }

    func list() throws -> [RemotePack] { packs }

    func download(_ id: String) throws -> Data {
      if let status = status { throw PackDownloadException(status, "HTTP \(status)") }
      downloads.append(id)
      guard let data = files[id] else { throw PackDownloadException(404, "missing") }
      return data
    }
  }

  final class Clock {
    var now: Int64 = 1_000
  }

  private static func remote(_ id: String, _ data: Data, version: Int64 = 1) -> RemotePack {
    RemotePack(id: id, title: id.uppercased(), version: version, sha256: PackStore.sha256(data), size: Int64(data.count), entries: 1)
  }

  private static let gta = Data("gta".utf8)
  private static let rdr = Data("rdr".utf8)

  private static func names(_ files: [URL]) -> [String] { files.map { $0.lastPathComponent } }

  private static func text(_ url: URL) -> String { (try? String(contentsOf: url, encoding: .utf8)) ?? "" }

  private static func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

  static func run() {
    TestRun.test("PackStoreTest.downloadsVerifiesAndReusesPacks") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let clock = Clock()
      let server = FakeServer([remote("gta-v", gta), remote("rdr2", rdr)], ["gta-v": gta, "rdr2": rdr])
      let store = PackStore(directory: dir, server: server, clock: { clock.now })
      assertEquals(["gta-v", "rdr2"], try store.refresh().downloaded)
      assertEquals(Set(["gta-v.json.gz", "rdr2.json.gz"]), Set(names(store.files())))
      // Haftası dolmadan sunucuya bakılmaz.
      clock.now += 60_000
      assertTrue(try store.refresh().skipped)
      // Zorla yenilemede aynı sürüm yeniden inmez.
      assertEquals([String](), try store.refresh(force: true).downloaded)
      assertEquals(["gta-v", "rdr2"], server.downloads)
    }
    TestRun.test("PackStoreTest.weeklyRefreshUpdatesChangedAndRemovesDroppedPacks") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let clock = Clock()
      let server = FakeServer([remote("gta-v", gta), remote("rdr2", rdr)], ["gta-v": gta, "rdr2": rdr])
      let store = PackStore(directory: dir, server: server, clock: { clock.now })
      _ = try store.refresh()
      let newGta = Data("gta v2".utf8)
      server.files["gta-v"] = newGta
      server.packs = [remote("gta-v", newGta, version: 2)]
      clock.now += PackStore.REFRESH_INTERVAL_MS
      let result = try store.refresh()
      assertEquals(["gta-v"], result.downloaded)
      assertEquals(["rdr2"], result.removed)
      assertEquals("gta v2", text(dir.appendingPathComponent("gta-v.json.gz")))
      assertFalse(exists(dir.appendingPathComponent("rdr2.json.gz")))
      assertEquals(1, store.installed().count)
      assertEquals(Int64(2), store.installed().first?.version)
    }
    TestRun.test("PackStoreTest.corruptDownloadIsNeverInstalled") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let server = FakeServer([remote("gta-v", gta)], ["gta-v": Data("tampered".utf8)])
      let store = PackStore(directory: dir, server: server)
      assertEquals([String](), try store.refresh().downloaded)
      assertTrue(store.files().isEmpty)
      assertFalse(exists(dir.appendingPathComponent("gta-v.json.gz")))
      // Kontrol zamanı ilerlemez: sonraki açılışta yeniden denenir.
      server.files["gta-v"] = gta
      assertEquals(["gta-v"], try store.refresh().downloaded)
    }
    TestRun.test("PackStoreTest.rateLimitedDownloadKeepsTheOldVersionAndRetries") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let clock = Clock()
      let server = FakeServer([remote("gta-v", gta)], ["gta-v": gta])
      let store = PackStore(directory: dir, server: server, clock: { clock.now })
      _ = try store.refresh()
      let newGta = Data("gta v2".utf8)
      server.files["gta-v"] = newGta
      server.packs = [remote("gta-v", newGta, version: 2)]
      server.status = 429
      clock.now += PackStore.REFRESH_INTERVAL_MS
      assertEquals([String](), try store.refresh().downloaded)
      assertEquals("gta", text(dir.appendingPathComponent("gta-v.json.gz")))
      // Kontrol zamanı ilerlemedi: sınır kalkınca hemen yeniden denenir.
      server.status = nil
      clock.now += 1000
      assertEquals(["gta-v"], try store.refresh().downloaded)
    }
    /// Uygulamayla gelen paketin aynısı indirilmez; sunucuda sürümü değişince iner.
    TestRun.test("PackStoreTest.packsAlreadyInTheAppAreNotDownloaded") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let clock = Clock()
      var hashed = 0
      let server = FakeServer([remote("gta-v", gta), remote("rdr2", rdr)], ["gta-v": gta, "rdr2": rdr])
      let store = PackStore(directory: dir, server: server, clock: { clock.now },
                            bundledHashes: { hashed += 1; return [PackStore.sha256(gta)] })
      assertEquals(["rdr2"], try store.refresh().downloaded)
      assertEquals(["rdr2"], server.downloads)
      assertEquals(["rdr2.json.gz"], names(store.files()))
      assertEquals(["rdr2"], store.installed().map { $0.id })
      assertEquals(1, hashed)
      // Haftası dolmadan bakılmaz; dolunca aynı sürümler için uygulamadaki dosyalar yeniden özetlenmez.
      assertTrue(try store.refresh().skipped)
      clock.now += PackStore.REFRESH_INTERVAL_MS
      assertEquals([String](), try store.refresh().downloaded)
      assertEquals(1, hashed)
      let newGta = Data("gta v2".utf8)
      server.files["gta-v"] = newGta
      server.packs = [remote("gta-v", newGta, version: 2), remote("rdr2", rdr)]
      assertEquals(["gta-v"], try store.refresh(force: true).downloaded)
      assertEquals(Set(["gta-v.json.gz", "rdr2.json.gz"]), Set(names(store.files())))
    }
    TestRun.test("PackStoreTest.downloadedPacksLoadIntoTheLibrary") {
      let dir = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: dir) }
      let pack = Fixtures.bytes("pack-wrapped.json.gz")
      let store = PackStore(directory: dir, server: FakeServer([remote("test-game", pack)], ["test-game": pack]))
      _ = try store.refresh()
      let library = GamePackLibrary(bundled: nil, userDirectory: store.files().first!.deletingLastPathComponent())
      assertEquals(["test-game"], library.infos.map { $0.id })
      assertEquals("Yere yat!", library.find("Get Down!"))
    }
    /// Uygulama paketindeki packs-sha256.txt (Android'deki copyGamePacks biçimi) okunur. (Yalnız Swift'te.)
    TestRun.test("PackStoreTest.bundledHashFileIsParsed") {
      let hash = PackStore.sha256(gta)
      let parsed = PackStore.parseHashes("\(hash.uppercased()) gta-v.json.gz\nkisa x\n\n\(PackStore.sha256(rdr)) rdr2.json.gz\n")
      assertEquals(Set([hash, PackStore.sha256(rdr)]), parsed)
    }
  }
}
