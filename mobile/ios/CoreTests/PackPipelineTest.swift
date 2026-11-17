// SPDX-License-Identifier: AGPL-3.0-only
// Android'deki test/.../core/PackPipelineTest.kt'nin Swift portu; onunla birebir aynı tutulmalıdır.
// Kotlin'deki doğrudan yürütücü (`Executor { it.run() }`) ve ayrıca seri kuyruk denenir (SubtitlePipelineTest gibi).
import Foundation

/// Hattın oyun paketi yolu: paketteki satır motora gitmez, olmayan satır motora gider.
enum PackPipelineTest {
  final class TextSink: SubtitleSink {
    var shown: [String] = []
    func show(_ text: String, durationMs: Int, box: TextBox?, replaces: Bool) { shown.append(text) }
    func clear() {}
  }

  final class Fixture {
    let clock = FakeClock()
    let sink = TextSink()
    let mode: ExecutorMode
    let queue = DispatchQueue(label: "CoreTests.packs")
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

    func onRead(_ lines: [String], _ box: TextBox?) {
      p.onRead(lines, box)
      if mode == .serialQueue { queue.sync {} }
    }
  }

  private static let pack: [String: String] = [
    PackKey.key("Get Down!")!: "Yere yat!",
    PackKey.key("Who is that?")!: "O da kim?",
    PackKey.key("Don Torrisi wants you.")!: "Don Torrisi seni istiyor.",
  ]

  static func lookup(_ text: String) -> PackMatch? {
    PackLookup.match(text) { line in PackKey.key(line).flatMap { pack[$0] } }
  }

  struct Broken: Error {}

  static func run() {
    for mode in ExecutorMode.allCases { run(mode) }
    TestRun.test("PackPipelineTest.speakerPrefixIsKept") {
      assertEquals(">> Yere yat!", PackTranslation.match(">> Get down!", lookup)?.text)
      assertEquals("- Yere yat!", PackTranslation.match("- Get down!", lookup)?.text)
      assertEquals("- Yere yat!\n- O da kim?", PackTranslation.match("- Get down!\n- Who is that?", lookup)?.text)
      assertEquals("ENZO: Don Torrisi seni istiyor.", PackTranslation.match("ENZO: Don Torrisi wants you.", lookup)?.text)
      assertNull(PackTranslation.match("- ", lookup))
      assertNull(PackTranslation.match("Get out!", lookup))
    }
    TestRun.test("PackPipelineTest.packsAreOnlyForEnglishToTurkish") {
      assertTrue(PackTranslation.applies("en", "tr"))
      assertFalse(PackTranslation.applies("en", "de"))
      assertFalse(PackTranslation.applies("ja", "tr"))
    }
    /// Uygulamayla gelen GTA V paketiyle uçtan uca: tam satır, sonra OCR'ın bozduğu satır aynı paketten.
    TestRun.test("PackPipelineTest.embeddedPackThroughThePipeline") {
      guard EmbeddedPacks.directory != nil else { return }
      let library = EmbeddedPacks.library("gta-v.json.gz")
      var calls = 0
      let f = Fixture(.direct) { _ in calls += 1; return "motor" }
      f.p.packLookup = { text in PackTranslation.match(library, text) }
      f.onRead(["Are you listening to me?"], nil)
      assertEquals(0, calls)
      assertEquals("gta-v", library.searchScope)
      f.clock.now += 100
      f.onRead([], nil)
      f.clock.now += 2000
      f.onRead([], nil)
      f.onRead(["Somebody help rne!"], nil)
      assertEquals(0, calls)
      assertEquals(PackTranslation.match(library, "Somebody help me!")?.text, f.sink.shown.last)
      assertEquals(2, f.p.packHits)
    }
  }

  static func run(_ mode: ExecutorMode) {
    let suffix = " [\(mode.rawValue)]"
    TestRun.test("PackPipelineTest.packLineSkipsTheEngine" + suffix) {
      var calls: [String] = []
      var hits: [String] = []
      let f = Fixture(mode) { text in calls.append(text); return "motor:\(text)" }
      f.p.packLookup = { text in PackTranslation.match(text, lookup) }
      f.p.onPackHit = { source, _ in hits.append(source) }
      // İki satırlık okuma pakete satırlarıyla gider; ikisi de paketteyse motora hiç gidilmez.
      f.onRead(["Get down!", "Who is that?"], nil)
      assertEquals(["Yere yat!\nO da kim?"], f.sink.shown)
      assertTrue(calls.isEmpty)
      assertEquals(["Get down!\nWho is that?"], hits)
      assertEquals(1, f.p.packHits)

      f.clock.now += 100
      f.onRead([], nil)
      f.clock.now += 2000
      f.onRead([], nil)
      f.onRead(["Where are you going?"], nil)
      assertEquals(["Where are you going?"], calls)
      assertEquals("motor:Where are you going?", f.sink.shown.last)
      assertEquals(1, f.p.packHits)
    }
    TestRun.test("PackPipelineTest.brokenLookupFallsBackToTheEngine" + suffix) {
      let f = Fixture(mode) { _ in "Arabaya bin." }
      f.p.packLookup = { _ in throw Broken() }
      f.onRead(["Get in the car."], nil)
      assertEquals(["Arabaya bin."], f.sink.shown)
    }
  }
}
