// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile

import android.content.Context
import android.util.Base64
import com.gametranslator.gametranslator_mobile.core.Glossary
import com.gametranslator.gametranslator_mobile.core.SubtitleStyle
import org.json.JSONObject

/** PS5'e kaydedilmiş bu telefonun bağlantı bilgileri. */
class Console(val host: String, val name: String, val registKey: ByteArray, val morning: ByteArray) {
    /** Uyandırma için kayıt anahtarının onaltılık değeri (anahtar ASCII onaltılık, sıfırla doldurulmuş). */
    val wakeCredential: Long?
        get() {
            val end = registKey.indexOf(0).let { if (it < 0) registKey.size else it }
            val text = String(registKey, 0, end, Charsets.US_ASCII)
            return try { java.lang.Long.parseUnsignedLong(text, 16) } catch (error: NumberFormatException) { null }
        }
}

/** Altyazının oyunda arandığı bölge, ekrana oranla (0–1). */
data class Region(val top: Double = 0.62, val bottom: Double = 0.97, val left: Double = 0.14, val right: Double = 0.86)

data class Settings(
    val region: Region = Region(),
    val sourceLanguage: String = "en",
    val targetLanguage: String = "tr",
    /** google (çevrimiçi, anahtarsız), mlkit (cihaz üstünde), deepl (kendi anahtarınla) */
    val engine: String = "google",
    val deepLKey: String = "",
    val style: SubtitleStyle = SubtitleStyle(),
    /** PS5 dinlenme modundaysa uyandır. */
    val autoWake: Boolean = true,
    /** Terim sözlüğü, bilgisayardaki sözlük dosyalarıyla aynı JSON biçiminde; boşsa sözlük yok. */
    val glossary: String = "",
    /** Oyun paketleri (İngilizce→Türkçe): paketteki satır motora gitmeden paketin Türkçesiyle gösterilir. */
    val packsEnabled: Boolean = true,
) {
    /** Sözlük metni çözülmüş hâliyle; boş ya da bozuksa boş sözlük. */
    fun parsedGlossary(): Glossary {
        if (glossary.isBlank()) return Glossary.EMPTY
        val root = try { JSONObject(glossary) } catch (error: org.json.JSONException) { return Glossary.EMPTY }
        val terms = LinkedHashMap<String, String>()
        root.optJSONObject("terms")?.let { map -> for (key in map.keys()) (map.opt(key) as? String)?.let { terms[key] = it } }
        val keep = ArrayList<String>()
        root.optJSONArray("keep")?.let { list -> for (i in 0 until list.length()) (list.opt(i) as? String)?.let { keep.add(it) } }
        return Glossary.of(terms, keep)
    }

    fun toJson(): JSONObject = JSONObject()
        .put("region", JSONObject().put("top", region.top).put("bottom", region.bottom).put("left", region.left).put("right", region.right))
        .put("sourceLanguage", sourceLanguage)
        .put("targetLanguage", targetLanguage)
        .put("engine", engine)
        .put("deepLKey", deepLKey)
        .put("autoWake", autoWake)
        .put("glossary", glossary)
        .put("packsEnabled", packsEnabled)
        .put("style", JSONObject()
            .put("fontSize", style.fontSize).put("bottomPercent", style.bottomPercent).put("placement", style.placement)
            .put("background", style.background).put("bold", style.bold).put("textColor", style.textColor)
            .put("displayMode", style.displayMode).put("stackPrevious", style.stackPrevious))

    companion object {
        /** Eksik alanlar varsayılanla dolar. */
        fun fromJson(json: JSONObject?): Settings {
            val defaults = Settings()
            if (json == null) return defaults
            val r = json.optJSONObject("region")
            val s = json.optJSONObject("style")
            val d = defaults.style
            val top = (r?.optDouble("top", defaults.region.top) ?: defaults.region.top).coerceIn(0.0, 0.95)
            val left = (r?.optDouble("left", defaults.region.left) ?: defaults.region.left).coerceIn(0.0, 0.95)
            return Settings(
                region = Region(
                    top = top,
                    bottom = (r?.optDouble("bottom", defaults.region.bottom) ?: defaults.region.bottom).coerceIn(top + 0.05, 1.0),
                    left = left,
                    right = (r?.optDouble("right", defaults.region.right) ?: defaults.region.right).coerceIn(left + 0.05, 1.0)),
                sourceLanguage = json.optString("sourceLanguage", defaults.sourceLanguage),
                targetLanguage = json.optString("targetLanguage", defaults.targetLanguage),
                engine = json.optString("engine", defaults.engine),
                deepLKey = json.optString("deepLKey", ""),
                autoWake = json.optBoolean("autoWake", true),
                glossary = json.optString("glossary", ""),
                packsEnabled = json.optBoolean("packsEnabled", true),
                style = SubtitleStyle(
                    fontSize = s?.optInt("fontSize", d.fontSize) ?: d.fontSize,
                    bottomPercent = s?.optInt("bottomPercent", d.bottomPercent) ?: d.bottomPercent,
                    placement = s?.optString("placement", d.placement) ?: d.placement,
                    background = s?.optInt("background", d.background) ?: d.background,
                    bold = s?.optBoolean("bold", d.bold) ?: d.bold,
                    textColor = s?.optString("textColor", d.textColor) ?: d.textColor,
                    displayMode = s?.optString("displayMode", d.displayMode) ?: d.displayMode,
                    stackPrevious = s?.optBoolean("stackPrevious", d.stackPrevious) ?: d.stackPrevious))
        }
    }
}

/** Uygulamaya özel depoda (başka uygulamalar okuyamaz) tutulan kayıtlar. */
class Store(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("gametranslator", Context.MODE_PRIVATE)

    var accountId: ByteArray?
        get() = prefs.getString("accountId", null)?.let { decode(it) }?.takeIf { it.size == 8 }
        set(value) = prefs.edit().apply { if (value == null) remove("accountId") else putString("accountId", encode(value)) }.apply()

    var console: Console?
        get() {
            val json = prefs.getString("console", null)?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return null
            val key = decode(json.optString("registKey")) ?: return null
            val morning = decode(json.optString("morning")) ?: return null
            if (key.size != 16 || morning.size != 16 || json.optString("host").isEmpty()) return null
            return Console(json.optString("host"), json.optString("name", "PS5"), key, morning)
        }
        set(value) = prefs.edit().apply {
            if (value == null) remove("console")
            else putString("console", JSONObject().put("host", value.host).put("name", value.name)
                .put("registKey", encode(value.registKey)).put("morning", encode(value.morning)).toString())
        }.apply()

    /** Tanıtım ekranları bir kez gösterildi mi? */
    var introSeen: Boolean
        get() = prefs.getBoolean("introSeen", false)
        set(value) = prefs.edit().putBoolean("introSeen", value).apply()

    var settings: Settings
        get() = Settings.fromJson(prefs.getString("settings", null)?.let { runCatching { JSONObject(it) }.getOrNull() })
        set(value) = prefs.edit().putString("settings", value.toJson().toString()).apply()

    companion object {
        fun encode(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)
        fun decode(text: String): ByteArray? = try { Base64.decode(text, Base64.DEFAULT) } catch (error: IllegalArgumentException) { null }
    }
}
