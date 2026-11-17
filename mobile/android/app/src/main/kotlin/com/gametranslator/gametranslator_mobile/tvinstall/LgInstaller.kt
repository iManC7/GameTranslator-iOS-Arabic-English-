// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import com.jcraft.jsch.ChannelExec
import com.jcraft.jsch.JSch
import com.jcraft.jsch.JSchException
import com.jcraft.jsch.KeyPair
import com.jcraft.jsch.Session
import org.json.JSONException
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class CommandResult(val status: Int, val output: String)

/** TV'de komut çalıştırır; [input] verilirse komutun girişine akar ("cat > dosya"). */
interface RemoteShell : Closeable {
    fun run(command: String, input: ByteArray? = null): CommandResult
}

/** Key Server'dan alınan anahtar: parolasız PEM ya da (yeni biçimde) anahtar ve parolası. */
class LgKey(val text: String, val passphrase: String?) {
    fun toJson(): JSONObject = JSONObject().put("text", text).put("passphrase", passphrase ?: JSONObject.NULL)

    companion object {
        fun fromJson(json: JSONObject?): LgKey? {
            val text = json?.optString("text").orEmpty()
            if (text.isEmpty()) return null
            return LgKey(text, if (json!!.isNull("passphrase")) null else json.optString("passphrase"))
        }
    }
}

/**
 * LG geliştirici modunun SSH sunucusuna (9922, kullanıcı prisoner) bağlanır. TV'nin anahtarı her fabrika ayarında
 * değişir; anahtar denetlenmez (ssh'deki StrictHostKeyChecking=no gibi). webOS'un dropbear'ı eski algoritmalar
 * (ssh-rsa, SHA-1) kullanır; JSch bunları varsayılan olarak kapattığı için açıkça eklenir.
 */
class JschShell(private val host: String, private val key: LgKey, private val cancel: Cancel, private val port: Int = LgInstaller.SSH_PORT) : RemoteShell {
    private var session: Session? = null

    private fun session(): Session {
        session?.takeIf { it.isConnected }?.let { return it }
        cancel.check()
        val jsch = JSch()
        try {
            jsch.addIdentity("tv", key.text.toByteArray(Charsets.UTF_8), null, key.passphrase?.toByteArray(Charsets.UTF_8))
        } catch (error: JSchException) {
            throw TvInstallException(TvError.KEY_REFUSED, "anahtar okunamadı: ${error.message}", error)
        }
        val created = try {
            jsch.getSession("prisoner", host, port)
        } catch (error: JSchException) {
            throw TvInstallException(TvError.UNREACHABLE, error.message, error)
        }
        created.setConfig("StrictHostKeyChecking", "no")
        created.setConfig("PreferredAuthentications", "publickey")
        created.setConfig("server_host_key", append(JSch.getConfig("server_host_key"), "ssh-rsa,ssh-dss"))
        created.setConfig("PubkeyAcceptedAlgorithms", append(JSch.getConfig("PubkeyAcceptedAlgorithms"), "ssh-rsa"))
        created.setConfig("kex", append(JSch.getConfig("kex"), "diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1"))
        created.setConfig("cipher.s2c", append(JSch.getConfig("cipher.s2c"), "aes128-cbc,3des-cbc,aes256-cbc"))
        created.setConfig("cipher.c2s", append(JSch.getConfig("cipher.c2s"), "aes128-cbc,3des-cbc,aes256-cbc"))
        cancel.track(Closeable { created.disconnect() })
        try {
            created.connect(8_000)
            // Kurulum komutu sonucu dakikalarca bekleyebilir: bağlantı canlı tutulur.
            created.setServerAliveInterval(15_000)
            created.serverAliveCountMax = 8
        } catch (error: JSchException) {
            cancel.check()
            val message = error.message.orEmpty()
            val refused = message.contains("Auth fail", ignoreCase = true) || message.contains("Auth cancel", ignoreCase = true)
            throw TvInstallException(if (refused) TvError.KEY_REFUSED else TvError.UNREACHABLE, message, error)
        }
        session = created
        return created
    }

