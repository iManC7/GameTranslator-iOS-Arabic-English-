// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile

import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.gametranslator.gametranslator_mobile.core.GamePackLibrary
import com.gametranslator.gametranslator_mobile.core.Glossary
import com.gametranslator.gametranslator_mobile.core.GlossaryTranslator
import com.gametranslator.gametranslator_mobile.core.HttpPackServer
import com.gametranslator.gametranslator_mobile.core.PackStore
import com.gametranslator.gametranslator_mobile.core.PackTranslation
import com.gametranslator.gametranslator_mobile.core.PrefixTranslator
import com.gametranslator.gametranslator_mobile.core.ReadScheduler
import com.gametranslator.gametranslator_mobile.core.SubtitlePipeline
import com.gametranslator.gametranslator_mobile.core.SubtitleServer
import com.gametranslator.gametranslator_mobile.core.SubtitleSink
import com.gametranslator.gametranslator_mobile.core.TextBox
import com.gametranslator.gametranslator_mobile.core.TextTranslator
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Uygulamanın çekirdeği: PS5 Remote Play oturumunu açar, gelen karelerde altyazı bölgesini okur, çevirir ve
 * TV'deki uygulamaya (ve telefondaki ekrana) gönderir. Bilgisayardaki AppController + StreamSession'ın karşılığı.
 * Tek örnek: arka plan servisi başlatır/durdurur, Flutter arayüzü durumunu izler.
 */
object Engine : Native.SessionListener {
    private const val TAG = "GameTranslator"
    /** Yazı tanıma için saniyede en çok bu kadar kare çözülüp verilir. */
    private const val MAX_FPS = 5
    private const val LOG_LINES = 300

    /** idle, starting, waking, connecting, streaming, reconnecting, stopping, failed */
    @Volatile var phase = "idle"; private set
    @Volatile var message = ""; private set
    @Volatile var running = false; private set
    @Volatile var lastSource = ""; private set
    @Volatile var lastTranslation = ""; private set
    @Volatile var lastRead = ""; private set
    @Volatile var frameCount = 0L; private set
    @Volatile var frameWidth = 0; private set
    @Volatile var frameHeight = 0; private set
    @Volatile var translatedCount = 0; private set
    /** Paketten gösterilen satır sayısı ve son satırın geldiği paketin (oynanan oyunun) adı. */
    @Volatile var packHits = 0; private set
    @Volatile var packGame = ""; private set

    val server = SubtitleServer()

    /** Durum değişince ana iş parçacığında çağrılır. */
    @Volatile var onChanged: ((Map<String, Any?>) -> Unit)? = null

