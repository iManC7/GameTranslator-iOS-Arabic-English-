// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Windows'taki GlossaryTests, TurkishSuffixTests ve TermProtectionTests ile aynı durumlar. */
class GlossaryTest {
    private val gow = Glossary.of(
        mapOf("Leviathan Axe" to "Leviathan Baltası", "Axe" to "Balta", "Midgard" to "Midgard", "World Serpent" to "Dünya Yılanı"),
        listOf("Kratos", "Atreus"))

    @Test
    fun parsesTermsAndKeepNames() {
        assertEquals(6, gow.count)
        assertEquals("Leviathan Baltası", gow.turkish("leviathan  axe"))
        assertEquals("Kratos", gow.turkish("KRATOS"))
        assertNull(gow.turkish("Freya"))
        assertEquals(1, Glossary.of(mapOf("..." to "x", "Odin" to "Odin", "" to "y")).count)
    }

    @Test
    fun findsWholeWordsCaseInsensitiveLongestFirst() {
        val found = gow.find("THROW THE LEVIATHAN AXE, then the axe. Kratos's axes. Midgardian.")
        assertEquals(listOf("Leviathan Axe", "Axe", "Kratos"), found.map { it.english })
        assertEquals(10, found[0].start)
    }
}

class TurkishSuffixTest {
    private fun check(vararg cases: Triple<String, String, String>) {
        for ((term, suffix, expected) in cases) assertEquals("$term + $suffix", expected, TurkishSuffix.attach(term, suffix))
    }

    @Test
    fun properNounsTakeHarmonizedSuffixWithApostrophe() = check(
        Triple("Kratos", "u", "Kratos'u"), Triple("Kratos", "un", "Kratos'un"), Triple("Kratos", "a", "Kratos'a"),
        Triple("Kratos", "da", "Kratos'ta"), Triple("Kratos", "dan", "Kratos'tan"), Triple("Kratos", "la", "Kratos'la"),
        Triple("Kratos", "dur", "Kratos'tur"), Triple("Atreus", "un", "Atreus'un"), Triple("Midgard", "a", "Midgard'a"),
        Triple("Midgard", "da", "Midgard'da"), Triple("Midgard", "u", "Midgard'ı"), Triple("Midgard", "un", "Midgard'ın"),
        Triple("Midgard", "daki", "Midgard'daki"), Triple("Freya", "u", "Freya'yı"), Triple("Freya", "a", "Freya'ya"),
        Triple("Freya", "un", "Freya'nın"), Triple("Freya", "la", "Freya'yla"), Triple("Freya", "da", "Freya'da"),
        Triple("Mimir", "a", "Mimir'e"), Triple("Mimir", "u", "Mimir'i"), Triple("Mimir", "dan", "Mimir'den"),
        Triple("Brok", "da", "Brok'ta"), Triple("Jötunheim", "a", "Jötunheim'e"), Triple("Thor", "un", "Thor'un"),
        Triple("Sindri", "un", "Sindri'nin"), Triple("Sindri", "u", "Sindri'yi"), Triple("Odin", "ya", "Odin'e"),
        Triple("Freya", "nın", "Freya'nın"), Triple("Kratos", "nın", "Kratos'un"), Triple("Kratos", "", "Kratos"))

    @Test
    fun compoundNamesTakeTheBufferN() = check(
        Triple("Leviathan Baltası", "u", "Leviathan Baltası'nı"), Triple("Leviathan Baltası", "a", "Leviathan Baltası'na"),
        Triple("Leviathan Baltası", "da", "Leviathan Baltası'nda"), Triple("Leviathan Baltası", "dan", "Leviathan Baltası'ndan"),
        Triple("Leviathan Baltası", "un", "Leviathan Baltası'nın"), Triple("Leviathan Baltası", "la", "Leviathan Baltası'yla"),
        Triple("Dünya Ağacı", "a", "Dünya Ağacı'na"), Triple("Kaos Bıçakları", "u", "Kaos Bıçakları'nı"))

    @Test
    fun commonNounsAreWrittenTogether() = check(
        Triple("can iksiri", "u", "can iksirini"), Triple("kontrol noktası", "a", "kontrol noktasına"),
        Triple("bekleme süresi", "da", "bekleme süresinde"), Triple("envanter", "a", "envantere"),
        Triple("kılıç", "u", "kılıcı"), Triple("kitap", "u", "kitabı"), Triple("bıçak", "u", "bıçağı"),
        Triple("renk", "u", "rengi"), Triple("top", "u", "topu"), Triple("balta", "u", "baltayı"),
        Triple("balta", "lar", "baltalar"), Triple("kalkan", "dan", "kalkandan"), Triple("kalkan", "la", "kalkanla"))
}

class TermProtectionTest {
    private val gow = Glossary.of(
        mapOf("Leviathan Axe" to "Leviathan Baltası", "Midgard" to "Midgard", "health potion" to "can iksiri"),
        listOf("Kratos", "Atreus"))