    override fun run(command: String, input: ByteArray?): CommandResult {
        val session = session()
        return cancel.guard {
            try {
                val channel = session.openChannel("exec") as ChannelExec
                channel.setCommand(command)
                val errors = ByteArrayOutputStream()
                channel.setErrStream(errors, true)
                val stdout = channel.inputStream
                val stdin = channel.outputStream
                channel.connect(10_000)
                if (input != null) {
                    var offset = 0
                    while (offset < input.size) {
                        cancel.check()
                        val n = minOf(32 * 1024, input.size - offset)
                        stdin.write(input, offset, n)
                        offset += n
                    }
                    stdin.flush()
                }
                // Giriş kapatılınca komut dosyanın bittiğini anlar.
                stdin.close()
                val output = stdout.readBytes()
                while (!channel.isClosed) cancel.sleep(50)
                val status = channel.exitStatus
                channel.disconnect()
                CommandResult(status, String(output, Charsets.UTF_8) + errors.toString("UTF-8"))
            } catch (error: JSchException) {
                throw TvInstallException(TvError.CONNECTION_LOST, error.message, error)
            } catch (error: IOException) {
                throw TvInstallException(TvError.CONNECTION_LOST, error.message, error)
            }
        }
    }

    override fun close() {
        session?.disconnect()
        session = null
    }

    companion object {
        /** Algoritma listesine eksik olanları sona ekler (JSch önce kendi güvenli seçeneklerini dener). */
        fun append(current: String?, extra: String): String {
            val list = current.orEmpty().split(',').filter { it.isNotBlank() }.toMutableList()
            for (item in extra.split(',')) if (item.isNotBlank() && item !in list) list.add(item)
            return list.joinToString(",")
        }
    }
}

/**
 * TV uygulamasını LG'nin geliştirici modu üzerinden kurar ve günceller (Windows'taki DevModeInstaller.cs).
 * Geliştirici modu açık TV 9922 portunda SSH bekler; anahtar Key Server'dan bir kez alınır.
 */
class LgInstaller(private val shell: RemoteShell, private val cancel: Cancel, private val pollIntervalMs: Long = 2_000) {
    /** TV'deki sürüm; uygulama kurulu değilse null. */
    fun installedVersion(): String? = versionFromAppInfo(shell.run("cat $APP_INFO_PATH").output)

    /**
     * Paketi TV'ye yükler ve ares-install'un yaptığı gibi kurar: kurulum aboneliği TV "installed" ya da hata diyene
     * kadar açık kalır, paket ancak bundan sonra silinir.
     */
    fun install(ipk: ByteArray, fileName: String, version: String, installTimeoutSeconds: Int = 180, onProgress: (String) -> Unit = {}) {
        val remote = "$TEMP_DIR/$fileName"
        onProgress("uploading:0")
        // Önceki denemelerden kalan paketler TV'de yer kaplamasın.
        val upload = shell.run("mkdir -p $TEMP_DIR && rm -f $TEMP_DIR/com.gametranslator.tv_*.ipk $TEMP_DIR/com.GameTranslator.tv_*.ipk && cat > '$remote'", ipk)
        if (upload.status != 0) throw failure("yükleme çıkış kodu ${upload.status}: ${short(upload.output)}", upload.output)
        onProgress("uploading:100")
        // Paket TV'ye eksiksiz ulaştı mı? (wc yoksa ya da çıktı okunamazsa denetim atlanır.)
        val size = shell.run("wc -c < '$remote'").output.trim().toLongOrNull()
        if (size != null && size != ipk.size.toLong())
            throw TvInstallException(TvError.INSTALL_FAILED, "paket TV'ye eksik ya da bozuk ulaştı: $size/${ipk.size} bayt")

        onProgress("installing")
        val response = shell.run(installCommand(remote, installTimeoutSeconds))
        val outcome = parseInstallReplies(response.output)
        if (outcome.failed) {
            remove(remote)
            throw failure(outcome.reason?.takeIf { it.isNotBlank() } ?: "kurulum başarısız: ${short(response.output)}", response.output)
        }
        // TV "installed" dese de (ya da sonucu okunamadıysa) sürüm appinfo.json'dan doğrulanır.
        onProgress("verifying")
        val limit = System.currentTimeMillis() + if (outcome.installed) 30_000 else 60_000
        while (true) {
            if (installedVersion() == version) {
                remove(remote)
                return
            }
            if (System.currentTimeMillis() >= limit) break
            cancel.sleep(pollIntervalMs)
        }
        if (outcome.installed) remove(remote)
        throw TvInstallException(TvError.INSTALL_FAILED, "TV'de $version sürümü görünmedi; kurulum yanıtı (${response.status}): ${short(response.output)}")
    }

