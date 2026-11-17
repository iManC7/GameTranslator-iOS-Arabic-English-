// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.util.concurrent.Executor

/** Hattın oyun paketi yolu: paketteki satır motora gitmez, olmayan satır motora gider. */
class PackPipelineTest {
    private var now = 0L
    private val shown = mutableListOf<String>()
    private val sink = object : SubtitleSink {
        override fun show(text: String, durationMs: Int, box: TextBox?, replaces: Boolean) {
            shown.add(text)
        }

        override fun clear() {}
    }
    private val direct = Executor { it.run() }

    private val pack = mapOf(
        PackKey.key("Get Down!")!! to "Yere yat!",
        PackKey.key("Who is that?")!! to "O da kim?",
        PackKey.key("Don Torrisi wants you.")!! to "Don Torrisi seni istiyor.",
    )

    private fun lookup(text: String) = PackLookup.match(text) { line -> PackKey.key(line)?.let { pack[it] } }

    @Test
    fun packLineSkipsTheEngine() {
        val calls = mutableListOf<String>()
        val hits = mutableListOf<String>()
        val p = SubtitlePipeline({ text -> calls.add(text); "motor:$text" }, sink, direct, SubtitleStabilizer(clock = { now }))
        p.packLookup = { text -> PackTranslation.match(text, ::lookup) }
        p.onPackHit = { source, _ -> hits.add(source) }
        // İki satırlık okuma pakete satırlarıyla gider; ikisi de paketteyse motora hiç gidilmez.
        p.onRead(listOf("Get down!", "Who is that?"), null)
        assertEquals(listOf("Yere yat!\nO da kim?"), shown)
        assertTrue(calls.isEmpty())
        assertEquals(listOf("Get down!\nWho is that?"), hits)
        assertEquals(1, p.packHits)

        now += 100
        p.onRead(emptyList(), null)
        now += 2000
        p.onRead(emptyList(), null)
        p.onRead(listOf("Where are you going?"), null)
        assertEquals(listOf("Where are you going?"), calls)
        assertEquals("motor:Where are you going?", shown.last())
        assertEquals(1, p.packHits)
    }

    @Test
    fun brokenLookupFallsBackToTheEngine() {
        val p = SubtitlePipeline({ "Arabaya bin." }, sink, direct, SubtitleStabilizer(clock = { now }))
        p.packLookup = { throw IllegalStateException("bozuk") }
        p.onRead(listOf("Get in the car."), null)
        assertEquals(listOf("Arabaya bin."), shown)
    }

    /** Konuşmacı işareti PrefixTranslator'daki gibi korunur; ">>" paket anahtarında yok sayıldığı için ayrıca eklenir. */
    @Test
    fun speakerPrefixIsKept() {
        assertEquals(">> Yere yat!", PackTranslation.match(">> Get down!", ::lookup)?.text)
        assertEquals("- Yere yat!", PackTranslation.match("- Get down!", ::lookup)?.text)
        assertEquals("- Yere yat!\n- O da kim?", PackTranslation.match("- Get down!\n- Who is that?", ::lookup)?.text)
        assertEquals("ENZO: Don Torrisi seni istiyor.", PackTranslation.match("ENZO: Don Torrisi wants you.", ::lookup)?.text)
        assertNull(PackTranslation.match("- ", ::lookup))
        assertNull(PackTranslation.match("Get out!", ::lookup))
    }

    @Test
    fun packsAreOnlyForEnglishToTurkish() {
        assertTrue(PackTranslation.applies("en", "tr"))
        assertFalse(PackTranslation.applies("en", "de"))
        assertFalse(PackTranslation.applies("ja", "tr"))
    }

    /** Uygulamayla gelen GTA V paketiyle uçtan uca: tam satır, sonra OCR'ın bozduğu satır aynı paketten. */
    @Test
    fun embeddedPackThroughThePipeline() {
        val directory = System.getProperty("gametranslator.packs")?.let(::File) ?: return
        val library = GamePackLibrary({ listOf("gta-v.json.gz" to { File(directory, "gta-v.json.gz").readBytes() }) }, null)
        var calls = 0
        val p = SubtitlePipeline({ calls++; "motor" }, sink, direct, SubtitleStabilizer(clock = { now }))
        p.packLookup = { text -> PackTranslation.match(library, text) }
        p.onRead(listOf("Are you listening to me?"), null)
        assertEquals(0, calls)
        assertEquals("gta-v", library.searchScope)
        now += 100
        p.onRead(emptyList(), null)
        now += 2000
        p.onRead(emptyList(), null)
        p.onRead(listOf("Somebody help rne!"), null)
        assertEquals(0, calls)
        assertEquals(PackTranslation.match(library, "Somebody help me!")?.text, shown.last())
        assertEquals(2, p.packHits)
    }
}
