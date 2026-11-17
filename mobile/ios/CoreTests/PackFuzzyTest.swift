// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/PackFuzzyTest.kt'nin Swift portu (CouchSubs'tan uyarlanan denemeler); onunla birebir aynı
// tutulmalıdır.
import Foundation

private func optionalString(_ value: Any?) -> String? { value is NSNull ? nil : value as? String }

/// Mac'teki PackLookupTests'in OCR'a dayanıklı arama denemeleri.
enum PackLookupFuzzyTest {
  private static let pack: [String: String] = [
    PackKey.key("Get Down!")!: "Yere yat!",
    PackKey.key("Who is that?")!: "O da kim?",
    PackKey.key("Don Torrisi wants you.")!: "Don Torrisi seni istiyor.",
    PackKey.key("Get back!")!: "Geri çekil!",
  ]

  private static func find(_ line: String) -> String? { PackKey.key(line).flatMap { pack[$0] } }
  private static func match(_ text: String) -> PackMatch? { PackLookup.match(text) { find($0) } }

  static func run() {
    /// OCR'ın bozduğu etiket ("-GAETANO:", "M]:", "li LUCA:") da atılıp aranır; ekranda olduğu gibi kalır.
    TestRun.test("PackLookupFuzzyTest.garbledSpeakerLabelIsStripped") {
      assertEquals("- GAETANO: Don Torrisi seni istiyor.", match("-GAETANO: Don Torrisi wants you.")?.text)
      assertEquals("- GAETANO: Don Torrisi seni istiyor.", match("- GAETANO: Don Torrisi wants you.")?.text)
      assertEquals("M]: Yere yat!", match("M]: Get down!")?.text)
      assertEquals("li LUCA: O da kim?", match("li LUCA: Who is that?")?.text)
      assertEquals("SEBASTIAN O da kim?", match("SEBASTIAN Who is that?")?.text)
      assertNull(match("I told you: get out!"))
    }
    /// Paket betiğiyle aynı gevşek etiket kuralı (fuzzy-vectors.json).
    TestRun.test("PackLookupFuzzyTest.looseLabelVectors") {
      let vectors = (Fixtures.json("fuzzy-vectors.json") as! [String: Any])["looseLabels"] as! [[String: Any]]
      assertTrue(vectors.count > 5)
      for vector in vectors {
        let input = vector["input"] as! String
        let found = PackLookup.looseLabel(input)
        assertEquals(optionalString(vector["label"]), found?.0, input)
        assertEquals(optionalString(vector["body"]), found?.1, input)
      }
    }
    /// Tam anahtar tutmazsa her parça önce tam, sonra bulanık aranır; tam satır her zaman önce gelir.
    TestRun.test("PackLookupFuzzyTest.nearestIsTriedOnlyAfterExactParts") {
      var asked: [String] = []
      let nearest = { (line: String) -> String? in
        asked.append(line)
        return line == "Who iz that?" ? "O da kim?" : nil
      }
      assertEquals("ENZO: Yere yat! O da kim?", PackLookup.match("ENZO: Get down! Who iz that?", nearest) { find($0) }?.text)
      assertEquals("Yere yat!", PackLookup.match("GET DOWN!!", { _ in "x" }) { find($0) }?.text)
      assertFalse(asked.contains("Get down!"))
    }
    /// Altyazının bloğuna düşen köşe yazısı (GTA V'te bölge adı, kamera ipucu) atlanır; tek başına eşleşme sayılmaz.
    TestRun.test("PackLookupFuzzyTest.overlayLineNextToTheSubtitleIsSkipped") {
      assertEquals("O da kim?", match("San Andreas\nWho is that?")?.text)
      assertEquals("Yere yat!", match("Get down!\nFirst Person • zoom")?.text)
      assertEquals("Yere yat!\nO da kim?", match("Get down!\nMirror Park\nWho is that?")?.text)
      assertNull(match("San Andreas\nMirror Park"))
      assertNull(match("Get down!\nwho are you"))
      assertTrue(PackLookup.isOverlay("LOSNN"))
      assertFalse(PackLookup.isOverlay("Listen to me,"))
      assertFalse(PackLookup.isOverlay("Hey, Franklin!"))
    }
  }
}

enum PackFuzzyTest {
  private static var directory: URL? { EmbeddedPacks.directory }

  private static func library(_ file: String) -> GamePackLibrary { EmbeddedPacks.library(file) }

