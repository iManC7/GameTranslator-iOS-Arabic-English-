// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs'tan uyarlandı: CouchSubs (Copyright (C) 2026 Sinan Yorulmaz), AGPL-3.0, yazarının izniyle.
// Kaynak: couchsubs-android/app/src/main/java/com/couchsubs/mobile/packs/PackStore.kt
package com.gametranslator.gametranslator_mobile.core

import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/** Sunucudaki bir paket (GET /v1/packs). */
data class RemotePack(val id: String, val title: String, val version: Long, val sha256: String, val size: Long, val entries: Int)

/** Paket indirilemedi; [status] HTTP kodu (429: sınır aşıldı), ağ hatasında null. */
class PackDownloadException(val status: Int?, message: String) : IOException(message)

/** Paket sunucusu (gerçeği [HttpPackServer]; testlerde sahtesi). */
interface PackServer {
    fun list(): List<RemotePack>
    fun download(id: String): ByteArray
}

/**
 * Sunucudaki yeni ve güncellenen oyun paketleri (ücretsiz, hesapsız): sunucudan indirilir, SHA-256 ile doğrulanıp
 * uygulamanın klasöründe saklanır, haftada bir yenilenir. Sürümü değişmeyen paket yeniden indirilmez; sunucudan kalkan
 * paket silinir. Bozuk ya da yarım dosya hiçbir zaman yüklenmez (önce geçici dosyaya yazılır, doğrulanınca yerine
 * konur). Uygulamayla gelen paketlerle aynı kimlikteki indirilmiş paket onların yerine geçer (bkz. GamePackLibrary).
 *
 * [bundledHashes]: uygulamayla gelen paket dosyalarının SHA-256'ları (küçük harf hex). Sunucudaki paket bunlardan
 * biriyle aynıysa indirilmez (uygulamada zaten var); yalnız gerekince ve yenileme başına bir kez hesaplanır.
 */
