// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.nio.file.Files

// CouchSubs'tan (Copyright (C) 2026 Sinan Yorulmaz, AGPL-3.0) uyarlanan denemeler.
class PackStoreTest {
    private class FakeServer(var packs: List<RemotePack>, val files: MutableMap<String, ByteArray>) : PackServer {
        val downloads = mutableListOf<String>()
        var status: Int? = null
        override fun list() = packs
        override fun download(id: String): ByteArray {
            status?.let { throw PackDownloadException(it, "HTTP $it") }
            downloads.add(id)
            return files[id] ?: throw PackDownloadException(404, "missing")
        }
    }

    private fun remote(id: String, data: ByteArray, version: Long = 1) = RemotePack(id, id.uppercase(), version, PackStore.sha256(data), data.size.toLong(), 1)

    private val gta = "gta".toByteArray()
    private val rdr = "rdr".toByteArray()

    @Test
    fun downloadsVerifiesAndReusesPacks() {
        val dir = Files.createTempDirectory("packs").toFile()
        var now = 1_000L
        val server = FakeServer(listOf(remote("gta-v", gta), remote("rdr2", rdr)), mutableMapOf("gta-v" to gta, "rdr2" to rdr))
        val store = PackStore(dir, server, { now })
        assertEquals(listOf("gta-v", "rdr2"), store.refresh().downloaded)
        assertEquals(setOf("gta-v.json.gz", "rdr2.json.gz"), store.files().map { it.name }.toSet())
        // Haftası dolmadan sunucuya bakılmaz.
        now += 60_000
        assertTrue(store.refresh().skipped)
        // Zorla yenilemede aynı sürüm yeniden inmez.
        assertEquals(emptyList<String>(), store.refresh(force = true).downloaded)
        assertEquals(listOf("gta-v", "rdr2"), server.downloads)
    }

    @Test
    fun weeklyRefreshUpdatesChangedAndRemovesDroppedPacks() {
        val dir = Files.createTempDirectory("packs").toFile()
        var now = 1_000L
        val server = FakeServer(listOf(remote("gta-v", gta), remote("rdr2", rdr)), mutableMapOf("gta-v" to gta, "rdr2" to rdr))
        val store = PackStore(dir, server, { now })
        store.refresh()
        val newGta = "gta v2".toByteArray()
        server.files["gta-v"] = newGta
        server.packs = listOf(remote("gta-v", newGta, version = 2))
        now += PackStore.REFRESH_INTERVAL_MS
        val result = store.refresh()
        assertEquals(listOf("gta-v"), result.downloaded)
        assertEquals(listOf("rdr2"), result.removed)
        assertEquals("gta v2", File(dir, "gta-v.json.gz").readText())
        assertFalse(File(dir, "rdr2.json.gz").exists())
        assertEquals(2L, store.installed().single().version)
    }

    @Test
    fun corruptDownloadIsNeverInstalled() {
        val dir = Files.createTempDirectory("packs").toFile()
        val server = FakeServer(listOf(remote("gta-v", gta)), mutableMapOf("gta-v" to "tampered".toByteArray()))
        val store = PackStore(dir, server)
        assertEquals(emptyList<String>(), store.refresh().downloaded)
        assertTrue(store.files().isEmpty())
        assertFalse(File(dir, "gta-v.json.gz").exists())
        // Kontrol zamanı ilerlemez: sonraki açılışta yeniden denenir.
        server.files["gta-v"] = gta
        assertEquals(listOf("gta-v"), store.refresh().downloaded)
    }

    @Test
    fun rateLimitedDownloadKeepsTheOldVersionAndRetries() {
        val dir = Files.createTempDirectory("packs").toFile()
        var now = 1_000L
        val server = FakeServer(listOf(remote("gta-v", gta)), mutableMapOf("gta-v" to gta))
        val store = PackStore(dir, server, { now })
        store.refresh()
        val newGta = "gta v2".toByteArray()
        server.files["gta-v"] = newGta
        server.packs = listOf(remote("gta-v", newGta, version = 2))
        server.status = 429
        now += PackStore.REFRESH_INTERVAL_MS
        assertEquals(emptyList<String>(), store.refresh().downloaded)
        assertEquals("gta", File(dir, "gta-v.json.gz").readText())
        // Kontrol zamanı ilerlemedi: sınır kalkınca hemen yeniden denenir.
        server.status = null
        now += 1000
        assertEquals(listOf("gta-v"), store.refresh().downloaded)
    }

    /** Uygulamayla gelen paketin aynısı indirilmez; sunucuda sürümü değişince iner. */
    @Test
    fun packsAlreadyInTheAppAreNotDownloaded() {
        val dir = Files.createTempDirectory("packs").toFile()
        var now = 1_000L
        var hashed = 0
        val server = FakeServer(listOf(remote("gta-v", gta), remote("rdr2", rdr)), mutableMapOf("gta-v" to gta, "rdr2" to rdr))
        val store = PackStore(dir, server, { now }, { hashed++; setOf(PackStore.sha256(gta)) })
        assertEquals(listOf("rdr2"), store.refresh().downloaded)
        assertEquals(listOf("rdr2"), server.downloads)
        assertEquals(listOf("rdr2.json.gz"), store.files().map { it.name })
        assertEquals(listOf("rdr2"), store.installed().map { it.id })
        assertEquals(1, hashed)
        // Haftası dolmadan bakılmaz; dolunca aynı sürümler için uygulamadaki dosyalar yeniden özetlenmez.
        assertTrue(store.refresh().skipped)
        now += PackStore.REFRESH_INTERVAL_MS
        assertEquals(emptyList<String>(), store.refresh().downloaded)
        assertEquals(1, hashed)
        val newGta = "gta v2".toByteArray()
        server.files["gta-v"] = newGta
        server.packs = listOf(remote("gta-v", newGta, version = 2), remote("rdr2", rdr))
        assertEquals(listOf("gta-v"), store.refresh(force = true).downloaded)
        assertEquals(setOf("gta-v.json.gz", "rdr2.json.gz"), store.files().map { it.name }.toSet())
    }

    @Test
    fun downloadedPacksLoadIntoTheLibrary() {
        val dir = Files.createTempDirectory("packs").toFile()
        val pack = Fixtures.bytes("pack-wrapped.json.gz")
        val store = PackStore(dir, FakeServer(listOf(remote("test-game", pack)), mutableMapOf("test-game" to pack)))
        store.refresh()
        val library = GamePackLibrary(null, store.files().first().parentFile)
        assertEquals(listOf("test-game"), library.infos.map { it.id })
        assertEquals("Yere yat!", library.find("Get Down!"))
    }
}