  static func run() {
    /// İmza Mac, Windows ve paket betiğiyle bit bit aynı.
    TestRun.test("PackFuzzyTest.signatureVectors") {
      let vectors = Fixtures.json("fuzzy-vectors.json") as! [String: Any]
      let signatures = vectors["signatures"] as! [[String: Any]]
      assertTrue(signatures.count > 10)
      for vector in signatures {
        let input = vector["input"] as! String
        assertEquals(vector["folded"] as! String, KotlinText.string(codePoints: PackFuzzy.folded(input)), input)
        assertEquals((vector["damaged"] as! NSNumber).boolValue, PackFuzzy.damaged(input), input)
        let signature = PackFuzzy.signature(input)
        if vector["length"] is NSNull {
          assertTrue(signature == nil, input)
          continue
        }
        guard let (length, bloom) = signature else {
          TestRun.fail("imza yok: \(input)", #fileID, #line)
          continue
        }
        assertEquals((vector["length"] as! NSNumber).intValue, length, input)
        assertEquals((vector["bits"] as! NSNumber).intValue, PackFuzzy.bits(length), input)
        assertEquals(vector["bloom"] as! String, bloom.map { String(format: "%02x", $0) }.joined(), input)
      }
      for pair in vectors["similarities"] as! [[String: Any]] {
        let bits = (pair["bits"] as! NSNumber).intValue
        let query = PackFuzzy.bloom(PackFuzzy.trigramHashes(PackFuzzy.folded(pair["query"] as! String)), bits)
        let entry = PackFuzzy.bloom(PackFuzzy.trigramHashes(PackFuzzy.folded(pair["entry"] as! String)), bits)
        assertEquals((pair["similarity"] as! NSNumber).doubleValue, PackFuzzy.similarity(query, entry, 0, bits),
                     accuracy: 1e-9, pair["query"] as! String)
      }
    }
    /// Tek OCR düzeltmesi: karışan harf, düşen harf, yutulan boşluk ya da kesme işareti; kısa ve uzun satırda yok.
    TestRun.test("PackFuzzyTest.variantsAreSingleCorrections") {
      let variants = PackFuzzy.variants("Somebody help rne!")
      assertTrue(variants.contains("somebody help me"))
      assertTrue(PackFuzzy.variants("You cant put a price").contains("you can t put a price"))
      assertTrue(PackFuzzy.variants("Yeah, well, well see.").contains("yeah well we ll see"))
      assertFalse(variants.contains("somebody help rne"))
      assertTrue(!variants.contains { $0.hasPrefix(" ") || $0.hasSuffix(" ") || $0.contains("  ") })
      assertTrue(PackFuzzy.variants("Hey").isEmpty)
      assertTrue(PackFuzzy.variants(String(repeating: "x", count: 49)).isEmpty)
    }
    /// Kullanıcılardan gelen gerçek ıskalamalar (Mafia: The Old Country): paket betiğiyle aynı Türkçe ya da hiç eşleşme.
    TestRun.test("PackFuzzyTest.realOcrMissesMatchLikeThePackScript") {
      guard directory != nil else { return }
      let fixtures = Fixtures.json("pack-matches.json") as! [String: Any]
      let cases = fixtures["cases"] as! [[String: Any]]
      assertTrue(cases.count >= 50)
      let library = library("mafia-the-old-country.json.gz")
      assertNull(library.searchScope)
      assertNotNull(PackLookup.match(library, fixtures["warmUp"] as! String))
      assertEquals("mafia-the-old-country", library.searchScope)
      let started = DispatchTime.now().uptimeNanoseconds
      for item in cases {
        let screen = item["screen"] as! String
        assertEquals(optionalString(item["turkish"]), PackLookup.match(library, screen)?.text, screen)
      }
      let perLine = Double(DispatchTime.now().uptimeNanoseconds - started) / 1e6 / Double(cases.count)
      print("  Mafia bulanık arama: satır başına \(String(format: "%.2f", perLine)) ms")
    }
    /// Hiç tam eşleşme olmadan bulanık arama yapılmaz (hangi oyunun oynandığı belli değil).
    TestRun.test("PackFuzzyTest.noFuzzySearchBeforeTheGameIsKnown") {
      guard directory != nil else { return }
      let library = library("mafia-the-old-country.json.gz")
      let garbled = "GAETANO: All this will bébehind u soon: Uötil'then don't let any of these båétards getpyou, alrightiz:t"
      assertNull(PackLookup.match(library, garbled))
      assertNull(library.scopeTitle)
      assertNotNull(PackLookup.match(library, "You fucked up now, boy!"))
      assertEquals("Mafia: The Old Country", library.scopeTitle)
      let clean = PackLookup.match(library, "All this will be behind us soon. Until then don’t let any of these bastards get to you, alright?")?.text
      assertEquals("GAETANO: \(clean ?? "nil")", PackLookup.match(library, garbled)?.text)
      assertEquals("mafia-the-old-country", PackLookup.match(library, garbled)?.packId)
    }
    /// Biçim 2: oyunun ayrı gösterdiği parçalar ve imzalar.
    TestRun.test("PackFuzzyTest.versionTwoSegmentsAndSignaturesLoad") {
      guard directory != nil else { return }
      let library = library("mafia-the-old-country.json.gz")
      assertNotNull(PackLookup.match(library, "Che buono."))
      assertEquals("ENZO: Che buono.", PackLookup.match(library, "ENZO: Che buono.")?.text)
      assertNotNull(PackLookup.match(library, "then clear the way for someone who does."))
      let pack = try GamePack.decode(Data(contentsOf: EmbeddedPacks.file("mafia-the-old-country.json.gz")), "mafia-the-old-country")
      assertTrue((pack.fuzzy?.count ?? 0) > 20000)
    }
    /// GTA V oyuncularının gerçek ıskalamaları: kısa satırda tek harf hatası, yutulmuş kesme işareti, köşe yazısı, iki
    /// satırlık altyazının yalnız bir satırı ve başına çöp eklenmiş okuma da paketten bulunur.
    TestRun.test("PackFuzzyTest.gtaOcrReadsAreFound") {
      guard directory != nil else { return }
      let library = library("gta-v.json.gz")
      assertNotNull(PackLookup.match(library, "Are you listening to me?"))
      func same(_ screen: String, _ line: String, file: String = #fileID, lineNumber: Int = #line) {
        let expected = PackLookup.match(library, line)?.text
        assertNotNull(expected, line, file: file, line: lineNumber)
        assertEquals(expected, PackLookup.match(library, screen)?.text, screen, file: file, line: lineNumber)
      }
      same("Somebody help rne!", "Somebody help me!")
      same("Yeah, well, well see.", "Yeah, well, we'll see.")
      same("You cant put a price on freedom.", "You can't put a price on freedom.")
      same("LOSNN\nI told him to leave it, Trevor.", "I told him to leave it, Trevor.")
      same("I can't do crap with this deathship right", "I can't do crap with this deathship right on top of me! Bring it down, T!")
      same("San Andreas LOSNN but it does mean he's got money to pay people who help him.",
           "but it does mean he's got money to pay people who help him.")
      assertNull(PackLookup.match(library, "The quick brown fox jumps over the lazy dog near the river bank."))
      assertNull(PackLookup.match(library, "Sauvage gentleman of the western plains"))
    }
    /// İki altyazı yan yana tek satır okununca yalnız birinin Türkçesi gösterilmez; köşe yazısı eklenmiş okuma yine bulunur.
    TestRun.test("PackFuzzyTest.twoSubtitlesReadAsOneLineAreNotHalfTranslated") {
      assertEquals(
        ["Mirror Park Errr.", "Your broke.", "Call me back,", "okay? Bye, Dad."],
        PackFuzzy.clauses("Mirror Park Errr. Your broke. Call me back, okay? Bye, Dad.")
      )
      assertEquals(
        ["to escape...", "if we're able.", "You said seriously. nis seriously."],
        PackFuzzy.clauses("to escape... if we're able. You said seriously. nis seriously.")
      )
      guard directory != nil else { return }
      let library = library("gta-v.json.gz")
      assertNotNull(PackLookup.match(library, "Are you listening to me?"))
      let pairs = [
        ("Hey, look. Good shit on those contracts you been workin' on.", "But listen, I got some other work."),
        ("I'm calling it. Don't burn your eyes out.", "Bye, Dad."),
      ]
      for (first, second) in pairs {
        let alone = PackLookup.match(library, first)?.text
        assertNotNull(alone, first)
        let found = PackLookup.match(library, "\(first) \(second)")?.text
        assertNotEquals(alone, found, "\(first) \(second)")
        let other = PackLookup.match(library, second)?.text
        if let found = found, let other = other, let alone = alone {
          assertTrue(found.contains(alone) && found.contains(other), found)
        }
      }
      assertNotNull(PackLookup.match(library, "Your vehicle? Sorry, we can't get that sorted at this time. San Andreas"))
      assertNotNull(PackLookup.match(library, "Vinewood Hills Just not my junk, okay? I'm already scarred down there."))
    }
    /// En büyük pakette (GTA V) bulunamayan satırın araması da satır başına 20 ms'nin altında.
    TestRun.test("PackFuzzyTest.fuzzySearchIsFastInTheLargestPack") {
      guard directory != nil else { return }
      let library = library("gta-v.json.gz")
      assertNotNull(PackLookup.match(library, "Are you listening to me?"))
      let lines = [
        "Wh4t the fück are y0u doing here, man? Get öut of my house!", "Mich ael, I tbink we need to tälk about this",
        "Yöu know what, Franklin? You're a good kid, but you gotta lısten", "Lâmar, get in the c ar, we're late!",
        "The quick brown fox jumps over the lazy dog near the river bank.", "Sauvage gentleman of the western plains",
      ]
      // Isınma, sonra ölçüm.
      for _ in 0..<5 { for line in lines { _ = PackLookup.match(library, line) } }
      let rounds = 25
      let started = DispatchTime.now().uptimeNanoseconds
      for _ in 0..<rounds { for line in lines { _ = PackLookup.match(library, line) } }
      let perLineMs = Double(DispatchTime.now().uptimeNanoseconds - started) / 1e6 / Double(rounds * lines.count)
      print("  GTA V bulanık arama: satır başına \(String(format: "%.2f", perLineMs)) ms")
      assertTrue(perLineMs < 20, "satır başına \(perLineMs) ms")
    }
  }
}
