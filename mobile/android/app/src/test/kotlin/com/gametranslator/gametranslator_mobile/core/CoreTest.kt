// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.net.HttpURLConnection
import java.net.Socket
import java.net.URL
import java.util.concurrent.Executor

class TextMatchTest {
    @Test
    fun normalizeKeepsOnlyLettersAndDigits() {
        assertEquals("where are you going", TextMatch.normalize("  Where are   you -- going?! "))
        assertEquals("çok güzel 24", TextMatch.normalize("Çok güzel: 24!"))
    }

    @Test
    fun similarityToleratesOcrNoise() {
        assertTrue(TextMatch.isSimilar("where are you going", "where are you goinq"))
        assertFalse(TextMatch.isSimilar("where are you going", "get in the car now"))
        assertFalse(TextMatch.isSimilar("", ""))
    }

    @Test
    fun grownTextIsANewSubtitle() {
        assertFalse(TextMatch.isSameSubtitle("where are you going son", "where are you going"))
        assertTrue(TextMatch.isSameSubtitle("where are you goinq", "where are you going"))
    }

    @Test
    fun missingWholeRowIsTheSameSubtitle() {
        val sent = TextMatch.normalizeRows("We need to leave right now\nbefore they find us here")
        assertTrue(TextMatch.isSameSubtitle("we need to leave right now", sent))
        assertFalse(TextMatch.isSameSubtitle("we need to leave", sent))
    }

    @Test
    fun revisionIsGrowthOrNearDuplicate() {
        assertTrue(TextMatch.isRevision("We do not have time.", "We do not have"))
        assertTrue(TextMatch.isRevision("I know somethin' is wrong here", "I know somethinl is wrong here"))
        assertFalse(TextMatch.isRevision("Get in the car.", "Where is the boy?"))
    }
}

class OcrNoiseTest {
    @Test
    fun dropsGarbageTokensAndKeepsPunctuation() {
        assertEquals("We were in the, yes.", OcrNoise.clean("We were in the ou$3e, yes."))
        assertEquals("the waters are cold", OcrNoise.clean("the waters2aljd are cold"))
    }

    @Test
    fun keepsUsualLetterDigitMixes() {
        assertEquals("Press R2 on your PS5 at 60fps", OcrNoise.clean("Press R2 on your PS5 at 60fps"))
    }

    @Test
    fun fixesMisreadPronoun() {
        assertEquals("I don't know", OcrNoise.clean("l don't know"))
        assertEquals("I'll go", OcrNoise.clean("|'ll go"))
        assertEquals("Get in the car.", OcrNoise.clean("| Get in the car."))
    }

    @Test
    fun dropsLeadingGaugeNumber() {
        assertEquals("We'll lose them", OcrNoise.clean("9? We'll lose them"))
    }

    @Test
    fun garbledReadIsDetected() {
        assertTrue(OcrNoise.looksGarbled("Gtt solkolfege."))
        assertFalse(OcrNoise.looksGarbled("Where are you going?"))
        assertTrue(OcrNoise.score("Where are you going") > OcrNoise.score("WhErE aRe y0u$ goInG"))
    }
}

class SubtitleStabilizerTest {
    private var now = 0L
    private fun stabilizer() = SubtitleStabilizer(clock = { now })

    @Test
    fun finishedSentenceIsSentOnFirstFrameAndOnlyOnce() {
        val s = stabilizer()
        assertEquals(StabilizerAction.translate("Where are you going?"), s.feed("Where are you going?"))
        now += 200
        assertEquals(StabilizerAction.None, s.feed("Where are you going?"))
        now += 200
        assertEquals(StabilizerAction.None, s.feed("Where are you goinq?"))
    }

    @Test
    fun unfinishedLineWaitsForASecondFrame() {
        val s = stabilizer()
        assertEquals(StabilizerAction.None, s.feed("Where are you"))
        now += 200
        assertEquals(StabilizerKind.TRANSLATE, s.feed("Where are you").kind)
    }

    @Test
    fun emptyRegionClearsAfterDelay() {
        val s = stabilizer()
        s.feed("Get in the car.")
        now += 300
        assertEquals(StabilizerAction.None, s.feed(""))
        now += 900
        assertEquals(StabilizerAction.Clear, s.feed(""))
        now += 900
        assertEquals(StabilizerAction.None, s.feed(""))
    }