    /** Uygulamayı açar; açılamazsa false (kullanıcı TV'den açar). */
    fun launch(server: String?): Boolean {
        val params = JSONObject().put("id", APP_ID)
        if (!server.isNullOrEmpty()) params.put("params", JSONObject().put("server", server))
        for (service in listOf("luna://com.webos.applicationManager/launch", "luna://com.webos.service.applicationmanager/launch")) {
            val result = runCatching { shell.run("/usr/bin/luna-send-pub -n 1 '$service' '$params'") }.getOrNull() ?: continue
            if (result.output.contains("\"returnValue\":true") || result.output.contains("\"returnValue\" : true")) return true
        }
        return false
    }

    /**
     * Geliştirici modunun 1000 saatlik süresini baştan başlatır (Developer Mode uygulamasının EXTEND düğmesi gibi).
     * Başarısız olursa null döner: süre dolmadan kullanıcı TV'den de uzatabilir.
     */
    fun renewSession(): Int? {
        val token = runCatching { shell.run("cat $SESSION_TOKEN_PATH").output.trim() }.getOrNull() ?: return null
        if (token.isEmpty() || token.contains(' ')) return null
        return try {
            val renewed = https("https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=${URLEncoder.encode(token, "UTF-8")}")
            if (!renewed.contains("success", ignoreCase = true)) return null
            remainingHours(https("https://developer.lge.com/secure/CheckDevModeSession.dev?sessionToken=${URLEncoder.encode(token, "UTF-8")}"))
        } catch (error: IOException) {
            null
        }
    }

    private fun https(url: String): String {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 10_000
        connection.readTimeout = 10_000
        return try {
            connection.inputStream.use { String(it.readBytes(), Charsets.UTF_8) }
        } finally {
            connection.disconnect()
        }
    }

    private fun remove(remote: String) {
        runCatching { shell.run("rm -f '$remote'") }
    }

    private fun failure(detail: String, evidence: String) =
        TvInstallException(if (isStorageProblem(evidence) || isStorageProblem(detail)) TvError.NOT_ENOUGH_SPACE else TvError.INSTALL_FAILED, detail)

    class InstallOutcome(val installed: Boolean, val failed: Boolean, val reason: String?)

