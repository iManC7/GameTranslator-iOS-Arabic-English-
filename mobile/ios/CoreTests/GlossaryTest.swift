// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/GlossaryTest.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
import Foundation

/// Windows'taki GlossaryTests, TurkishSuffixTests ve TermProtectionTests ile aynı durumlar.
enum GlossaryTest {
  static let gow = Glossary.of(
    ["Leviathan Axe": "Leviathan Baltası", "Axe": "Balta", "Midgard": "Midgard", "World Serpent": "Dünya Yılanı"],
    keep: ["Kratos", "Atreus"])

  static func run() {
    TestRun.test("GlossaryTest.parsesTermsAndKeepNames") {
      assertEquals(6, gow.count)
      assertEquals("Leviathan Baltası", gow.turkish("leviathan  axe"))
      assertEquals("Kratos", gow.turkish("KRATOS"))
      assertNull(gow.turkish("Freya"))
      assertEquals(1, Glossary.of(["...": "x", "Odin": "Odin", "": "y"]).count)
    }
    TestRun.test("GlossaryTest.findsWholeWordsCaseInsensitiveLongestFirst") {
      let found = gow.find("THROW THE LEVIATHAN AXE, then the axe. Kratos's axes. Midgardian.")
      assertEquals(["Leviathan Axe", "Axe", "Kratos"], found.map { $0.english })
      assertEquals(10, found[0].start)
    }
  }
}

enum TurkishSuffixTest {
  private static func check(_ cases: [(String, String, String)], file: String = #fileID, line: Int = #line) {
    for (term, suffix, expected) in cases {
      assertEquals(expected, TurkishSuffix.attach(term, suffix), "\(term) + \(suffix)", file: file, line: line)
    }
  }

  static func run() {
    TestRun.test("TurkishSuffixTest.properNounsTakeHarmonizedSuffixWithApostrophe") {
      check([
        ("Kratos", "u", "Kratos'u"), ("Kratos", "un", "Kratos'un"), ("Kratos", "a", "Kratos'a"),
        ("Kratos", "da", "Kratos'ta"), ("Kratos", "dan", "Kratos'tan"), ("Kratos", "la", "Kratos'la"),
        ("Kratos", "dur", "Kratos'tur"), ("Atreus", "un", "Atreus'un"), ("Midgard", "a", "Midgard'a"),
        ("Midgard", "da", "Midgard'da"), ("Midgard", "u", "Midgard'ı"), ("Midgard", "un", "Midgard'ın"),
        ("Midgard", "daki", "Midgard'daki"), ("Freya", "u", "Freya'yı"), ("Freya", "a", "Freya'ya"),
        ("Freya", "un", "Freya'nın"), ("Freya", "la", "Freya'yla"), ("Freya", "da", "Freya'da"),
        ("Mimir", "a", "Mimir'e"), ("Mimir", "u", "Mimir'i"), ("Mimir", "dan", "Mimir'den"),
        ("Brok", "da", "Brok'ta"), ("Jötunheim", "a", "Jötunheim'e"), ("Thor", "un", "Thor'un"),
        ("Sindri", "un", "Sindri'nin"), ("Sindri", "u", "Sindri'yi"), ("Odin", "ya", "Odin'e"),
        ("Freya", "nın", "Freya'nın"), ("Kratos", "nın", "Kratos'un"), ("Kratos", "", "Kratos"),
      ])
    }
    TestRun.test("TurkishSuffixTest.compoundNamesTakeTheBufferN") {
      check([
        ("Leviathan Baltası", "u", "Leviathan Baltası'nı"), ("Leviathan Baltası", "a", "Leviathan Baltası'na"),
        ("Leviathan Baltası", "da", "Leviathan Baltası'nda"), ("Leviathan Baltası", "dan", "Leviathan Baltası'ndan"),
        ("Leviathan Baltası", "un", "Leviathan Baltası'nın"), ("Leviathan Baltası", "la", "Leviathan Baltası'yla"),
        ("Dünya Ağacı", "a", "Dünya Ağacı'na"), ("Kaos Bıçakları", "u", "Kaos Bıçakları'nı"),
      ])
    }
    TestRun.test("TurkishSuffixTest.commonNounsAreWrittenTogether") {
      check([
        ("can iksiri", "u", "can iksirini"), ("kontrol noktası", "a", "kontrol noktasına"),
        ("bekleme süresi", "da", "bekleme süresinde"), ("envanter", "a", "envantere"),
        ("kılıç", "u", "kılıcı"), ("kitap", "u", "kitabı"), ("bıçak", "u", "bıçağı"),
        ("renk", "u", "rengi"), ("top", "u", "topu"), ("balta", "u", "baltayı"),
        ("balta", "lar", "baltalar"), ("kalkan", "dan", "kalkandan"), ("kalkan", "la", "kalkanla"),
      ])
    }
  }
}

enum TermProtectionTest {
  static let gow = Glossary.of(
    ["Leviathan Axe": "Leviathan Baltası", "Midgard": "Midgard", "health potion": "can iksiri"],
    keep: ["Kratos", "Atreus"])

