// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors

/** Uygulamanın içinde gelen TV paketi (assets/tv-app). */
class BundledApp(val asset: String, val version: String) {
    val fileName: String get() = asset.substringAfterLast('/')
}

/** Kurulan TV'nin kaydı: güncellemeler aynı TV'ye yeniden kurulabilsin diye. */
class TvStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("tvinstall", Context.MODE_PRIVATE)

    var tv: Map<String, Any?>?
        get() {
            val json = prefs.getString("tv", null)?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return null
            return mapOf(
                "brand" to json.optString("brand"),
                "host" to json.optString("host"),
                "name" to json.optString("name"),
                "version" to json.optString("version").ifEmpty { null },
                "installedAt" to json.optLong("installedAt"),
            )
        }
        set(value) = prefs.edit().apply {
            if (value == null) remove("tv") else putString("tv", JSONObject(value).toString())
        }.apply()

    /** LG anahtarı TV'ye göre: parola bir kez sorulur. */
    fun lgKey(host: String): LgKey? = prefs.getString("lgkey:$host", null)?.let { runCatching { LgKey.fromJson(JSONObject(it)) }.getOrNull() }

    fun setLgKey(host: String, key: LgKey?) = prefs.edit().apply {
        if (key == null) remove("lgkey:$host") else putString("lgkey:$host", key.toJson().toString())
    }.apply()
}

/**
 * Telefondan TV uygulaması kurma sihirbazının köprüsü: "gt/tv" yöntem kanalı ve "gt/tv/events" ilerleme akışı.
 * Ağ işleri arka plandaki iş parçacıklarında yapılır; aynı anda tek kurulum çalışır ve "cancel" ile kesilir.
 */
