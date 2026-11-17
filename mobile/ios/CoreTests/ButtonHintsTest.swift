// SPDX-License-Identifier: AGPL-3.0-only
// Core/ButtonHints.swift testleri (Kotlin karşılığı yok).
import Foundation

enum ButtonHintsTest {
  static func run() {
    TestRun.test("ButtonHintsTest.trailingPromptsAreRemoved") {
      assertEquals("IL MERLO: then clear the way for someone who does.", ButtonHints.strip("IL MERLO: then clear the way for someone who does. RESUME BA"))
      assertEquals("MINER: Nobody's working down there until it's checked out.", ButtonHints.strip("MINER: Nobody's working down there until it's checked out. SKIP RESUME BA"))
      assertEquals("Let's go!", ButtonHints.strip("Let's go! SKIP X"))
      assertEquals("", ButtonHints.strip("SKIP RESUME BA"))
      assertEquals("", ButtonHints.strip("A CONTINUE"))
    }
    TestRun.test("ButtonHintsTest.dialogueIsLeftAlone") {
      assertEquals("I said go back", ButtonHints.strip("I said go back"))
      assertEquals("WE NEED TO GO BACK", ButtonHints.strip("WE NEED TO GO BACK"))
      assertEquals("Don't skip it. OK", ButtonHints.strip("Don't skip it. OK"))
      assertEquals("He said: SKIP", ButtonHints.strip("He said: SKIP"))
      assertEquals("PS5", ButtonHints.strip("PS5"))
      assertEquals("", ButtonHints.strip(""))
    }
  }
}