  static func run() {
    TestRun.test("TermProtectionTest.replacesTermsWithPlaceholderNames") {
      let (text, slots) = TermProtector(gow, "").protect("Kratos, take the Leviathan Axe to Midgard. Kratos!")
      assertEquals("Zarmon, take the Velkor to Dorvan. Zarmon!", text)
      assertEquals(["Kratos", "Leviathan Axe", "Midgard"], slots.map { $0.english })
    }
    TestRun.test("TermProtectionTest.restoresTermsWithSuffixesDespiteCaseAndSpacing") {
      let cases: KeyValuePairs<String, String> = [
        "Zarmon, Velkor'u Dorvan'a götür. Zarmon!": "Kratos, Leviathan Baltası'nı Midgard'a götür. Kratos!",
        "ZARMON, VELKOR'U DORVAN'A GÖTÜR. ZARMON!": "Kratos, Leviathan Baltası'nı Midgard'a GÖTÜR. Kratos!",
        "Zarmon, Velkor ’u Dorvana götür. Zarmon!": "Kratos, Leviathan Baltası'nı Midgard'a götür. Kratos!",
      ]
      for (output, expected) in cases {
        let protector = TermProtector(gow, "")
        let (_, slots) = protector.protect("Kratos, take the Leviathan Axe to Midgard. Kratos!")
        assertEquals(expected, TermProtector.restore(output, slots, protector.allSlots))
      }
    }
    TestRun.test("TermProtectionTest.missingOrForeignPlaceholderMeansUnreliable") {
      let protector = TermProtector(gow, "")
      let (_, slots) = protector.protect("Take the Leviathan Axe to Midgard.")
      assertNull(TermProtector.restore("Baltayı Dorvan'a götür.", slots, protector.allSlots))

      let other = TermProtector(gow, "")
      other.protect("Kratos!")
      let (_, second) = other.protect("Go to Midgard.")
      assertNull(TermProtector.restore("Zarmon Velkor'a git.", second, other.allSlots))
      assertEquals("Midgard'a git.", TermProtector.restore("Velkor'a git.", second, other.allSlots))
    }
    TestRun.test("TermProtectionTest.commonNounAtSentenceStartIsCapitalizedAndQuotesAreNotSuffixes") {
      let (_, slots) = TermProtector(gow, "").protect("Drink the health potion. Health potion first!")
      assertEquals("Can iksirini iç. Önce can iksiri!", TermProtector.restore("Zarmon'u iç. Önce Zarmon!", slots))
      let (_, quoted) = TermProtector(gow, "").protect("He said 'Midgard' again.")
      assertEquals("Yine 'Midgard' dedi.", TermProtector.restore("Yine 'Zarmon' dedi.", quoted))
    }
    TestRun.test("TermProtectionTest.placeholderAlreadyInTheSourceIsSkipped") {
      assertEquals("Zarmon met Velkor.", TermProtector(gow, "Zarmon met Kratos.").protect("Zarmon met Kratos.").0)
    }
    TestRun.test("TermProtectionTest.translatorProtectsTermsAndFallsBackWhenAPlaceholderIsLost") {
      var seen: [String] = []
      let good = GlossaryTranslator(gow) { text in
        seen.append(text)
        return text.contains("Zarmon") ? "Zarmon'a git." : "Şimdi gidiyoruz."
      }
      assertEquals("Midgard'a git.", good.translate("Go to Midgard."))
      assertEquals("Şimdi gidiyoruz.", good.translate("We go now."))
      assertEquals(["Go to Zarmon.", "We go now."], seen)

      let lossy = GlossaryTranslator(gow) { text in text.contains("Zarmon") ? "Oraya git." : "Midgard'a git." }
      assertEquals("Midgard'a git.", lossy.translate("Go to Midgard."))
      assertNull(GlossaryTranslator(gow) { _ in nil }.translate("Go to Midgard."))
    }
  }
}

enum SpeakerPrefixTest {
  static func run() {
    TestRun.test("SpeakerPrefixTest.splitsDashAndChevronMarkers") {
      func pair(_ p: (String, String)) -> [String] { [p.0, p.1] }
      assertEquals(["- ", "Where are you going?"], pair(SpeakerPrefix.split("- Where are you going?")))
      assertEquals(["— ", "Run!"], pair(SpeakerPrefix.split("  — Run!  ")))
      assertEquals([">> ", "Stay close."], pair(SpeakerPrefix.split(">> Stay close.")))
      assertEquals([">>", "Go."], pair(SpeakerPrefix.split(">>Go.")))
      assertEquals(["", "No marker here - just a dash inside."], pair(SpeakerPrefix.split("No marker here - just a dash inside.")))
      assertEquals(["-", ""], pair(SpeakerPrefix.split("- ")))
    }
    TestRun.test("SpeakerPrefixTest.translatorKeepsTheMarkerOutOfTheEngine") {
      var seen: [String] = []
      let translator = PrefixTranslator { text in
        seen.append(text)
        return text == "Where are you going?" ? "Nereye gidiyorsun?" : "Dikkat et."
      }
      assertEquals("- Nereye gidiyorsun?", translator.translate("- Where are you going?"))
      assertEquals("Dikkat et.", translator.translate("Be careful."))
      assertEquals(["Where are you going?", "Be careful."], seen)
      assertEquals("-", translator.translate("- "))
      assertNull(PrefixTranslator { _ in nil }.translate(">> Hold on."))
      assertNull(PrefixTranslator { _ in "  " }.translate(">> Hold on."))
    }
  }
}