    @Test
    fun lineThatComesBackIsRestoredNotRetranslated() {
        val s = stabilizer()
        s.feed("Get in the car.")
        now += 100
        s.feed("")
        now += 900
        assertEquals(StabilizerAction.Clear, s.feed(""))
        now += 300
        assertEquals(StabilizerAction.restore("Get in the car."), s.feed("Get in the car."))
    }

    @Test
    fun forgottenLineIsRetriedAfterDelay() {
        val s = stabilizer()
        s.feed("Get in the car.")
        s.forgetSent()
        now += 200
        assertEquals(StabilizerAction.None, s.feed("Get in the car."))
        now += 1000
        assertEquals(StabilizerKind.TRANSLATE, s.feed("Get in the car.").kind)
    }

    @Test
    fun sameLanguageIsNotSent() {
        val s = stabilizer()
        assertFalse(s.shouldSend("Ayarlar menüsü", "Ayarlar menüsü"))
        assertTrue(s.shouldSend("Where are you going?", "Nereye gidiyorsun?"))
    }
}

class SubtitlePipelineTest {
    private var now = 0L
    private val shown = mutableListOf<String>()
    private var clears = 0
    private val sink = object : SubtitleSink {
        override fun show(text: String, durationMs: Int, box: TextBox?, replaces: Boolean) {
            shown.add("$text|$durationMs|$replaces")
        }

        override fun clear() {
            clears++
        }
    }
    private val direct = Executor { it.run() }

    private fun pipeline(translator: TextTranslator) =
        SubtitlePipeline(translator, sink, direct, SubtitleStabilizer(clock = { now }))

    @Test
    fun translatesShowsAndClears() {
        val calls = mutableListOf<String>()
        val p = pipeline { text -> calls.add(text); "Nereye gidiyorsun?" }
        p.onRead(listOf("Where are", "you going?"), TextBox(0.2, 0.8, 0.8, 0.9))
        assertEquals(listOf("Where are you going?"), calls)
        assertEquals(listOf("Nereye gidiyorsun?|15000|false"), shown)
        now += 300
        p.onRead(listOf("Where are", "you going?"), null)
        assertEquals(1, shown.size)
        now += 100
        p.onRead(emptyList(), null)
        now += 900
        p.onRead(emptyList(), null)
        assertEquals(1, clears)
    }

    @Test
    fun cachedLineIsNotTranslatedAgain() {
        var calls = 0
        val p = pipeline { calls++; "Arabaya bin." }
        p.onRead(listOf("Get in the car."), null)
        now += 100
        p.onRead(emptyList(), null)
        now += 5000
        p.onRead(emptyList(), null)
        now += 5000
        p.onRead(listOf("Get in the car."), null)
        assertEquals(1, calls)
        assertEquals(2, shown.size)
    }

    @Test
    fun failedTranslationShowsNothingAndRetries() {
        var calls = 0
        val p = pipeline { calls++; if (calls == 1) null else "Arabaya bin." }
        p.onRead(listOf("Get in the car."), null)
        assertTrue(shown.isEmpty())
        now += 1200
        p.onRead(listOf("Get in the car."), null)
        assertEquals(listOf("Arabaya bin.|15000|false"), shown)
    }

    @Test
    fun grownLineReplacesThePreviousOne() {
        val p = pipeline { text -> "tr:$text" }
        p.onRead(listOf("We do not have"), null)
        now += 200
        p.onRead(listOf("We do not have"), null)
        now += 200
        p.onRead(listOf("We do not have time."), null)
        assertEquals(listOf("tr:We do not have|15000|false", "tr:We do not have time.|15000|true"), shown)
    }

    @Test
    fun textAlreadyInTargetLanguageIsNotShown() {
        val p = pipeline { text -> text }
        p.onRead(listOf("Ayarlar menüsünü aç."), null)
        assertTrue(shown.isEmpty())
    }
}

class ReadSchedulerTest {
    @Test
    fun unchangedRegionIsReusedUpToALimit() {
        val scheduler = ReadScheduler(maxReuse = 2)
        val a = ByteArray(16) { 100 }
        assertFalse(scheduler.canReuse(a))
        assertTrue(scheduler.canReuse(a.copyOf()))
        assertTrue(scheduler.canReuse(a.copyOf()))
        assertFalse(scheduler.canReuse(a.copyOf()))
        assertFalse(scheduler.canReuse(ByteArray(16) { if (it == 3) 10 else 100 }))
    }
}