class PackStore(
    private val directory: File,
    private val server: PackServer,
    private val clock: () -> Long = System::currentTimeMillis,
    private val bundledHashes: () -> Set<String> = { emptySet() },
) {
    companion object {
        const val REFRESH_INTERVAL_MS = 7L * 24 * 60 * 60 * 1000
        /** CouchSubs'ın paket sunucusu (yazarının izniyle; aynı paket biçimi). */
        const val DEFAULT_URL = "https://couchsubs-packs.enmera.workers.dev"
        private const val MANIFEST = "packs.state"

        fun sha256(data: ByteArray): String =
            MessageDigest.getInstance("SHA-256").digest(data).joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }

    /** [bundled]: sunucudaki sürüm uygulamayla gelenle aynı; dosyası yok. */
    data class Local(val id: String, val title: String, val version: Long, val sha256: String, val bundled: Boolean = false)

    /** Yenilemenin sonucu: indirilen ve silinen paketler; [skipped] true ise süresi gelmediği için bakılmadı. */
    data class Refresh(val downloaded: List<String> = emptyList(), val removed: List<String> = emptyList(), val skipped: Boolean = false)

    private val lock = Any()

    /** Klasör (GamePackLibrary'nin kullanıcı klasörü olarak verilir). */
    val folder: File get() = directory

    /** Doğrulanmış, yüklenmeye hazır paket dosyaları. */
    fun files(): List<File> = synchronized(lock) {
        manifest().second.filter { !it.bundled }.mapNotNull { local -> packFile(local.id).takeIf { it.isFile } }
    }

    fun installed(): List<Local> = synchronized(lock) { manifest().second.filter { !it.bundled } }

    val lastCheck: Long get() = synchronized(lock) { manifest().first }

    /**
     * Süresi geldiyse (ya da [force]) sunucuya bakar ve değişen paketleri indirir (bloklar). Liste alınamazsa elde
     * olanlar kalır; inemeyen paket bir sonraki açılışta yeniden denenir.
     */
    fun refresh(force: Boolean = false): Refresh = synchronized(lock) {
        val (checked, current) = manifest()
        if (!force && current.isNotEmpty() && clock() - checked < REFRESH_INTERVAL_MS) return Refresh(skipped = true)
        val remote = server.list()
        directory.mkdirs()
        val kept = mutableListOf<Local>()
        val downloaded = mutableListOf<String>()
        var bundled: Set<String>? = null
        for (pack in remote) {
            val existing = current.firstOrNull { it.id == pack.id }
            val file = packFile(pack.id)
            if (existing != null && existing.bundled && existing.version == pack.version && existing.sha256.equals(pack.sha256, ignoreCase = true)) {
                kept.add(existing)
                continue
            }
            if (existing != null && !existing.bundled && existing.version == pack.version && existing.sha256.equals(pack.sha256, ignoreCase = true) &&
                file.isFile && sha256(file.readBytes()).equals(pack.sha256, ignoreCase = true)
            ) {
                kept.add(existing)
                continue
            }
            // Uygulamayla gelen paketin aynısı indirilmez.
            val inApp = bundled ?: runCatching { bundledHashes() }.getOrDefault(emptySet()).also { bundled = it }
            if (pack.sha256.lowercase() in inApp) {
                file.delete()
                kept.add(Local(pack.id, pack.title, pack.version, pack.sha256.lowercase(), bundled = true))
                continue
            }
            val data = try {
                server.download(pack.id)
            } catch (error: PackDownloadException) {
                // Bu paket şimdi inmedi: eski sürümü varsa o kalır, sonraki yenilemede yeniden denenir.
                if (existing != null && !existing.bundled && file.isFile) kept.add(existing.copy(version = -1))
                continue
            }
            if (!sha256(data).equals(pack.sha256, ignoreCase = true)) {
                if (existing != null && !existing.bundled && file.isFile) kept.add(existing.copy(version = -1))
                continue
            }
            val temporary = File(directory, "${pack.id}.download")
            temporary.writeBytes(data)
            if (!temporary.renameTo(file)) {
                file.delete()
                if (!temporary.renameTo(file)) throw IOException("cannot store ${pack.id}")
            }
            kept.add(Local(pack.id, pack.title, pack.version, pack.sha256.lowercase()))
            downloaded.add(pack.id)
        }
        val removed = current.filter { local -> !local.bundled && remote.none { it.id == local.id } }.map { it.id }
        removed.forEach { packFile(it).delete() }
        // Bir paket inemediyse (sürüm -1) bir sonraki açılışta yeniden denensin diye kontrol zamanı ilerletilmez.
        val retry = kept.any { it.version == -1L }
        writeManifest(if (retry) checked else clock(), kept)
        Refresh(downloaded, removed)
    }

    /** "İndirilen paketleri sil". */
    fun clear() = synchronized(lock) { directory.listFiles()?.forEach { it.delete() } }

    private fun packFile(id: String) = File(directory, "$id.json.gz")

    private fun manifest(): Pair<Long, List<Local>> {
        val file = File(directory, MANIFEST)
        if (!file.isFile) return 0L to emptyList()
        return try {
            val json = JSONObject(file.readText())
            val packs = json.optJSONArray("packs")
            val list = (0 until (packs?.length() ?: 0)).mapNotNull { packs!!.optJSONObject(it) }.map {
                Local(it.getString("id"), it.optString("title", it.getString("id")), it.optLong("version"), it.optString("sha256"),
                    it.optBoolean("bundled", false))
            }
            json.optLong("checked") to list
        } catch (error: JSONException) {
            0L to emptyList()
        }
    }

    private fun writeManifest(checked: Long, packs: List<Local>) {
        val json = JSONObject().put("checked", checked).put("packs", org.json.JSONArray(packs.map {
            JSONObject().put("id", it.id).put("title", it.title).put("version", it.version).put("sha256", it.sha256).put("bundled", it.bundled)
        }))
        val temporary = File(directory, "$MANIFEST.tmp")
        temporary.writeText(json.toString())
        if (!temporary.renameTo(File(directory, MANIFEST))) {
            File(directory, MANIFEST).delete()
            temporary.renameTo(File(directory, MANIFEST))
        }
    }
}

/** Paket sunucusu: GET /v1/packs (liste), GET /v1/packs/{id} (gzip'li paket). */
class HttpPackServer(private val baseUrl: String) : PackServer {
    override fun list(): List<RemotePack> {
        val body = String(request("$baseUrl/v1/packs"), Charsets.UTF_8)
        val packs = JSONObject(body).optJSONArray("packs") ?: return emptyList()
        return (0 until packs.length()).map { index ->
            val item = packs.getJSONObject(index)
            RemotePack(item.getString("id"), item.optString("title"), item.optLong("version"), item.getString("sha256"),
                item.optLong("size"), item.optInt("entries"))
        }
    }

    override fun download(id: String): ByteArray = request("$baseUrl/v1/packs/$id")

    private fun request(url: String): ByteArray {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = 15_000
            connection.readTimeout = 60_000
            val status = connection.responseCode
            if (status !in 200..299) throw PackDownloadException(status, "HTTP $status")
            return connection.inputStream.use { it.readBytes() }
        } catch (error: PackDownloadException) {
            throw error
        } catch (error: IOException) {
            throw PackDownloadException(null, error.message ?: "network")
        } finally {
            connection.disconnect()
        }
    }
}
