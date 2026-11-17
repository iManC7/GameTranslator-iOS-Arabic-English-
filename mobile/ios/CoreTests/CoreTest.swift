// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/CoreTest.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
// SubtitleServerTest (HTTP sunucusu) çekirdeğin parçası olmadığı için burada yok.
import Foundation

enum TextMatchTest {
  static func run() {
    TestRun.test("TextMatchTest.normalizeKeepsOnlyLettersAndDigits") {
      assertEquals("where are you going", TextMatch.normalize("  Where are   you -- going?! "))
      assertEquals("çok güzel 24", TextMatch.normalize("Çok güzel: 24!"))
    }
    TestRun.test("TextMatchTest.similarityToleratesOcrNoise") {
      assertTrue(TextMatch.isSimilar("where are you going", "where are you goinq"))
      assertFalse(TextMatch.isSimilar("where are you going", "get in the car now"))
      assertFalse(TextMatch.isSimilar("", ""))
    }
    TestRun.test("TextMatchTest.grownTextIsANewSubtitle") {
      assertFalse(TextMatch.isSameSubtitle("where are you going son", "where are you going"))
      assertTrue(TextMatch.isSameSubtitle("where are you goinq", "where are you going"))
    }
    TestRun.test("TextMatchTest.missingWholeRowIsTheSameSubtitle") {
      let sent = TextMatch.normalizeRows("We need to leave right now\nbefore they find us here")
      assertTrue(TextMatch.isSameSubtitle("we need to leave right now", sent))
      assertFalse(TextMatch.isSameSubtitle("we need to leave", sent))
    }
    TestRun.test("TextMatchTest.revisionIsGrowthOrNearDuplicate") {
      assertTrue(TextMatch.isRevision("We do not have time.", "We do not have"))
      assertTrue(TextMatch.isRevision("I know somethin' is wrong here", "I know somethinl is wrong here"))
      assertFalse(TextMatch.isRevision("Get in the car.", "Where is the boy?"))
    }
  }
}

enum OcrNoiseTest {
  static func run() {
    TestRun.test("OcrNoiseTest.dropsGarbageTokensAndKeepsPunctuation") {
      assertEquals("We were in the, yes.", OcrNoise.clean("We were in the ou$3e, yes."))
      assertEquals("the waters are cold", OcrNoise.clean("the waters2aljd are cold"))
    }
    TestRun.test("OcrNoiseTest.keepsUsualLetterDigitMixes") {
      assertEquals("Press R2 on your PS5 at 60fps", OcrNoise.clean("Press R2 on your PS5 at 60fps"))
    }
    TestRun.test("OcrNoiseTest.fixesMisreadPronoun") {
      assertEquals("I don't know", OcrNoise.clean("l don't know"))
      assertEquals("I'll go", OcrNoise.clean("|'ll go"))
      assertEquals("Get in the car.", OcrNoise.clean("| Get in the car."))
    }
    TestRun.test("OcrNoiseTest.dropsLeadingGaugeNumber") {
      assertEquals("We'll lose them", OcrNoise.clean("9? We'll lose them"))
    }
    TestRun.test("OcrNoiseTest.garbledReadIsDetected") {
      assertTrue(OcrNoise.looksGarbled("Gtt solkolfege."))
      assertFalse(OcrNoise.looksGarbled("Where are you going?"))
      assertTrue(OcrNoise.score("Where are you going") > OcrNoise.score("WhErE aRe y0u$ goInG"))
    }
  }
}

/// Kotlin'deki `private var now = 0L` + `SubtitleStabilizer(clock = { now })`.
final class FakeClock {
  var now: Int64 = 0
}

enum SubtitleStabilizerTest {
  static func run() {
    func stabilizer(_ clock: FakeClock) -> SubtitleStabilizer { SubtitleStabilizer(clock: { clock.now }) }

    TestRun.test("SubtitleStabilizerTest.finishedSentenceIsSentOnFirstFrameAndOnlyOnce") {
      let c = FakeClock()
      let s = stabilizer(c)
      assertEquals(StabilizerAction.translate("Where are you going?"), s.feed("Where are you going?"))
      c.now += 200
      assertEquals(StabilizerAction.None, s.feed("Where are you going?"))
      c.now += 200
      assertEquals(StabilizerAction.None, s.feed("Where are you goinq?"))
    }
    TestRun.test("SubtitleStabilizerTest.unfinishedLineWaitsForASecondFrame") {
      let c = FakeClock()
      let s = stabilizer(c)
      assertEquals(StabilizerAction.None, s.feed("Where are you"))
      c.now += 200
      assertEquals(StabilizerKind.translate, s.feed("Where are you").kind)
    }
    TestRun.test("SubtitleStabilizerTest.emptyRegionClearsAfterDelay") {
      let c = FakeClock()
      let s = stabilizer(c)
      _ = s.feed("Get in the car.")
      c.now += 300
      assertEquals(StabilizerAction.None, s.feed(""))
      c.now += 900
      assertEquals(StabilizerAction.Clear, s.feed(""))
      c.now += 900
      assertEquals(StabilizerAction.None, s.feed(""))
    }
    TestRun.test("SubtitleStabilizerTest.lineThatComesBackIsRestoredNotRetranslated") {
      let c = FakeClock()
      let s = stabilizer(c)
      _ = s.feed("Get in the car.")
      c.now += 100
      _ = s.feed("")
      c.now += 900
      assertEquals(StabilizerAction.Clear, s.feed(""))
      c.now += 300
      assertEquals(StabilizerAction.restore("Get in the car."), s.feed("Get in the car."))
    }
    TestRun.test("SubtitleStabilizerTest.forgottenLineIsRetriedAfterDelay") {
      let c = FakeClock()
      let s = stabilizer(c)
      _ = s.feed("Get in the car.")
      s.forgetSent()
      c.now += 200
      assertEquals(StabilizerAction.None, s.feed("Get in the car."))
      c.now += 1000
      assertEquals(StabilizerKind.translate, s.feed("Get in the car.").kind)
    }
    TestRun.test("SubtitleStabilizerTest.sameLanguageIsNotSent") {
      let s = stabilizer(FakeClock())
      assertFalse(s.shouldSend("Ayarlar menüsü", "Ayarlar menüsü"))
      assertTrue(s.shouldSend("Where are you going?", "Nereye gidiyorsun?"))
    }
  }
}

