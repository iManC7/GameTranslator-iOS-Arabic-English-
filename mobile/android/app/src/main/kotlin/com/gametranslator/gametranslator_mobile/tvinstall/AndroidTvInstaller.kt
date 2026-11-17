// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.io.File
import java.io.IOException
import java.net.SocketTimeoutException

/**
 * GameTranslator'ın Android TV uygulamasını ağ üzerinden kurar (Windows'taki AndroidTvInstaller.cs). TV'de geliştirici
 * seçenekleri ve USB/ağ hata ayıklaması açık olmalıdır; Android TV'lerin çoğu bu ayarla 5555 portunda ADB bekler.
 */
class AndroidTvInstaller(host: String, private val keyFile: File, port: Int = DEFAULT_PORT) {
    private val host: String
    private val port: Int

    init {
        // "192.168.1.20:5555" gibi yazılmış adres de kabul edilir.
        val parts = host.trim().split(':')
        this.host = parts[0].trim()
        this.port = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: port
    }

    /** Kurulum sırasında TV'nin onay sorusunu göstermesi. */
    var onApprovalNeeded: () -> Unit = {}

    /** "connecting", "approve", "checking", "uploading:<yüzde>", "installing", "launching" */
    var onProgress: (String) -> Unit = {}

    class Result(val version: String, val installed: Boolean)

    /** TV'deki sürüm; kurulu değilse null. */
    fun installedVersion(cancel: Cancel): String? = connect(cancel).use { adb ->
        cancel.guard { versionFromDumpsys(adb.run("shell:dumpsys package $PACKAGE_NAME")) }
    }

    /**
     * Uygulama eksikse ya da eskiyse kurar ve açar; hepsi tek bağlantıda yapılır, TV onayı en çok bir kez sorulur.
     * [server]: TV uygulamasının bağlanacağı altyazı sunucusu (ör. http://telefon:8787).
     */
    fun ensureInstalled(apk: ByteArray, version: String, cancel: Cancel, server: String? = null, force: Boolean = false): Result {
        onProgress("connecting")
        val adb = connect(cancel)
        try {
            return cancel.guard {
                adb.timeout(60_000)
                onProgress("checking")
                // Çok kullanıcılı Android TV'ler (ör. TCL / Google TV profilleri) için paketi etkin kullanıcıya da bağla.
                adb.run("shell:cmd package install-existing $PACKAGE_NAME")
                val installed = versionFromDumpsys(adb.run("shell:dumpsys package $PACKAGE_NAME"))
                if (!force && installed != null && !Versions.isNewer(version, installed)) {
                    onProgress("launching")
                    if (!launch(adb, server).contains("Error")) return@guard Result(installed, false)
                }
                install(adb, apk, cancel)
                onProgress("launching")
                launch(adb, server)
                Result(version, true)
            }
        } catch (error: SocketTimeoutException) {
            throw TvInstallException(TvError.CONNECTION_LOST, error.message, error)
        } catch (error: IOException) {
            throw TvInstallException(TvError.CONNECTION_LOST, error.message, error)
        } finally {
            adb.close()
            cancel.untrack(adb)
        }
    }

    /** Uygulamayı açar (kuruluysa). */
    fun launchOnly(cancel: Cancel, server: String? = null): Boolean = connect(cancel).use { adb ->
        cancel.guard { !launch(adb, server).contains("Error") }
    }

    private fun connect(cancel: Cancel): AdbClient {
        val key = Adb.loadOrCreateKey(keyFile)
        val client = AdbClient.connect(host, port, key, AdbOptions.ADB, cancel, onApprovalNeeded = {
            onProgress("approve")
            onApprovalNeeded()
        })
        return cancel.track(client)
    }

    private fun launch(adb: AdbClient, server: String?): String {
        val extra = if (server.isNullOrEmpty()) "" else " --es params '{\"server\":\"$server\"}' --es server '$server'"
        var result = adb.run("shell:am start -n $PACKAGE_NAME/.MainActivity$extra")
        if (result.contains("Error")) {
            // Uygulama başka bir kullanıcıya (TV profili) kurulmuş olabilir: etkin kullanıcıya bağlayıp yeniden dene.
            val user = adb.run("shell:am get-current-user").trim()
            if (user.isNotEmpty() && user.all { it.isDigit() }) {
                adb.run("shell:cmd package install-existing --user $user $PACKAGE_NAME")
                result = adb.run("shell:am start --user $user -n $PACKAGE_NAME/.MainActivity$extra")
            }
        }
        return result
    }

    /** APK'yı kurar. İmzası farklı eski bir kopya varsa önce onu kaldırır. */
    private fun install(adb: AdbClient, apk: ByteArray, cancel: Cancel) {
        adb.timeout(180_000)
        var result = streamInstall(adb, apk)
        if (result.contains("INSTALL_FAILED_UPDATE_INCOMPATIBLE") || result.contains("INSTALL_FAILED_VERSION_DOWNGRADE")) {
            cancel.check()
            adb.run("shell:pm uninstall $PACKAGE_NAME")
            result = streamInstall(adb, apk)
        }
        if (!result.contains("Success")) {
            val error = if (isStorageProblem(result)) TvError.NOT_ENOUGH_SPACE else TvError.INSTALL_FAILED
            throw TvInstallException(error, result.trim().take(500))
        }
    }

    private fun streamInstall(adb: AdbClient, apk: ByteArray): String {
        onProgress("uploading:0")
        // Android 7 ve sonrası: dosyayı TV'ye ayrıca kopyalamadan doğrudan paket yöneticisine akıtır.
        val result = try {
            adb.run("exec:cmd package install -r -d -g -S ${apk.size}", apk) { sent -> onProgress("uploading:${sent * 100L / apk.size}") }
        } catch (error: TvInstallException) {
            if (error.error != TvError.INSTALL_FAILED) throw error
            "" // exec: hizmeti yok (çok eski Android)
        }
        if (!needsLegacyInstall(result)) {
            onProgress("installing")
            return result
        }
        // Android 6 ve öncesi: "cmd package" yok. Dosya sync ile geçici klasöre yazılır, pm ile kurulur.
        val remote = "/data/local/tmp/gametranslator-tv.apk"
        adb.push(apk, remote) { sent -> onProgress("uploading:${sent * 100L / apk.size}") }
        onProgress("installing")
        val output = adb.run("shell:pm install -r -d $remote")
        runCatching { adb.run("shell:rm -f $remote") }
        return output
    }

    companion object {
        const val DEFAULT_PORT = 5555
        const val PACKAGE_NAME = "com.gametranslator.tv"

        fun versionFromDumpsys(output: String): String? = Regex("versionName=(\\S+)").find(output)?.groupValues?.get(1)

        /** "cmd package" komutu bu Android'de yoksa. */
        fun needsLegacyInstall(output: String): Boolean {
            val text = output.lowercase()
            return text.contains("unknown command") || text.contains("cmd: not found") || text.contains("can't find service") ||
                text.contains("inaccessible or not found") || (text.isBlank())
        }

        fun isStorageProblem(text: String): Boolean = Regex(
            "no space|not enough (free )?(space|storage)|insufficient (free )?(space|storage)|out of space|storage (is )?full|disk (is )?full|ENOSPC|lack of (space|storage)|INSTALL_FAILED_INSUFFICIENT_STORAGE",
            RegexOption.IGNORE_CASE,
        ).containsMatchIn(text)
    }
}
