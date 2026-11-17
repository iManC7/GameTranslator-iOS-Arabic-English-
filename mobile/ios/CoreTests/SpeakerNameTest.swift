// SPDX-License-Identifier: AGPL-3.0-only
// Core/SpeakerName.swift testleri (Kotlin karşılığı yok).
import Foundation

enum SpeakerNameTest {
  static func run() {
    TestRun.test("SpeakerNameTest.namesAreSplitOff") {
      assertEquals("ENZO: ", SpeakerName.split("ENZO: Come on, Gaetano, where are you...").0)
      assertEquals("MINE GUARD: ", SpeakerName.split("MINE GUARD: It wasn't me!").0)
      assertEquals("It wasn't me!", SpeakerName.split("MINE GUARD: It wasn't me!").1)
      assertEquals("DR. O'NEIL-SMITH: ", SpeakerName.split("DR. O'NEIL-SMITH: Hold still.").0)
      assertEquals("BB-8: ", SpeakerName.split("BB-8: Beep.").0)
    }
    TestRun.test("SpeakerNameTest.ordinaryTextIsLeftAlone") {
      assertEquals("", SpeakerName.split("Note: this is not a name").0)
      assertEquals("", SpeakerName.split("We need to go: now.").0)
      assertEquals("", SpeakerName.split("A: one letter").0)
      assertEquals("", SpeakerName.split("10:30 tomorrow").0)
      assertEquals("", SpeakerName.split("ENZO:").0)
      assertEquals("", SpeakerName.split("A VERY LONG NAME THAT IS NOT A NAME AT ALL: hi").0)
    }
    TestRun.test("SpeakerNameTest.translatorKeepsTheName") {
      var seen: [String] = []
      let translator = SpeakerNameTranslator(FunctionTranslator { text in seen.append(text); return "[\(text)]" })
      assertEquals("MINE GUARD: [It wasn't me!]", translator.translate("MINE GUARD: It wasn't me!"))
      assertEquals(["It wasn't me!"], seen)
      assertEquals("[Hello there]", translator.translate("Hello there"))
      let failing = SpeakerNameTranslator(FunctionTranslator { _ in nil })
      assertNull(failing.translate("ENZO: Hi."))
      // Konuşmacı işaretiyle birlikte: önce tire, sonra ad ayrılır.
      let both = PrefixTranslator(SpeakerNameTranslator(FunctionTranslator { "[\($0)]" }))
      assertEquals("- ENZO: [Go.]", both.translate("- ENZO: Go."))
    }
  }
}
