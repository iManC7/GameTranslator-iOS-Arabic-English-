// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile

import android.text.Html
import com.gametranslator.gametranslator_mobile.core.TextTranslator
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

/**
 * Google'ın anahtarsız çeviri ucu (Windows'taki GoogleGtxTranslator ile aynı). İnternet ister.
 * Bir uç yanıt vermezse ya da hız sınırına takılırsa sıradaki yedek uç denenir; hiçbiri çevirmezse null döner
 * (çağıran cihaz üstü çeviriye geçer, İngilizce metin çeviri gibi gösterilmez).
 */
class GoogleGtxTranslator(private val source: String, private val target: String) : TextTranslator {
    override fun translate(text: String): String? {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return ""
        val query = URLEncoder.encode(trimmed, "UTF-8")
        val endpoints = listOf(
            "https://translate.googleapis.com/translate_a/single?client=gtx&sl=$source&tl=$target&dt=t&q=$query",
            "https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl=$source&tl=$target&dt=t&q=$query",
            "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=$source&tl=$target&q=$query",
        )
        for (endpoint in endpoints) {
            val translated = fetch(endpoint)
            if (!translated.isNullOrBlank()) return translated
        }
        return null
    }

    private fun fetch(url: String): String? {
        val connection = URL(url).openConnection() as HttpURLConnection
        return try {
            // Üç uç sırayla denenebildiği için süreler kısa tutulur: altyazı ekrandan gitmeden yedeğe geçilsin.
            connection.connectTimeout = 2500
            connection.readTimeout = 3500
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36")
            if (connection.responseCode != 200) return null
            parse(connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() })
        } catch (error: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        /**
         * İki yanıt biçimi vardır: `[[["çeviri","kaynak",...],...],...]` (cümle parçaları birleştirilir) ve yedek uçtaki
         * `["çeviri"]`.
         */
        internal fun parse(json: String): String? {
            val root = JSONArray(json)
            val sentences = root.optJSONArray(0)
            val text = if (sentences != null) {
                val result = StringBuilder()
                for (i in 0 until sentences.length()) {
                    val part = sentences.optJSONArray(i)?.optString(0, "") ?: ""
                    if (part.isNotEmpty() && part != "null") result.append(part)
                }
                result.toString().trim()
            } else {
                (root.opt(0) as? String)?.trim() ?: ""
            }
            return if (text.isEmpty()) null else Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY).toString()
        }
    }
}

/** DeepL API (kullanıcının kendi anahtarıyla). ":fx" ile biten anahtar ücretsiz uca gider. */
class DeepLTranslator(private val key: String, private val source: String, private val target: String) : TextTranslator {
    override fun translate(text: String): String? {
        val host = if (key.trim().endsWith(":fx")) "api-free.deepl.com" else "api.deepl.com"
        val connection = URL("https://$host/v2/translate").openConnection() as HttpURLConnection
        return try {
            connection.connectTimeout = 4000
            connection.readTimeout = 6000
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.setRequestProperty("Authorization", "DeepL-Auth-Key ${key.trim()}")
            connection.setRequestProperty("Content-Type", "application/json")
            val body = JSONObject()
                .put("text", JSONArray().put(text))
                .put("source_lang", source.uppercase())
                .put("target_lang", target.uppercase())
            connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            if (connection.responseCode != 200) return null
            val json = JSONObject(connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() })
            json.optJSONArray("translations")?.optJSONObject(0)?.optString("text")?.takeIf { it.isNotBlank() }
        } catch (error: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }
}

/** Cihaz üstünde çeviri (ML Kit). İnternetsiz çalışır; dil modeli (~30 MB) ilk kullanımda bir kez iner. */
class MlKitTranslator(source: String, target: String) : TextTranslator {
    private val translator: Translator? = run {
        val from = TranslateLanguage.fromLanguageTag(source)
        val to = TranslateLanguage.fromLanguageTag(target)
        if (from == null || to == null) null
        else Translation.getClient(TranslatorOptions.Builder().setSourceLanguage(from).setTargetLanguage(to).build())
    }
    @Volatile private var modelReady = false

    /** Modeli indirir (gerekiyorsa). Bloklar; başarısızsa false. */
    fun prepare(timeoutSeconds: Long = 180): Boolean {
        val client = translator ?: return false
        if (modelReady) return true
        return try {
            Tasks.await(client.downloadModelIfNeeded(DownloadConditions.Builder().build()), timeoutSeconds, TimeUnit.SECONDS)
            modelReady = true
            true
        } catch (error: Exception) {
            false
        }
    }

    override fun translate(text: String): String? {
        val client = translator ?: return null
        if (!modelReady && !prepare()) return null
        return try {
            Tasks.await(client.translate(text), 8, TimeUnit.SECONDS)
        } catch (error: Exception) {
            null
        }
    }

    fun close() {
        translator?.close()
    }
}

/** Önce [primary]; başarısız olursa [fallback] (ör. internet koptuğunda cihaz üstü çeviri). */
class FallbackTranslator(private val primary: TextTranslator, private val fallback: TextTranslator) : TextTranslator {
    override fun translate(text: String): String? = primary.translate(text) ?: fallback.translate(text)
}