class SubtitleServerTest {
    @Test
    fun servesOverlayPageOnlyWhenProvided() {
        val server = SubtitleServer(port = 0)
        val port = server.start()
        try {
            val missing = URL("http://127.0.0.1:$port/obs").openConnection() as HttpURLConnection
            assertEquals(404, missing.responseCode)
            server.overlayPage = "<html>altyazı</html>".toByteArray()
            val page = URL("http://127.0.0.1:$port/obs").openConnection() as HttpURLConnection
            assertEquals(200, page.responseCode)
            assertTrue(page.contentType.startsWith("text/html"))
            assertEquals("<html>altyazı</html>", page.inputStream.readBytes().toString(Charsets.UTF_8))
        } finally {
            server.stop()
        }
    }

    @Test
    fun framesMatchTheTvProtocol() {
        assertEquals("0.875", SubtitleServer.number(0.8750))
        assertEquals("1", SubtitleServer.number(1.4))
        assertEquals("0", SubtitleServer.number(-0.2))
        assertEquals(
            "event: subtitle\ndata: {\"at\":5,\"box\":{\"bottom\":0.9,\"left\":0.2,\"right\":0.8,\"top\":0.8},\"duration\":15000,\"replace\":true,\"text\":\"Çok \\\"iyi\\\"\\nşey\"}\n\n",
            SubtitleServer.subtitleFrame("Çok \"iyi\"\nşey", 15000, TextBox(0.2, 0.8, 0.8, 0.9), true, 5))
        assertEquals(
            "event: style\ndata: {\"background\":72,\"bold\":false,\"bottomPercent\":7,\"displayMode\":\"inApp\",\"fontSize\":46,\"placement\":\"cover\",\"stackPrevious\":true,\"textColor\":\"white\"}\n\n",
            SubtitleServer.styleFrame(SubtitleStyle()))
    }

    @Test
    fun helloIdentifiesTheAppInLowercase() {
        val server = SubtitleServer(port = 0)
        val port = server.start()
        try {
            val connection = URL("http://127.0.0.1:$port/hello").openConnection() as HttpURLConnection
            assertEquals(200, connection.responseCode)
            val body = connection.inputStream.bufferedReader().readText()
            assertTrue(body.contains("gametranslator"))
            assertEquals("*", connection.getHeaderField("Access-Control-Allow-Origin"))
            assertEquals(404, (URL("http://127.0.0.1:$port/nope").openConnection() as HttpURLConnection).responseCode)
        } finally {
            server.stop()
        }
    }

    @Test
    fun eventStreamCarriesStyleSubtitleAndClear() {
        val server = SubtitleServer(port = 0)
        val port = server.start()
        // Bildirim sunucunun iş parçacığından gelir; test iş parçacığı güncel değeri görsün.
        val counts = java.util.concurrent.atomic.AtomicInteger(-1)
        server.onClientsChanged = { counts.set(it) }
        server.sendStyle(SubtitleStyle(fontSize = 58))
        try {
            Socket("127.0.0.1", port).use { socket ->
                socket.soTimeout = 3000
                socket.getOutputStream().write("GET /events HTTP/1.1\r\nHost: x\r\n\r\n".toByteArray())
                val reader = socket.getInputStream().bufferedReader(Charsets.UTF_8)
                fun readUntil(marker: String): String {
                    val text = StringBuilder()
                    while (!text.contains(marker)) text.append(reader.readLine() ?: break).append('\n')
                    return text.toString()
                }
                val head = readUntil("event: style")
                assertTrue(head.contains("text/event-stream"))
                assertTrue(readUntil("fontSize").contains("\"fontSize\":58"))
                var waited = 0
                while (server.connectedClients == 0 && waited++ < 100) Thread.sleep(10)
                assertEquals(1, server.connectedClients)
                server.sendSubtitle("Merhaba dünya", 15000, null, false)
                assertTrue(readUntil("Merhaba").contains("\"text\":\"Merhaba dünya\""))
                server.clear()
                assertTrue(readUntil("event: clear").contains("event: clear"))
            }
            var waited = 0
            // Kopan bağlantı bir sonraki yazmada fark edilir; yüklü makinede beklemek yetmeyebildiği için dürtülür.
            while ((server.connectedClients != 0 || counts.get() != 0) && waited++ < 500) {
                server.clear()
                Thread.sleep(10)
            }
            assertEquals(0, server.connectedClients)
            assertEquals(0, counts.get())
        } finally {
            server.stop()
        }
        assertNull(null)
    }
}
