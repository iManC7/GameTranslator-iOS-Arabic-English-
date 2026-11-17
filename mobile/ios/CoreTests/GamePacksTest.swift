// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/GamePacksTest.kt'nin Swift portu (CouchSubs'tan uyarlanan denemeler); onunla birebir aynı
// tutulmalıdır. Deneme dosyaları GT_FIXTURES_DIR'den (Android'deki src/test/resources/fixtures), gömülü paketler
// GT_PACKS_DIR'den (windows/src/GameTranslator.Core/Resources/packs) okunur; run.sh ikisini de ayarlar.
import Foundation

/// Mac ve Windows'la ortak deneme dosyaları.
enum Fixtures {
  static var directory: URL {
    guard let path = ProcessInfo.processInfo.environment["GT_FIXTURES_DIR"] else {
      fatalError("GT_FIXTURES_DIR ayarlı değil (run.sh ayarlar)")
    }
    return URL(fileURLWithPath: path)
  }

  static func bytes(_ name: String) -> Data {
    guard let data = try? Data(contentsOf: directory.appendingPathComponent(name)) else { fatalError("deneme dosyası yok: \(name)") }
    return data
  }

  static func text(_ name: String) -> String { String(decoding: bytes(name), as: UTF8.self) }

  static func json(_ name: String) -> Any { try! JSONSerialization.jsonObject(with: bytes(name)) }
}

/// Kotlin'deki `System.getProperty("gametranslator.packs")`: ayarlı değilse gömülü paket denemeleri atlanır.
enum EmbeddedPacks {
  static var directory: URL? {
    ProcessInfo.processInfo.environment["GT_PACKS_DIR"].map { URL(fileURLWithPath: $0) }
  }

  static func file(_ name: String) -> URL { directory!.appendingPathComponent(name) }

  /// Yalnız tek paketle kitaplık.
  static func library(_ name: String) -> GamePackLibrary {
    let url = file(name)
    return GamePackLibrary(bundled: { [(name: name, read: { try Data(contentsOf: url) })] }, userDirectory: nil)
  }
}