class TvInstallChannel private constructor(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())
    private val background = Executors.newCachedThreadPool()
    private val store = TvStore(activity)
    private var events: EventChannel.EventSink? = null

    @Volatile
    private var job: Cancel? = null

    private fun emit(stage: String) {
        main.post { events?.success(mapOf("stage" to stage)) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "bundled" -> result.success(bundled().mapKeys { it.key.name.lowercase() }.mapValues { it.value.version })
            "phoneAddress" -> result.success(LocalNetwork.privateAddresses().firstOrNull())
            "saved" -> result.success(store.tv)
            "forget" -> {
                store.tv?.get("host")?.let { store.setLgKey(it as String, null) }
                store.tv = null
                result.success(null)
            }
            "normalize" -> result.success(ManualAddress.normalize(call.arguments as? String))
            "find" -> {
                val brand = brandOf(call.arguments as? String) ?: return result.error("bad_brand", "marka", null)
                val cancel = Cancel()
                job = cancel
                async(result) { TvDiscovery.find(brand, cancel).map { it.toMap() } }
            }
            "check" -> {
                val brand = brandOf(call.argument<String>("brand")) ?: return result.error("bad_brand", "marka", null)
                val host = call.argument<String>("host") ?: return result.error("bad_host", "adres", null)
                async(result) {
                    mapOf(
                        "ready" to TvDiscovery.isReady(brand, host),
                        "keyServer" to (brand == TvBrand.LG && TvDiscovery.isKeyServerOn(host)),
                        "hasKey" to (brand == TvBrand.LG && store.lgKey(host) != null),
                    )
                }
            }
            "install" -> {
                val brand = brandOf(call.argument<String>("brand")) ?: return result.error("bad_brand", "marka", null)
                val host = call.argument<String>("host") ?: return result.error("bad_host", "adres", null)
                val name = call.argument<String>("name") ?: ""
                val passphrase = call.argument<String>("passphrase")
                val force = call.argument<Boolean>("force") ?: false
                job?.cancel()
                val cancel = Cancel()
                job = cancel
                async(result) { install(brand, host, name, passphrase, force, cancel) }
            }
            "cancel" -> {
                job?.cancel()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun async(result: MethodChannel.Result, block: () -> Any?) {
        background.execute {
            val value = try {
                block()
            } catch (error: Exception) {
                Log.w(TAG, "TV işi başarısız", error)
                failure(error)
            }
            main.post { result.success(value) }
        }
    }

    private fun failure(error: Exception): Map<String, Any?> {
        val known = error as? TvInstallException
        return mapOf(
            "ok" to false,
            "error" to (known?.error ?: TvError.INSTALL_FAILED).name,
            "detail" to (known?.detail ?: error.message ?: error.javaClass.simpleName),
        )
    }

    private fun install(brand: TvBrand, host: String, name: String, passphrase: String?, force: Boolean, cancel: Cancel): Map<String, Any?> {
        val app = bundled()[brand] ?: throw TvInstallException(TvError.PACKAGE_MISSING, "assets/tv-app içinde ${brand.name} paketi yok")
        val bytes = activity.assets.open(app.asset).use { it.readBytes() }
        val server = LocalNetwork.privateAddresses().firstOrNull()?.let { "http://$it:8787" }
        val outcome: Map<String, Any?> = when (brand) {
            TvBrand.ANDROID -> {
                val installer = AndroidTvInstaller(host, File(activity.filesDir, "tvinstall/adbkey"))
                installer.onProgress = ::emit
                val done = installer.ensureInstalled(bytes, app.version, cancel, server, force)
                mapOf("ok" to true, "version" to done.version, "installed" to done.installed, "launched" to true)
            }
            TvBrand.LG -> installLg(host, passphrase, app, bytes, server, force, cancel)
            TvBrand.SAMSUNG -> throw TvInstallException(TvError.INSTALL_FAILED, "Samsung kurulumu bilgisayardan yapılır")
        }
        store.tv = mapOf(
            "brand" to brand.name.lowercase(), "host" to host, "name" to name,
            "version" to outcome["version"], "installedAt" to System.currentTimeMillis(),
        )
        return outcome
    }

    private fun installLg(host: String, passphrase: String?, app: BundledApp, bytes: ByteArray, server: String?, force: Boolean, cancel: Cancel): Map<String, Any?> {
        emit("connecting")
        if (!LocalNetwork.isPortOpen(host, LgInstaller.SSH_PORT, 3000)) throw TvInstallException(TvError.UNREACHABLE, "9922 kapalı")
        var key = store.lgKey(host)
        if (key == null || !passphrase.isNullOrBlank()) {
            if (passphrase.isNullOrBlank()) throw TvInstallException(TvError.WRONG_PASSPHRASE, "parola gerekli")
            emit("key")
            key = LgInstaller.fetchKey(host, passphrase, cancel)
        }
        JschShell(host, key, cancel).use { shell ->
            val installer = LgInstaller(shell, cancel)
            emit("checking")
            val current = try {
                installer.installedVersion()
            } catch (error: TvInstallException) {
                // Kayıtlı anahtar artık geçmiyorsa (geliştirici modu yeniden açılmış) unutulur; parola yeniden sorulur.
                if (error.error == TvError.KEY_REFUSED) store.setLgKey(host, null)
                throw error
            }
            store.setLgKey(host, key)
            val needs = force || current == null || Versions.isNewer(app.version, current)
            if (needs) installer.install(bytes, app.fileName, app.version, onProgress = ::emit)
            emit("launching")
            val launched = installer.launch(server)
            val hours = runCatching { installer.renewSession() }.getOrNull()
            return mapOf("ok" to true, "version" to (if (needs) app.version else current), "installed" to needs, "launched" to launched, "hoursLeft" to hours)
        }
    }

    private fun bundled(): Map<TvBrand, BundledApp> {
        val files = runCatching { activity.assets.list("tv-app")?.toList() }.getOrNull().orEmpty()
        val out = LinkedHashMap<TvBrand, BundledApp>()
        for (file in files) {
            val brand = when {
                file.endsWith(".ipk") -> TvBrand.LG
                file.endsWith(".apk") -> TvBrand.ANDROID
                file.endsWith(".wgt") -> TvBrand.SAMSUNG
                else -> null
            } ?: continue
            val version = Versions.ofBundledFile(file) ?: continue
            out[brand] = BundledApp("tv-app/$file", version)
        }
        return out
    }

    private fun brandOf(text: String?): TvBrand? = when (text?.lowercase()) {
        "lg" -> TvBrand.LG
        "samsung" -> TvBrand.SAMSUNG
        "android" -> TvBrand.ANDROID
        else -> null
    }

    companion object {
        private const val TAG = "GameTranslatorTv"

        /** MainActivity.configureFlutterEngine'den bir kez çağrılır. */
        fun attach(activity: Activity, messenger: BinaryMessenger) {
            val channel = TvInstallChannel(activity)
            MethodChannel(messenger, "gt/tv").setMethodCallHandler(channel::handle)
            EventChannel(messenger, "gt/tv/events").setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    channel.events = sink
                }

                override fun onCancel(arguments: Any?) {
                    channel.events = null
                }
            })
        }
    }
}