    companion object {
        const val SSH_PORT = 9922
        const val KEY_PORT = 9991
        const val APP_ID = "com.gametranslator.tv"
        // Windows sürümü burada "com.GameTranslator.tv" yazıyor; paket küçük harfle kurulur (scripts/package-ipk.py, Swift sürümü).
        const val APP_INFO_PATH = "/media/developer/apps/usr/palm/applications/$APP_ID/appinfo.json"
        const val TEMP_DIR = "/media/developer/temp"
        private const val INSTALL_LOG = "$TEMP_DIR/GameTranslator-install.log"
        private const val SESSION_TOKEN_PATH = "/var/luna/preferences/devmode_enabled"

        /** Key Server'dan anahtarı alır ve TV ekranındaki parolayla çözer. */
        fun fetchKey(host: String, passphrase: String, cancel: Cancel): LgKey {
            val response = try {
                cancel.guard { LanHttp.get(host, KEY_PORT, "/webos_rsa", 5_000, cancel) }
            } catch (error: IOException) {
                cancel.check()
                throw TvInstallException(TvError.KEY_SERVER_OFF, error.message, error)
            }
            if (response.status != 200 || response.body.isEmpty()) throw TvInstallException(TvError.KEY_SERVER_OFF, "HTTP ${response.status}")
            val pem = response.text
            if (LegacyPemKey.isLegacyEncrypted(pem)) return LgKey(LegacyPemKey.decryptWithCaseFallback(pem, passphrase), null)
            // Başka biçim (ör. OpenSSH): JSch parolayı kendisi çözer; burada yalnız denenir.
            for (candidate in listOf(passphrase.trim(), passphrase.trim().uppercase()).distinct()) {
                val pair = try {
                    KeyPair.load(JSch(), response.body, null)
                } catch (error: JSchException) {
                    throw TvInstallException(TvError.INSTALL_FAILED, "anahtar okunamadı: ${error.message}", error)
                }
                if (!pair.isEncrypted) return LgKey(pem, null)
                if (pair.decrypt(candidate)) return LgKey(pem, candidate)
            }
            throw TvInstallException(TvError.WRONG_PASSPHRASE)
        }

        fun versionFromAppInfo(text: String): String? = Regex("\"version\"\\s*:\\s*\"([^\"]+)\"").find(text)?.groupValues?.get(1)

        /**
         * TV'de kurulumu başlatan kabuk komutu (Windows'taki InstallCommand ile aynı). `luna-send-pub -i` girişi açık
         * kaldıkça aboneliği sürdürür; giriş `sleep`'ten gelir. Yanıtlar dosyaya yazılır; TV "installed" ya da hata
         * dediğinde, luna-send kendiliğinden çıktığında ya da süre dolduğunda yanıtlar basılır.
         */
        fun installCommand(remotePackage: String, waitSeconds: Int): String {
            val parameters = "{\"id\":\"com.ares.defaultName\",\"ipkUrl\":\"$remotePackage\",\"subscribe\":true}"
            return listOf(
                "rm -f $INSTALL_LOG",
                "sleep ${waitSeconds + 30} </dev/null 2>/dev/null | /usr/bin/luna-send-pub -i 'luna://com.webos.appInstallService/dev/install' '$parameters' >$INSTALL_LOG 2>&1 & L=\$!",
                "i=0",
                "while [ \$i -lt $waitSeconds ]; do grep -q -i -e '\"state\" *: *\"installed' -e 'failed' -e '\"returnValue\" *: *false' -e '\"state\" *: *\"success' $INSTALL_LOG 2>/dev/null && break; kill -0 \$L 2>/dev/null || break; sleep 1; i=\$((i+1)); done",
                "cat $INSTALL_LOG",
                "kill \$L 2>/dev/null",
                "rm -f $INSTALL_LOG",
            ).joinToString("; ")
        }

        /**
         * luna-send'in satır satır JSON yanıtlarını ares-install gibi okur: `returnValue: false` ya da `details.state`
         * içinde FAILED hata, `installed`/`SUCCESS` başarıdır.
         */
        fun parseInstallReplies(output: String): InstallOutcome {
            var pending = ""
            for (line in output.split('\n')) {
                pending += line.trim()
                if (pending.isEmpty()) continue
                if (!pending.startsWith("{")) {
                    pending = "" // luna-send'in kendi yazısı (ör. "Error: ..."); ares de JSON olmayanı atlar.
                    continue
                }
                val reply = try {
                    JSONObject(pending)
                } catch (error: JSONException) {
                    continue // satır yarım; sonrakiyle birleşir
                }
                pending = ""
                val details = reply.optJSONObject("details")
                val state = text(details, "state") ?: ""
                if (reply.has("returnValue") && reply.opt("returnValue") == false)
                    return InstallOutcome(false, true, reason(text(reply, "errorText") ?: text(reply, "errorMessage"), text(reply, "errorCode")))
                if (state.contains("failed", ignoreCase = true))
                    return InstallOutcome(false, true, reason(text(details, "reason") ?: text(details, "errorText") ?: state,
                        text(details, "errorCode") ?: text(reply, "errorCode")))
                if (state.contains("installed", ignoreCase = true) || state.startsWith("success", ignoreCase = true))
                    return InstallOutcome(true, false, null)
            }
            return InstallOutcome(false, false, null)
        }

        fun isStorageProblem(text: String) = AndroidTvInstaller.isStorageProblem(text)

        /** LG'nin yanıtındaki kalan süre `999:58:40` (saat:dakika:saniye) biçimindedir. */
        fun remainingHours(response: String): Int? = Regex("(\\d{1,4}):(\\d{2}):(\\d{2})").find(response)?.groupValues?.get(1)?.toInt()

        private fun reason(text: String?, code: String?): String {
            val reason = (text ?: "").trim()
            return if (code.isNullOrBlank()) reason else "$reason (errorCode $code)".trim()
        }

        private fun text(element: JSONObject?, name: String): String? {
            if (element == null || !element.has(name) || element.isNull(name)) return null
            val value: Any? = element.opt(name)
            return if (value is String) value else if (value is Number) value.toString() else null
        }

        private fun short(text: String) = if (text.length <= 500) text.trim() else text.substring(0, 500).trim() + "…"
    }
}