final class RecordingSink: SubtitleSink {
  var shown: [String] = []
  var clears = 0

  func show(_ text: String, durationMs: Int, box: TextBox?, replaces: Bool) {
    shown.append("\(text)|\(durationMs)|\(replaces)")
  }

  func clear() { clears += 1 }
}

/// Kotlin testindeki `Executor { it.run() }` (doğrudan) ya da seri kuyruk; kuyrukta her okumadan sonra iş beklenir.
enum ExecutorMode: String, CaseIterable {
  case direct, serialQueue
}

/// Kotlin'deki SubtitlePipelineTest durumu: saat, sink ve hat.
final class PipelineFixture {
  let clock = FakeClock()
  let sink = RecordingSink()
  let mode: ExecutorMode
  let queue = DispatchQueue(label: "CoreTests.translate")
  var p: SubtitlePipeline!

  init(_ mode: ExecutorMode, _ translator: @escaping (String) -> String?) {
    self.mode = mode
    let clock = self.clock
    let stabilizer = SubtitleStabilizer(clock: { clock.now })
    switch mode {
    case .direct:
      p = SubtitlePipeline(translator: FunctionTranslator(translator), sink: sink, translateExecutor: { $0() },
                           stabilizer: stabilizer)
    case .serialQueue:
      p = SubtitlePipeline(translator: FunctionTranslator(translator), sink: sink, translateQueue: queue,
                           stabilizer: stabilizer)
    }
  }

  var shown: [String] { sink.shown }
  var clears: Int { sink.clears }

  func onRead(_ lines: [String], _ box: TextBox?) {
    p.onRead(lines, box)
    if mode == .serialQueue { queue.sync {} }
  }
}

enum SubtitlePipelineTest {
  static func run() {
    for mode in ExecutorMode.allCases { run(mode) }
  }

  static func run(_ mode: ExecutorMode) {
    let suffix = " [\(mode.rawValue)]"
    TestRun.test("SubtitlePipelineTest.translatesShowsAndClears" + suffix) {
      var calls: [String] = []
      let f = PipelineFixture(mode) { text in calls.append(text); return "Nereye gidiyorsun?" }
      f.onRead(["Where are", "you going?"], TextBox(left: 0.2, top: 0.8, right: 0.8, bottom: 0.9))
      assertEquals(["Where are you going?"], calls)
      assertEquals(["Nereye gidiyorsun?|15000|false"], f.shown)
      f.clock.now += 300
      f.onRead(["Where are", "you going?"], nil)
      assertEquals(1, f.shown.count)
      f.clock.now += 100
      f.onRead([], nil)
      f.clock.now += 900
      f.onRead([], nil)
      assertEquals(1, f.clears)
    }
    TestRun.test("SubtitlePipelineTest.cachedLineIsNotTranslatedAgain" + suffix) {
      var calls = 0
      let f = PipelineFixture(mode) { _ in calls += 1; return "Arabaya bin." }
      f.onRead(["Get in the car."], nil)
      f.clock.now += 100
      f.onRead([], nil)
      f.clock.now += 5000
      f.onRead([], nil)
      f.clock.now += 5000
      f.onRead(["Get in the car."], nil)
      assertEquals(1, calls)
      assertEquals(2, f.shown.count)
    }
    TestRun.test("SubtitlePipelineTest.failedTranslationShowsNothingAndRetries" + suffix) {
      var calls = 0
      let f = PipelineFixture(mode) { _ in calls += 1; return calls == 1 ? nil : "Arabaya bin." }
      f.onRead(["Get in the car."], nil)
      assertTrue(f.shown.isEmpty)
      f.clock.now += 1200
      f.onRead(["Get in the car."], nil)
      assertEquals(["Arabaya bin.|15000|false"], f.shown)
    }
    TestRun.test("SubtitlePipelineTest.grownLineReplacesThePreviousOne" + suffix) {
      let f = PipelineFixture(mode) { text in "tr:\(text)" }
      f.onRead(["We do not have"], nil)
      f.clock.now += 200
      f.onRead(["We do not have"], nil)
      f.clock.now += 200
      f.onRead(["We do not have time."], nil)
      assertEquals(["tr:We do not have|15000|false", "tr:We do not have time.|15000|true"], f.shown)
    }
    TestRun.test("SubtitlePipelineTest.textAlreadyInTargetLanguageIsNotShown" + suffix) {
      let f = PipelineFixture(mode) { text in text }
      f.onRead(["Ayarlar menüsünü aç."], nil)
      assertTrue(f.shown.isEmpty)
    }
  }
}

enum ReadSchedulerTest {
  static func run() {
    TestRun.test("ReadSchedulerTest.unchangedRegionIsReusedUpToALimit") {
      let scheduler = ReadScheduler(maxReuse: 2)
      let a = [UInt8](repeating: 100, count: 16)
      assertFalse(scheduler.canReuse(a))
      assertTrue(scheduler.canReuse(a))
      assertTrue(scheduler.canReuse(a))
      assertFalse(scheduler.canReuse(a))
      assertFalse(scheduler.canReuse((0..<16).map { $0 == 3 ? 10 : 100 }))
    }
  }
}