    private val main = Handler(Looper.getMainLooper())
    private val control: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r -> Thread(r, "gt-control") }
    private val reader = Executors.newSingleThreadExecutor { r -> Thread(r, "gt-reader") }
    private val translating = Executors.newSingleThreadExecutor { r -> Thread(r, "gt-translate") }

    private val logs = ArrayDeque<String>()
    private val notifyPending = AtomicBoolean(false)

    private var appContext: Context? = null
    private var store: Store? = null
    @Volatile private var settings = Settings()
    private var session = 0L
    private var retry: ScheduledFuture<*>? = null
    /** Durdurma istendi ama denetim iş parçacığı henüz işlemedi (uyandırma beklemesini keser). */
    @Volatile private var stopRequested = false

    private val frameLock = Any()
    private var frame: Bitmap? = null
    private val reading = AtomicBoolean(false)
    private val scheduler = ReadScheduler()
    private var recognizer: TextRecognizer? = null
    @Volatile private var pipeline: SubtitlePipeline? = null
    private var mlKit: MlKitTranslator? = null
    private var lastLines: List<String> = emptyList()
    private var lastBox: TextBox? = null

    init {
        server.onClientsChanged = { notifyChanged() }
    }

    // --- Durum ---

    fun state(): Map<String, Any?> = mapOf(
        "phase" to phase,
        "message" to message,
        "running" to running,
        "tvClients" to server.connectedClients,
        "serverPort" to server.boundPort,
        "localAddress" to localAddress(),
        "lastSource" to lastSource,
        "lastTranslation" to lastTranslation,
        "lastRead" to lastRead,
        "frames" to frameCount,
        "frameWidth" to frameWidth,
        "frameHeight" to frameHeight,
        "translated" to translatedCount,
        "packHits" to packHits,
        "packGame" to packGame,
        "nativeAvailable" to Native.available,
    )

    fun logLines(): List<String> = synchronized(logs) { logs.toList() }

    private fun log(level: Int, text: String) {
        val line = "${if (level == 0) "E" else if (level == 1) "W" else "I"} $text"
        when (level) {
            0 -> Log.e(TAG, text)
            1 -> Log.w(TAG, text)
            else -> Log.i(TAG, text)
        }
        synchronized(logs) {
            logs.addLast(line)
            while (logs.size > LOG_LINES) logs.removeFirst()
        }
    }

    private fun setPhase(value: String, text: String = "") {
        phase = value
        message = text
        log(if (value == "failed") 0 else 2, "durum: $value $text".trim())
        notifyChanged()
    }

    /** Arayüze en çok ~10 Hz bildirim: kare sayacı her karede değişir. */
    private fun notifyChanged() {
        if (!notifyPending.compareAndSet(false, true)) return
        main.postDelayed({
            notifyPending.set(false)
            onChanged?.invoke(state())
        }, 100)
    }

    /**
     * Denetim iş parçacığında çalıştırır. Yürütücü yakalanmayan hatayı sessizce yutar; hata günlüğe ve arayüze
     * yazılmazsa uygulama "başlatılıyor"da takılı kalmış görünür.
     */
    private fun onControl(block: () -> Unit) {
        control.execute {
            try {
                block()
            } catch (error: Throwable) {
                Log.e(TAG, "denetim hatası", error)
                running = false
                setPhase("failed", "Beklenmeyen hata: ${error.javaClass.simpleName}: ${error.message}")
            }
        }
    }

    // --- Başlat / durdur ---

    fun start(context: Context) {
        val app = context.applicationContext
        onControl {
            if (running) return@onControl
            stopRequested = false
            appContext = app
            val s = Store(app)
            store = s
            settings = s.settings
            if (!Native.available) return@onControl setPhase("failed", "Yerel kütüphane yüklenemedi")
            if (s.accountId == null || s.console == null) return@onControl setPhase("failed", "Önce PSN girişi ve PS5 eşleştirmesi gerekli")
            running = true
            frameCount = 0
            translatedCount = 0
            packHits = 0
            packGame = ""
            setPhase("starting")
            refreshPacks(app)
            // TV uygulaması kurulamayan cihazlar için: tarayıcıda http://telefon:8787/obs
            if (server.overlayPage == null) server.overlayPage = runCatching { app.assets.open("obs-overlay.html").use { it.readBytes() } }.getOrNull()
            val port = server.start()
            log(2, "altyazı sunucusu: ${localAddress() ?: "?"}:$port")
            server.sendStyle(settings.style)
            buildPipeline()
            connect()
        }
    }

    fun stop() {
        stopRequested = true
        // Oturumun kapanması birkaç saniye sürer (iş parçacıkları beklenir); arayüz bu sırada "durduruluyor" gösterir.
        if (running || session != 0L) setPhase("stopping")
        onControl {
            if (!running && session == 0L) return@onControl setPhase("idle")
            running = false
            retry?.cancel(false)
            retry = null
            closeSession()
            pipeline?.reset()
            pipeline = null
            server.clear()
            server.stop()
            mlKit?.close()
            mlKit = null
            synchronized(frameLock) { frame = null }
            setPhase("idle")
        }
    }

    /** Ayarlar değişti: görünüm hemen TV'ye gider; dil ya da çeviri motoru değiştiyse hat yeniden kurulur. */
    fun applySettings(context: Context) {
        val app = context.applicationContext
        onControl {
            val before = settings
            val now = Store(app).settings
            settings = now
            if (!running) return@onControl
            if (now.style != before.style) server.sendStyle(now.style)
            if (now.engine != before.engine || now.deepLKey != before.deepLKey || now.sourceLanguage != before.sourceLanguage
                || now.targetLanguage != before.targetLanguage || now.glossary != before.glossary
                || now.packsEnabled != before.packsEnabled) buildPipeline()
            if (now.region != before.region) {
                scheduler.reset()
                pipeline?.reset()
            }
        }
    }

    private fun buildPipeline() {
        pipeline?.reset()
        val s = settings
        mlKit?.close()
        val local = MlKitTranslator(s.sourceLanguage, s.targetLanguage)
        mlKit = local
        // Cihaz üstü model arka planda hazırlanır: internet koptuğunda yedek olur.
        translating.execute { if (local.prepare()) log(2, "cihaz üstü çeviri modeli hazır") else log(1, "cihaz üstü çeviri modeli indirilemedi") }
        val online: TextTranslator? = when (s.engine) {
            "deepl" -> if (s.deepLKey.isNotBlank()) FallbackTranslator(DeepLTranslator(s.deepLKey, s.sourceLanguage, s.targetLanguage),
                GoogleGtxTranslator(s.sourceLanguage, s.targetLanguage)) else GoogleGtxTranslator(s.sourceLanguage, s.targetLanguage)
            "mlkit" -> null
            else -> GoogleGtxTranslator(s.sourceLanguage, s.targetLanguage)
        }
        val engine = if (online == null) local else FallbackTranslator(online, local)
        // Sözlüğün ek kuralları Türkçeye göredir; bilgisayarda da yalnız İngilizce→Türkçe için çalışır.
        val glossary = if (s.sourceLanguage == "en" && s.targetLanguage == "tr") s.parsedGlossary() else Glossary.EMPTY
        if (!glossary.isEmpty) log(2, "terim sözlüğü: ${glossary.count} terim")
        val withGlossary: TextTranslator = if (glossary.isEmpty) engine else GlossaryTranslator(glossary, engine)
        // Baştaki konuşmacı işareti ("- ", ">>") motorlara gönderilmez; hangi motor çevirirse çevirsin korunur.
        val translator: TextTranslator = PrefixTranslator(withGlossary)
        val built = SubtitlePipeline(translator, object : SubtitleSink {
            override fun show(text: String, durationMs: Int, box: TextBox?, replaces: Boolean) = server.sendSubtitle(text, durationMs, box, replaces)
            override fun clear() = server.clear()
        }, translating)
        built.onPair = { source, translation ->
            lastSource = source
            lastTranslation = translation
            translatedCount++
            log(2, "çeviri: \"${source.replace('\n', ' ')}\" → \"$translation\"")
            notifyChanged()
        }
        built.onTranslateFailed = { source -> log(1, "çevrilemedi: \"${source.replace('\n', ' ')}\"") }
        // Oyun paketi: satır paketteyse motora gidilmez. Bulanık arama yalnız son tam eşleşmenin paketinde (oynanan oyun).
        val app = appContext
        if (app != null && s.packsEnabled && PackTranslation.applies(s.sourceLanguage, s.targetLanguage)) {
            val library = packLibrary(app)
            // Paketler çeviri iş parçacığında ilk istekten önce açılır (birkaç saniye; arayüz ve okuma beklemez).
            translating.execute {
                val started = SystemClock.elapsedRealtime()
                try {
                    val infos = library.infos
                    log(2, "oyun paketleri: ${infos.size} paket, ${infos.sumOf { it.entries }} satır (${SystemClock.elapsedRealtime() - started} ms)")
                } catch (error: Throwable) {
                    // Bellek yetmezse paketsiz sürer; çeviri motoru çalışmaya devam eder.
                    log(0, "oyun paketleri açılamadı: ${error.javaClass.simpleName}")
                }
            }
            built.packLookup = { text -> PackTranslation.match(library, text) }
            built.onPackHit = { source, match ->
                packHits++
                packGame = library.scopeTitle ?: match.packId ?: ""
                log(2, "paket (${match.packId}): \"${source.replace('\n', ' ')}\"")
            }
        }
        built.onReadText = { text -> if (text != lastRead) { lastRead = text; notifyChanged() } }
        scheduler.reset()
        if (recognizer == null) recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        pipeline = built
    }

    // --- Oyun paketleri ---

    private val packLock = Any()
    private var packs: GamePackLibrary? = null
    private var packStore: PackStore? = null
    private val packRefreshing = AtomicBoolean(false)

    /** Uygulamayla gelen (assets/packs) ve sunucudan inen paketler; ilk aramada açılır, uygulama boyunca bellekte kalır. */
    private fun packLibrary(app: Context): GamePackLibrary = synchronized(packLock) {
        packs ?: GamePackLibrary({
            (app.assets.list("packs") ?: emptyArray()).map { name -> name to { app.assets.open("packs/$name").use { it.readBytes() } } }
        }, store(app).folder).also { packs = it }
    }

    private fun store(app: Context): PackStore = synchronized(packLock) {
        // Uygulamadaki paketlerin .gz özetleri derlemede yazılır (build.gradle.kts: copyGamePacks); AGP varlıkları açtığı
        // için telefonda dosyadan hesaplanamaz.
        packStore ?: PackStore(File(app.filesDir, "packs-remote"), HttpPackServer(PackStore.DEFAULT_URL), bundledHashes = {
            app.assets.open("packs-sha256.txt").bufferedReader().use { reader ->
                reader.readLines().mapNotNull { it.substringBefore(' ').trim().lowercase().takeIf { hash -> hash.length == 64 } }.toSet()
            }
        }).also { packStore = it }
    }

    /**
     * Haftada bir sunucudaki yeni ve güncellenen paketleri indirir (SHA-256 doğrulanır; uygulamada olanlar inmez).
     * Arka planda; değişiklik olduysa ve paketler açıksa yeniden yüklenir.
     */
    private fun refreshPacks(app: Context) {
        if (!settings.packsEnabled || !packRefreshing.compareAndSet(false, true)) return
        Thread({
            try {
                val result = store(app).refresh()
                if (!result.skipped) log(2, "paket sunucusu: ${result.downloaded.size} indirildi, ${result.removed.size} kaldırıldı")
                if (result.downloaded.isNotEmpty() || result.removed.isNotEmpty()) {
                    val library = synchronized(packLock) { packs }
                    if (library != null) translating.execute { runCatching { library.reload() } }
                }
            } catch (error: Throwable) {
                log(1, "paket sunucusuna ulaşılamadı: ${error.javaClass.simpleName}")
            } finally {
                packRefreshing.set(false)
            }
        }, "gt-packs").start()
    }

    // --- PS5 oturumu ---

    /** [relocated]: adres bu denemede zaten yenilendi; ağ ikinci kez taranmaz. */
    private fun connect(relocated: Boolean = false) {
        if (!running) return
        val s = store ?: return
        val console = s.console ?: return setPhase("failed", "PS5 eşleştirmesi yok")
        val account = s.accountId ?: return setPhase("failed", "PSN hesabı yok")
        setPhase("connecting", console.host)

        // PS5 açık mı? Kapalıysa (dinlenme modu) ayara göre uyandırılır.
        when (probe(console.host)) {
            true -> {}
            false -> {
                val credential = console.wakeCredential
                if (!settings.autoWake || credential == null) {
                    setPhase("failed", "PS5 dinlenme modunda")
                    return scheduleRetry(10)
                }
                setPhase("waking", console.host)
                Native.wake(console.host, credential)
                val deadline = SystemClock.elapsedRealtime() + 60000
                var awake = false
                while (!stopRequested && !awake && SystemClock.elapsedRealtime() < deadline) awake = probe(console.host) == true
                if (stopRequested) return
                if (!awake) {
                    setPhase("failed", "PS5 uyanmadı")
                    return scheduleRetry(10)
                }
                setPhase("connecting", console.host)
            }
            null -> {
                // Modem PS5'e yeni adres vermiş olabilir: ağ taranır, aynı adlı konsol bulunursa kayıt güncellenir.
                val moved = if (relocated) null else relocate(console)
                if (stopRequested) return
                if (moved != null) {
                    log(2, "PS5 yeni adreste bulundu: ${console.host} → $moved")
                    s.console = Console(moved, console.name, console.registKey, console.morning)
                    return connect(relocated = true)
                }
                setPhase("failed", "PS5 ağda bulunamadı (${console.host})")
                return scheduleRetry(5)
            }
        }

        log(2, "PS5 oturumu: ${console.name} ${console.host}")
        session = Native.sessionStart(console.host, console.registKey, console.morning, account, MAX_FPS, this)
        if (session == 0L) {
            setPhase("failed", "Oturum başlatılamadı")
            scheduleRetry(5)
        }
    }

    /**
     * Kayıtlı adres yanıt vermiyorsa konsolu ağda arar. Aynı adlı tek konsol varsa adresini döner; yoksa ya da
     * birden çok aday varsa null (başka bir PS5'in adresi kayda yazılmasın).
     */
    private fun relocate(console: Console): String? {
        val sameName = discover(emptyList(), 2500).filter { it["host"] != console.host && it["name"] == console.name }
        return sameName.singleOrNull()?.get("host") as? String
    }

    /** true: açık, false: dinlenme modunda, null: yanıt yok. */
    private fun probe(host: String): Boolean? {
        var result: Boolean? = null
        Native.discover(arrayOf(host), 1500, object : Native.ConsoleCallback {
            override fun onConsole(host: String, name: ByteArray, awake: Boolean) {
                if (result != true) result = awake
            }
        })
        return result
    }

    private fun closeSession() {
        val handle = session
        session = 0
        if (handle != 0L) Native.sessionStop(handle)
    }

    private fun scheduleRetry(seconds: Long) {
        if (!running) return
        retry?.cancel(false)
        retry = control.schedule({ if (running && session == 0L) connect() }, seconds, TimeUnit.SECONDS)
    }

    // Native.SessionListener: libchiaki'nin iş parçacıklarından çağrılır.

    override fun onLog(level: Int, message: String?) {
        // Bilgi satırları (her 5 sn'de kalp atışı, paket dökümleri) günlüğü doldurur; hata ve uyarılar tutulur.
        if (message != null && (level < 2 || message.startsWith("Session") || message.startsWith("Starting") || message.startsWith("Switched")))
            log(level, "chiaki: $message")
    }

    override fun onEvent(event: Int, quitReason: Int, reasonText: String?) {
        when (event) {
            Native.EVENT_CONNECTED -> setPhase("streaming")
            Native.EVENT_LOGIN_PIN -> onControl {
                closeSession()
                running = false
                setPhase("failed", "PS5 kullanıcısının giriş şifresi var; şifresiz bir kullanıcı kullanın")
            }
            Native.EVENT_QUIT -> onControl {
                // Oturum kendi iş parçacığından kapatılamaz; denetim iş parçacığında bırakılır.
                closeSession()
                if (!running) return@onControl
                when (quitReason) {
                    Native.QUIT_STOPPED -> {}
                    Native.QUIT_IN_USE -> {
                        setPhase("failed", "Remote Play başka bir cihazda kullanılıyor")
                        scheduleRetry(10)
                    }
                    Native.QUIT_REFUSED -> {
                        running = false
                        setPhase("failed", "PS5 bağlantıyı reddetti; yeniden eşleştirin")
                    }
                    else -> {
                        setPhase("reconnecting", reasonText ?: "bağlantı koptu")
                        scheduleRetry(3)
                    }
                }
            }
        }
    }

    override fun onFrame(buffer: ByteBuffer, width: Int, height: Int, stride: Int) {
        if (stride != width * 4) return
        synchronized(frameLock) {
            var target = frame
            if (target == null || target.width != width || target.height != height) {
                target = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                frame = target
                frameWidth = width
                frameHeight = height
            }
            buffer.rewind()
            target.copyPixelsFromBuffer(buffer)
        }
        frameCount++
        if (frameCount % MAX_FPS == 1L) notifyChanged()
        // Önceki kare hâlâ okunuyorsa bu kare atlanır; okuma kareleri biriktirmez.
        if (pipeline == null || !reading.compareAndSet(false, true)) return
        reader.execute { readFrame() }
    }

    // --- Yazı okuma ---

    private fun readFrame() {
        val current = pipeline
        val engine = recognizer
        val region = settings.region
        var crop: Bitmap? = null
        var cropX = 0
        var cropY = 0
        var fullWidth = 0
        var fullHeight = 0
        synchronized(frameLock) {
            val source = frame
            if (source != null) {
                fullWidth = source.width
                fullHeight = source.height
                cropX = (region.left * fullWidth).toInt().coerceIn(0, fullWidth - 2)
                cropY = (region.top * fullHeight).toInt().coerceIn(0, fullHeight - 2)
                val w = ((region.right - region.left) * fullWidth).toInt().coerceIn(1, fullWidth - cropX)
                val h = ((region.bottom - region.top) * fullHeight).toInt().coerceIn(1, fullHeight - cropY)
                crop = Bitmap.createBitmap(source, cropX, cropY, w, h)
            }
        }
        val image = crop
        if (current == null || engine == null || image == null) {
            reading.set(false)
            return
        }
        if (scheduler.canReuse(signature(image))) {
            current.onRead(lastLines, lastBox)
            reading.set(false)
            return
        }
        engine.process(InputImage.fromBitmap(image, 0)).addOnCompleteListener(reader) { task ->
            try {
                if (task.isSuccessful) {
                    val (lines, box) = rows(task.result, cropX, cropY, fullWidth, fullHeight)
                    lastLines = lines
                    lastBox = box
                    current.onRead(lines, box)
                } else {
                    log(1, "yazı tanıma başarısız: ${task.exception?.message}")
                }
            } finally {
                reading.set(false)
            }
        }
    }

    /** Bölgenin küçültülmüş parlaklık özeti; iki karenin aynı olup olmadığını anlamak için. */
    private fun signature(image: Bitmap): ByteArray {
        val small = Bitmap.createScaledBitmap(image, 32, 8, true)
        val pixels = IntArray(32 * 8)
        small.getPixels(pixels, 0, 32, 0, 0, 32, 8)
        if (small !== image) small.recycle()
        return ByteArray(pixels.size) { i ->
            val p = pixels[i]
            ((((p shr 16) and 0xFF) * 3 + ((p shr 8) and 0xFF) * 6 + (p and 0xFF)) / 10).toByte()
        }
    }

    /** Tanınan satırları yukarıdan aşağı sıralar, aynı hizadakileri birleştirir; yazının tüm ekrandaki yerini verir. */
    internal fun rows(result: Text, cropX: Int, cropY: Int, fullWidth: Int, fullHeight: Int): Pair<List<String>, TextBox?> {
        data class Piece(val text: String, val left: Int, val top: Int, val right: Int, val bottom: Int)
        val pieces = result.textBlocks.flatMap { it.lines }.mapNotNull { line ->
            val b = line.boundingBox ?: return@mapNotNull null
            if (line.text.isBlank()) null else Piece(line.text.trim(), b.left, b.top, b.right, b.bottom)
        }.sortedBy { it.top }
        if (pieces.isEmpty()) return Pair(emptyList(), null)

        val grouped = mutableListOf<MutableList<Piece>>()
        for (piece in pieces) {
            val row = grouped.lastOrNull()
            val reference = row?.first()
            // Dikey ortaları yarım satır yüksekliğinden yakınsa aynı satırdır.
            if (reference != null && abs((piece.top + piece.bottom) / 2 - (reference.top + reference.bottom) / 2) <
                max(reference.bottom - reference.top, piece.bottom - piece.top) / 2) row.add(piece)
            else grouped.add(mutableListOf(piece))
        }
        val lines = grouped.map { row -> row.sortedBy { it.left }.joinToString(" ") { it.text } }
        var left = Int.MAX_VALUE
        var top = Int.MAX_VALUE
        var right = 0
        var bottom = 0
        for (p in pieces) {
            left = min(left, p.left); top = min(top, p.top); right = max(right, p.right); bottom = max(bottom, p.bottom)
        }
        val box = TextBox(
            (cropX + left).toDouble() / fullWidth, (cropY + top).toDouble() / fullHeight,
            (cropX + right).toDouble() / fullWidth, (cropY + bottom).toDouble() / fullHeight)
        return Pair(lines, box)
    }

    // --- Arayüz için yardımcılar ---

    /** Son karenin JPEG görüntüsü (bölge ayarı ve önizleme için); kare yoksa null. */
    fun snapshot(maxWidth: Int): ByteArray? {
        val copy = synchronized(frameLock) {
            val source = frame ?: return null
            val width = min(maxWidth, source.width)
            Bitmap.createScaledBitmap(source, width, source.height * width / source.width, true)
        }
        val out = ByteArrayOutputStream()
        copy.compress(Bitmap.CompressFormat.JPEG, 80, out)
        return out.toByteArray()
    }

    fun sendTestSubtitle() {
        if (server.boundPort == 0) server.start()
        server.sendStyle(settings.style)
        val r = settings.region
        server.sendSubtitle("Bu bir deneme altyazısıdır. Oyunun üstünde görüyor musunuz?", 8000, TextBox(0.3, r.bottom - 0.1, 0.7, r.bottom - 0.03))
    }

    /** Telefonun yerel ağdaki IPv4 adresi (Wi-Fi öncelikli). */
    fun localAddress(): String? {
        var fallback: String? = null
        try {
            for (network in NetworkInterface.getNetworkInterfaces()) {
                if (!network.isUp || network.isLoopback) continue
                for (address in network.inetAddresses) {
                    if (address !is Inet4Address || address.isLoopbackAddress) continue
                    if (network.name.startsWith("wlan")) return address.hostAddress
                    if (fallback == null) fallback = address.hostAddress
                }
            }
        } catch (error: Exception) {
        }
        return fallback
    }

    /** Aramada sorulacak adresler: yayın adresleri ve /24 ağlardaki tüm adresler (bazı ağlar yayını geçirmez). */
    private fun discoveryTargets(extra: List<String>): Array<String> {
        val targets = linkedSetOf("255.255.255.255")
        targets.addAll(extra.filter { it.isNotBlank() })
        try {
            for (network in NetworkInterface.getNetworkInterfaces()) {
                if (!network.isUp || network.isLoopback) continue
                for (address in network.interfaceAddresses) {
                    val ip = address.address as? Inet4Address ?: continue
                    address.broadcast?.hostAddress?.let { targets.add(it) }
                    if (address.networkPrefixLength >= 24) {
                        val b = ip.address
                        val prefix = "${b[0].toInt() and 0xFF}.${b[1].toInt() and 0xFF}.${b[2].toInt() and 0xFF}."
                        for (i in 1..254) targets.add(prefix + i)
                    }
                }
            }
        } catch (error: Exception) {
        }
        return targets.toTypedArray()
    }

    /** Ağdaki PS5'leri arar (bloklar). [extra]: elle girilen adresler. */
    fun discover(extra: List<String>, timeoutMs: Int): List<Map<String, Any?>> {
        if (!Native.available) return emptyList()
        val found = LinkedHashMap<String, Map<String, Any?>>()
        Native.discover(discoveryTargets(extra), timeoutMs, object : Native.ConsoleCallback {
            override fun onConsole(host: String, name: ByteArray, awake: Boolean) {
                synchronized(found) { found[host] = mapOf("host" to host, "name" to String(name, Charsets.UTF_8), "awake" to awake) }
            }
        })
        return synchronized(found) { found.values.toList() }
    }

    /** PS5'in "Cihaz Eşleştir" koduyla kayıt (bloklar, en çok ~30 sn). Başarılıysa kaydı saklar. */
    fun register(context: Context, host: String, pin: Int): Map<String, Any?> {
        val s = Store(context.applicationContext)
        val account = s.accountId ?: return mapOf("ok" to false, "detail" to "Önce PSN girişi gerekli")
        if (!Native.available) return mapOf("ok" to false, "detail" to "Yerel kütüphane yüklenemedi")
        val out = ByteArray(Native.REGISTERED_SIZE)
        val reason = IntArray(1)
        val errors = mutableListOf<String>()
        log(2, "PS5 kaydı başlıyor: $host")
        val result = Native.register(host, account, pin, out, reason, object : Native.LogCallback {
            override fun onLog(level: Int, message: String?) {
                if (message == null) return
                log(level, "chiaki: $message")
                if (level == 0) synchronized(errors) { errors.add(message) }
            }
        })
        if (result != 0) {
            val code = reason[0]
            val detail = when {
                code == 0x80108b02.toInt() -> "PS5 bu PSN hesabını tanımadı. PS5'te oturum açık olan kullanıcıyla aynı hesapla giriş yapın."
                code == 0x80108b09.toInt() || code == 0x80108b12.toInt() -> "Kod yanlış ya da süresi dolmuş. PS5'te Cihaz Eşleştir'i yeniden açıp yeni kodu girin."
                result == 2 -> "İptal edildi"
                // PS5 "Cihaz Eşleştir" ekranında değilken kayıt aramasını reddeder ya da hiç yanıtlamaz.
                synchronized(errors) { errors.any { it.contains("search", ignoreCase = true) } } ->
                    "PS5 eşleştirmeye hazır değil. PS5'te Ayarlar › Sistem › Uzaktan Oynatma › Cihaz Eşleştir ekranını açık tutup yeniden deneyin."
                else -> synchronized(errors) { errors.firstOrNull() } ?: "PS5 yanıt vermedi. Konsolun açık ve Cihaz Eşleştir ekranında olduğunu kontrol edin."
            }
            log(0, "PS5 kaydı başarısız: $detail")
            return mapOf("ok" to false, "reason" to code, "detail" to detail)
        }
        val nameEnd = (0 until 32).firstOrNull { out[it] == 0.toByte() } ?: 32
        val name = String(out, 0, nameEnd, Charsets.UTF_8).ifBlank { "PS5" }
        s.console = Console(host, name, out.copyOfRange(32, 48), out.copyOfRange(48, 64))
        log(2, "PS5 kaydı tamam: $name")
        return mapOf("ok" to true, "name" to name, "host" to host)
    }
}
