// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile

import android.Manifest
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.Executors

/** Flutter arayüzü ile [Engine] arasındaki köprü: "gt/bridge" yöntem kanalı ve "gt/events" durum akışı. */
class MainActivity : FlutterActivity() {
    private val background = Executors.newCachedThreadPool()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "gt/bridge").setMethodCallHandler(::handle)
        // Telefondan TV uygulaması kurma sihirbazı (tvinstall/).
        com.gametranslator.gametranslator_mobile.tvinstall.TvInstallChannel.attach(this, messenger)
        EventChannel(messenger, "gt/events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                Engine.onChanged = { state -> events.success(state) }
                events.success(Engine.state())
            }

            override fun onCancel(arguments: Any?) {
                Engine.onChanged = null
            }
        })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleDebugIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDebugIntent(intent)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val store = Store(this)
        when (call.method) {
            "getState" -> result.success(Engine.state())
            "getSetup" -> result.success(setup(store))
            "getSettings" -> result.success(store.settings.toJson().toString())
            "setSettings" -> {
                val json = runCatching { JSONObject(call.arguments as String) }.getOrNull()
                    ?: return result.error("bad_settings", "Ayarlar okunamadı", null)
                store.settings = Settings.fromJson(json)
                Engine.applySettings(this)
                result.success(null)
            }
            "setAccountId" -> {
                val bytes = Store.decode(call.arguments as String)
                if (bytes == null || bytes.size != 8) return result.error("bad_account", "Hesap kimliği 8 bayt olmalı", null)
                store.accountId = bytes
                result.success(null)
            }
            "forgetAccount" -> {
                store.accountId = null
                store.console = null
                result.success(null)
            }
            "setIntroSeen" -> {
                store.introSeen = call.arguments as? Boolean ?: true
                result.success(null)
            }
            "forgetConsole" -> {
                store.console = null
                result.success(null)
            }
            "discover" -> {
                val extra = (call.argument<List<String>>("hosts") ?: emptyList())
                val timeout = call.argument<Int>("timeoutMs") ?: 3000
                background.execute {
                    val found = Engine.discover(extra, timeout)
                    runOnUiThread { result.success(found) }
                }
            }
            "register" -> {
                val host = call.argument<String>("host") ?: ""
                val pin = call.argument<Int>("pin") ?: -1
                if (host.isBlank() || pin < 0) return result.error("bad_arguments", "Adres ve kod gerekli", null)
                background.execute {
                    val outcome = Engine.register(this, host.trim(), pin)
                    runOnUiThread { result.success(outcome) }
                }
            }
            "start" -> {
                requestNotificationPermission()
                TranslatorService.start(this)
                result.success(null)
            }
            "stop" -> {
                TranslatorService.stop(this)
                result.success(null)
            }
            "snapshot" -> {
                val width = (call.arguments as? Int) ?: 960
                background.execute {
                    val jpeg = Engine.snapshot(width)
                    runOnUiThread { result.success(jpeg) }
                }
            }
            "testSubtitle" -> {
                background.execute { Engine.sendTestSubtitle() }
                result.success(null)
            }
            "logs" -> result.success(Engine.logLines())
            else -> result.notImplemented()
        }
    }

    private fun setup(store: Store): Map<String, Any?> {
        val console = store.console
        return mapOf(
            "hasAccount" to (store.accountId != null),
            "accountId" to store.accountId?.let { Store.encode(it) },
            "consoleHost" to console?.host,
            "consoleName" to console?.name,
            "introSeen" to store.introSeen,
            "version" to runCatching { packageManager.getPackageInfo(packageName, 0).versionName }.getOrNull(),
        )
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
    }

    /**
     * Yalnız hata ayıklama derlemesinde: adb ile eşleştirme aktarımı ve otomatik başlatma (uçtan uca testler için).
     * adb shell am start -n <paket>/.MainActivity --es gt_import '{"host":..,"name":..,"registKey":b64,"morning":b64,"accountId":b64}' --ez gt_start true
     */
    private fun handleDebugIntent(intent: Intent?) {
        if (intent == null || applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val store = Store(this)
        intent.getStringExtra("gt_import")?.let { text ->
            val json = runCatching { JSONObject(text) }.getOrNull() ?: return@let
            val key = Store.decode(json.optString("registKey"))
            val morning = Store.decode(json.optString("morning"))
            val account = Store.decode(json.optString("accountId"))
            if (key?.size == 16 && morning?.size == 16 && account?.size == 8) {
                store.accountId = account
                store.console = Console(json.optString("host"), json.optString("name", "PS5"), key, morning)
            }
        }
        if (intent.getBooleanExtra("gt_forget_console", false)) store.console = null
        intent.getStringExtra("gt_settings")?.let { text ->
            runCatching { JSONObject(text) }.getOrNull()?.let {
                store.settings = Settings.fromJson(it)
                Engine.applySettings(this)
            }
        }
        if (intent.getBooleanExtra("gt_start", false)) TranslatorService.start(this)
        if (intent.getBooleanExtra("gt_stop", false)) TranslatorService.stop(this)
        if (intent.getBooleanExtra("gt_test_subtitle", false)) background.execute { Engine.sendTestSubtitle() }
    }
}