func temporaryDirectory(_ prefix: String) -> URL {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
  try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

/// Sürecin bellek ayak izi (phys_footprint; Xcode'daki "Memory" ve iOS'un bellek sınırıyla aynı ölçü), bayt. macOS'ta
/// bırakılan büyük bloklar önbellekte kalıp ölçüme girer; run.sh bunu MallocLargeCache=0 ile kapatır (iOS'taki gibi).
func memoryFootprint() -> Int64 {
  var info = task_vm_info_data_t()
  var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
  let result = withUnsafeMutablePointer(to: &info) { pointer in
    pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
  }
  return result == KERN_SUCCESS ? Int64(info.phys_footprint) : 0
}

struct TestIOError: Error {}

enum PackKeyTest {
  static func run() {
    /// Mac, Windows ve paket hazırlayan Python betiği (canon.py) ile aynı sonuç.
    TestRun.test("PackKeyTest.goldenVectors") {
      let vectors = Fixtures.json("golden-vectors.json") as! [[String: Any]]
      assertEquals(15, vectors.count)
      for vector in vectors {
        let input = vector["input"] as! String
        assertEquals(vector["canon"] as! String, PackKey.canon(input), input)
        assertEquals(vector["key"] as! String, PackKey.key(input) ?? "", input)
        assertEquals(PackKey.key(input).flatMap(PackKey.number), PackKey.keyNumber(input), input)
      }
    }
    TestRun.test("PackKeyTest.tagsLongerThanFortyCharactersStay") {
      assertEquals("a   c", PackKey.stripTags("a <b> c"))
      let tooLong = "<" + String(repeating: "x", count: 41) + ">"
      assertEquals(tooLong, PackKey.stripTags(tooLong))
      assertEquals(" ", PackKey.stripTags("<" + String(repeating: "x", count: 40) + ">"))
      assertEquals("a < b   c", PackKey.stripTags("a < b <i> c"))
      assertEquals("< >", PackKey.stripTags("<<b>>"))
    }
    TestRun.test("PackKeyTest.numberRoundTripsUnsignedKeys") {
      assertEquals(Int64(-1), PackKey.number("ffffffffffffffff"))
      assertNull(PackKey.number("xyz"))
      assertNull(PackKey.number("0123"))
    }
  }
}

enum GamePackTest {
  private static func load(_ name: String) throws -> GamePack {
    try GamePack.decode(Fixtures.bytes(name), String(name.dropLast(".json.gz".count)))
  }

  private static func data(_ s: String) -> Data { Data(s.utf8) }

  static func run() {
    TestRun.test("GamePackTest.wrappedAndBareFormatsLoad") {
      let wrapped = try load("pack-wrapped.json.gz")
      assertEquals("test-game", wrapped.id)
      assertEquals("Test Game", wrapped.title)
      assertEquals(5, wrapped.size)
      let bare = try load("pack-bare.json.gz")
      assertEquals("pack-bare", bare.id)
      assertEquals("pack-bare", bare.title)
      assertEquals(2, bare.size)
    }
    TestRun.test("GamePackTest.plainJsonIsAccepted") {
      let key = PackKey.key("Get back!")!
      let pack = try GamePack.decode(data("{\"\(key)\": \"Geri çekil!\"}"), "plain")
      assertEquals("Geri çekil!", pack[PackKey.number(key)!])
    }
    TestRun.test("GamePackTest.brokenFilesAreRejected") {
      assertThrows(InvalidPackException.self) { try GamePack.decode(data("not json"), "x") }
      assertThrows(InvalidPackException.self) {
        try GamePack.decode(Data([0x1f, 0x8b, 8, 0] + [UInt8](repeating: 7, count: 30)), "x")
      }
      assertThrows(InvalidPackException.self) {
        try GamePack.decode(data("{\"format\":3,\"entries\":{\"0123456789abcdef\":\"x\"}}"), "x")
      }
      assertThrows(InvalidPackException.self) { try GamePack.decode(data("{\"bad\":\"x\"}"), "x") }
    }
    /// Elle seçilen oyun (yalnız iOS): yalnız o paket kullanılır, bulanık arama ilk satırdan onda.
    TestRun.test("GamePackTest.pinnedGameIsTheOnlyPack") {
      func pack(_ id: String, _ text: String) -> String {
        "{\"format\":2,\"id\":\"\(id)\",\"title\":\"\(id.uppercased())\",\"entries\":{\"\(PackKey.key("Let's go.")!)\":\"\(text)\"}}"
      }
      let a = pack("a", "Hadi gidelim."), b = pack("b", "Gidelim hadi.")
      let library = GamePackLibrary(bundled: { [(name: "a.json", read: { Data(a.utf8) }), (name: "b.json", read: { Data(b.utf8) })] },
                                    userDirectory: nil)
      // Otomatik: aynı satır iki pakette; sonra gelen kazanır.
      assertEquals("Gidelim hadi.", library.findWithPack("Let's go.")?.text)
      library.setPinned("a")
      assertEquals("Hadi gidelim.", library.findWithPack("Let's go.")?.text)
      assertEquals("A", library.scopeTitle)
      library.setPinned(nil)
      assertEquals("Gidelim hadi.", library.findWithPack("Let's go.")?.text)
    }
    /// Topluluk yaması düz biçimi (yalnız iOS): {"English line": "Türkçe"}; BOM'lu da olabilir.
    TestRun.test("GamePackTest.plainEnglishPatchesAreRead") {
      var pairs = (1...10).map { "\"Line number \($0) here\": \"Satır \($0)\"" }
      pairs.append("\"Press any button to continue\": \"Devam etmek için bir tuşa basın\"")
      let json = "\u{FEFF}{" + pairs.joined(separator: ",") + "}"
      let pack = try GamePack.decode(Data(json.utf8), "final-fantasy-vii-rebirth")
      assertEquals("Final Fantasy VII Rebirth", pack.title)
      let library = GamePackLibrary(bundled: { [(name: "final-fantasy-vii-rebirth.json", read: { Data(json.utf8) })] }, userDirectory: nil)
      assertEquals("Devam etmek için bir tuşa basın", PackTranslation.match(library, "Press any button to continue")?.text)
    }
    /// Biçim 2: tam satırlar önce, "segments" (parçalar) yalnız tam satır bulunmazsa (masaüstüyle aynı öncelik).
    TestRun.test("GamePackTest.formatTwoSegmentsAreFoundAfterWholeLines") {
      let down = PackKey.key("Get Down!")!
      let back = PackKey.key("Get back!")!
      let json = "{\"format\":2,\"id\":\"g\",\"entries\":{\"\(down)\":\"Yere yat!\"},"
        + "\"segments\":{\"\(back)\":\"Geri çekil!\",\"\(down)\":\"Eğil!\"},\"fuzzy\":{\"x\":[1,2]}}"
      assertEquals(1, try GamePack.decode(data(json), "g").size)
      let library = GamePackLibrary(bundled: { [(name: "g.json", read: { data(json) })] }, userDirectory: nil)
      assertEquals("Yere yat!", library.find("Get Down!"))
      assertEquals("Geri çekil!", library.find("Get back!"))
    }
    TestRun.test("GamePackTest.tagsAreRemovedFromTurkish") {
      let pack = try load("pack-wrapped.json.gz")
      let key = PackKey.number(PackKey.key("<b><h>SCANNATURI SPECIALE</></> KNIFE")!)!
      assertEquals("SCANNATURI SPECIALE BIÇAĞI", pack[key])
    }
    TestRun.test("GamePackTest.libraryMergesBundledAndUserPacks") {
      let user = temporaryDirectory("packs")
      defer { try? FileManager.default.removeItem(at: user) }
      let library = GamePackLibrary(bundled: {
        [
          (name: "a.json.gz", read: { Fixtures.bytes("pack-bare.json.gz") }),
          (name: "b.json.gz", read: { Fixtures.bytes("pack-wrapped.json.gz") }),
          (name: "c.json.gz", read: { data("bozuk") }),
        ]
      }, userDirectory: user)
      assertEquals(["a", "Test Game"], library.infos.map { $0.title })
      assertEquals([2, 5], library.infos.map { $0.entries })
      // Aynı anahtarda sonraki paket kazanır.
      assertEquals("Yere yat!", library.find("Get Down!"))
      assertEquals("test-game", library.findWithPack("Get Down!")?.packId)
      assertEquals("Geri çekil!", library.find("Get back!"))

      // Kullanıcının klasöründeki aynı kimlikli paket uygulamanınkinin yerine geçer.
      let key = PackKey.key("Get Down!")!
      try data("{\"format\":1,\"id\":\"test-game\",\"title\":\"Test Game 2\",\"entries\":{\"\(key)\":\"Yat yere!\"}}")
        .write(to: user.appendingPathComponent("test.json"))
      library.reload()
      assertEquals(["a", "Test Game 2"], library.infos.map { $0.title })
      assertEquals([true, false], library.infos.map { $0.builtIn })
      assertEquals("Yat yere!", library.find("Get Down!"))
      assertNull(library.find("Who is that?"))

      // Kapatılan paket aranmaz; önceki paketin çevirisi görünür.
      library.setDisabled(["test-game"])
      assertEquals("a", library.findWithPack("Get Down!")?.packId)
    }
    /// Paketteki aynı anahtarın sonraki satırı kazanır, boş satır alınmaz; çok satırlı pakette her satır bulunur.
    TestRun.test("GamePackTest.duplicateKeysKeepLastAndAllLinesAreFound") {
      let down = PackKey.key("Get Down!")!
      let lines = (0..<5000).map { "Line number \($0)" }
      let body = lines.enumerated().map { "\"\(PackKey.key($0.element)!)\":\"Satır \($0.offset)\"" }.joined(separator: ",")
      let json = "{\"format\":1,\"id\":\"g\",\"entries\":{\"\(down)\":\"Eğil!\",\(body),\"\(down)\":\"Yere yat!\",\"\(PackKey.key("Empty")!)\":\" \"}}"
      let pack = try GamePack.decode(data(json), "g")
      assertEquals(5001, pack.size)
      assertEquals("Yere yat!", pack[PackKey.number(down)!])
      assertNull(pack[PackKey.number(PackKey.key("Empty")!)!])
      for index in [0, 1, 2499, 4999] { assertEquals("Satır \(index)", pack[PackKey.number(PackKey.key(lines[index])!)!]) }
      assertNull(pack.segment(PackKey.number(down)!))
    }
    /// Uygulamayla gelen paketler ilk aramada ve teker teker okunur; okunamayan dosya atlanır.
    TestRun.test("GamePackTest.bundledPacksAreReadOneAtATime") {
      var events: [String] = []
      let wrapped = Fixtures.bytes("pack-wrapped.json.gz")
      let bare = Fixtures.bytes("pack-bare.json.gz")
      let library = GamePackLibrary(bundled: {
        events.append("liste")
        return [
          (name: "b.json.gz", read: { events.append("oku b"); return wrapped }),
          (name: "a.json.gz", read: { events.append("oku a"); return bare }),
          (name: "c.json.gz", read: { events.append("oku c"); throw TestIOError() }),
        ]
      }, userDirectory: nil)
      assertEquals([String](), events)
      assertEquals(["a", "Test Game"], library.infos.map { $0.title })
      assertEquals(["liste", "oku a", "oku b", "oku c"], events)
      assertEquals("Yere yat!", library.find("Get Down!"))
    }
    /// gzip ayrıntıları (GZIPInputStream gibi): ardışık üyeler birleşir, sondaki fazlalık yok sayılır, bozuk CRC reddedilir.
    TestRun.test("GamePackTest.gzipMembersTrailingBytesAndCrc") {
      let gz = [UInt8](Fixtures.bytes("pack-wrapped.json.gz"))
      let plain = try Gzip.decompress(Data(gz))
      assertEquals("{", String(decoding: plain.prefix(1), as: UTF8.self))
      assertEquals(plain + plain, try Gzip.decompress(Data(gz + gz)))
      assertEquals(plain, try Gzip.decompress(Data(gz + Array("trailing garbage, not gzip".utf8))))
      var broken = gz
      broken[broken.count - 6] ^= 0xff
      assertThrows(InvalidPackException.self) { try Gzip.decompress(Data(broken)) }
      assertThrows(InvalidPackException.self) { try Gzip.decompress(Data(gz.dropLast(4))) }
      assertThrows(InvalidPackException.self) { try Gzip.decompress(Data(gz.prefix(gz.count / 2))) }
      // Açılmış JSON da (Android varlıkları gibi) aynı paketi verir.
      let pack = try GamePack.decode(Data(plain), "x")
      assertEquals("test-game", pack.id)
      assertEquals(5, pack.size)
    }
    /// Uygulamayla gelen paketler (windows/src/GameTranslator.Core/Resources/packs) yüklenir ve hızlı aranır.
    TestRun.test("GamePackTest.embeddedPacksLoad") {
      guard let directory = EmbeddedPacks.directory else { return }
      let started = DispatchTime.now().uptimeNanoseconds
      let library = GamePackLibrary(bundled: { GamePackLibrary.files(in: directory) }, userDirectory: nil)
      let ids = library.infos.map { $0.id }
      let elapsedMs = (DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
      assertTrue(ids.contains("gta-v"))
      assertTrue(ids.contains("mafia-the-old-country"))
      assertTrue(elapsedMs < 10_000, "paketler \(elapsedMs) ms'de yüklendi")
      let mafia = EmbeddedPacks.library("mafia-the-old-country.json.gz")
      assertEquals("MARIA: Yere yat!", PackLookup.match(mafia, "MARIA: Get Down!")?.text)
      assertEquals("Yere yat!\nMinchia! Sana at sürmeyi yasaklamak lazım!",
                   PackLookup.match(mafia, "Get Down!\nMinchia! You shouldn't be allowed to ride!")?.text)
    }
  }
}

/// Gömülü paketlerin bellekte kalan boyu (bulanık imzalar dahil); zayıf telefonda çeviri başlarken bellek yetmeli.
enum PackMemoryTest {
  static func run() {
    TestRun.test("PackMemoryTest.embeddedPacksStaySmall") {
      guard let directory = EmbeddedPacks.directory else { return }
      let files = GamePackLibrary.files(in: directory).filter { GamePackLibrary.isPackFile($0.name) }
      let before = memoryFootprint()
      let library = GamePackLibrary(bundled: { files }, userDirectory: nil)
      let started = DispatchTime.now().uptimeNanoseconds
      assertEquals(files.count, library.infos.count)
      print("  PAKET YÜKLEME: \((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000) ms")
      let retainedMb = (memoryFootprint() - before) / (1 << 20)
      print("  PAKET BELLEK: \(retainedMb) MB (\(library.infos.count) paket, \(library.infos.reduce(0) { $0 + $1.entries }) satır)")
      assertTrue(retainedMb < 80, "paketler bellekte \(retainedMb) MB")
      assertEquals(files.count, library.infos.count)
    }
  }
}

enum PackLookupTest {
  private static let pack: [String: String] = [
    PackKey.key("Get Down!")!: "Yere yat!",
    PackKey.key("Who is that?")!: "O da kim?",
    PackKey.key("Don Torrisi wants you.")!: "Don Torrisi seni istiyor.",
    PackKey.key("Get back!")!: "Geri çekil!",
  ]

  private static func match(_ text: String) -> PackMatch? {
    PackLookup.match(text) { line in PackKey.key(line).flatMap { pack[$0] } }
  }

  static func run() {
    TestRun.test("PackLookupTest.wholeLineIgnoresCaseSpacingAndPunctuation") {
      assertEquals("Yere yat!", match("GET DOWN!!")?.text)
      assertEquals("O da kim?", match("  Who   is\nthat?  ")?.text)
      assertNull(match("Get out!"))
      assertNull(match(""))
    }
    TestRun.test("PackLookupTest.speakerLabelIsKept") {
      assertEquals("ENZO: Don Torrisi seni istiyor.", match("ENZO: Don Torrisi wants you.")?.text)
      assertEquals("Cesare: Yere yat!", match("Cesare: Get down!")?.text)
      assertNull(match("ENZO: Get out!"))
    }
    TestRun.test("PackLookupTest.eachLineIsLookedUpWhenTheWholeIsMissing") {
      assertEquals("ENZO: Yere yat!\nMARIA: O da kim?", match("ENZO: Get down!\nMARIA: Who is that?")?.text)
      assertEquals("- Yere yat!\n- O da kim?", match("- Get down!\n- Who is that?")?.text)
      assertNull(match("Get down!\nWho are you?"))
    }
    TestRun.test("PackLookupTest.eachSentenceIsLookedUpWhenTheLineIsMissing") {
      assertEquals("ENZO: Yere yat! O da kim?", match("ENZO: Get down! Who is that?")?.text)
      assertEquals("Yere yat! Geri çekil!", match("Get down! Get back!")?.text)
      assertNull(match("Get down! Who are you?"))
    }
    TestRun.test("PackLookupTest.wholeLineWinsOverParts") {
      let custom = [PackKey.key("Get down! Get back!")!: "Eğil ve geri çekil!", PackKey.key("Get Down!")!: "Yere yat!"]
      assertEquals("Eğil ve geri çekil!", PackLookup.match("Get down! Get back!") { line in PackKey.key(line).flatMap { custom[$0] } }?.text)
    }
  }
}