    @Test
    fun replacesTermsWithPlaceholderNames() {
        val (text, slots) = TermProtector(gow, "").protect("Kratos, take the Leviathan Axe to Midgard. Kratos!")
        assertEquals("Zarmon, take the Velkor to Dorvan. Zarmon!", text)
        assertEquals(listOf("Kratos", "Leviathan Axe", "Midgard"), slots.map { it.english })
    }

    @Test
    fun restoresTermsWithSuffixesDespiteCaseAndSpacing() {
        val cases = mapOf(
            "Zarmon, Velkor'u Dorvan'a götür. Zarmon!" to "Kratos, Leviathan Baltası'nı Midgard'a götür. Kratos!",
            "ZARMON, VELKOR'U DORVAN'A GÖTÜR. ZARMON!" to "Kratos, Leviathan Baltası'nı Midgard'a GÖTÜR. Kratos!",
            "Zarmon, Velkor ’u Dorvana götür. Zarmon!" to "Kratos, Leviathan Baltası'nı Midgard'a götür. Kratos!")
        for ((output, expected) in cases) {
            val protector = TermProtector(gow, "")
            val (_, slots) = protector.protect("Kratos, take the Leviathan Axe to Midgard. Kratos!")
            assertEquals(expected, TermProtector.restore(output, slots, protector.allSlots))
        }
    }

    @Test
    fun missingOrForeignPlaceholderMeansUnreliable() {
        val protector = TermProtector(gow, "")
        val (_, slots) = protector.protect("Take the Leviathan Axe to Midgard.")
        assertNull(TermProtector.restore("Baltayı Dorvan'a götür.", slots, protector.allSlots))

        val other = TermProtector(gow, "")
        other.protect("Kratos!")
        val (_, second) = other.protect("Go to Midgard.")
        assertNull(TermProtector.restore("Zarmon Velkor'a git.", second, other.allSlots))
        assertEquals("Midgard'a git.", TermProtector.restore("Velkor'a git.", second, other.allSlots))
    }

    @Test
    fun commonNounAtSentenceStartIsCapitalizedAndQuotesAreNotSuffixes() {
        val (_, slots) = TermProtector(gow, "").protect("Drink the health potion. Health potion first!")
        assertEquals("Can iksirini iç. Önce can iksiri!", TermProtector.restore("Zarmon'u iç. Önce Zarmon!", slots))
        val (_, quoted) = TermProtector(gow, "").protect("He said 'Midgard' again.")
        assertEquals("Yine 'Midgard' dedi.", TermProtector.restore("Yine 'Zarmon' dedi.", quoted))
    }

    @Test
    fun placeholderAlreadyInTheSourceIsSkipped() =
        assertEquals("Zarmon met Velkor.", TermProtector(gow, "Zarmon met Kratos.").protect("Zarmon met Kratos.").first)

    @Test
    fun translatorProtectsTermsAndFallsBackWhenAPlaceholderIsLost() {
        val seen = ArrayList<String>()
        val good = GlossaryTranslator(gow) { text ->
            seen.add(text)
            if ("Zarmon" in text) "Zarmon'a git." else "Şimdi gidiyoruz."
        }
        assertEquals("Midgard'a git.", good.translate("Go to Midgard."))
        assertEquals("Şimdi gidiyoruz.", good.translate("We go now."))
        assertEquals(listOf("Go to Zarmon.", "We go now."), seen)

        val lossy = GlossaryTranslator(gow) { text -> if ("Zarmon" in text) "Oraya git." else "Midgard'a git." }
        assertEquals("Midgard'a git.", lossy.translate("Go to Midgard."))
        assertNull(GlossaryTranslator(gow) { null }.translate("Go to Midgard."))
    }
}

class SpeakerPrefixTest {
    @Test
    fun splitsDashAndChevronMarkers() {
        assertEquals("- " to "Where are you going?", SpeakerPrefix.split("- Where are you going?"))
        assertEquals("— " to "Run!", SpeakerPrefix.split("  — Run!  "))
        assertEquals(">> " to "Stay close.", SpeakerPrefix.split(">> Stay close."))
        assertEquals(">>" to "Go.", SpeakerPrefix.split(">>Go."))
        assertEquals("" to "No marker here - just a dash inside.", SpeakerPrefix.split("No marker here - just a dash inside."))
        assertEquals("-" to "", SpeakerPrefix.split("- "))
    }

    @Test
    fun translatorKeepsTheMarkerOutOfTheEngine() {
        val seen = ArrayList<String>()
        val translator = PrefixTranslator { text ->
            seen.add(text)
            if (text == "Where are you going?") "Nereye gidiyorsun?" else "Dikkat et."
        }
        assertEquals("- Nereye gidiyorsun?", translator.translate("- Where are you going?"))
        assertEquals("Dikkat et.", translator.translate("Be careful."))
        assertEquals(listOf("Where are you going?", "Be careful."), seen)
        assertEquals("-", translator.translate("- "))
        assertNull(PrefixTranslator { null }.translate(">> Hold on."))
        assertNull(PrefixTranslator { "  " }.translate(">> Hold on."))
    }
}
