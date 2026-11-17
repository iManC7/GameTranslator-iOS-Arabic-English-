// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Core.Dubbing;

namespace GameTranslator.Core;

/// <summary>Kare → bölge → yazı tanıma → kararlılık → çeviri → TV.</summary>
/// <param name="clock">Milisaniye saati; testlerde sahtesi verilir.</param>
public sealed class SubtitlePipeline(ITextReader reader, ITextTranslator translator, ISubtitleSender sender,
    ReadScheduler? scheduler = null, Func<long>? clock = null)
{
    /// <summary>
    /// Satır ekrandan bundan uzun süre önce kalktıysa geç gelen çevirisi gösterilmez (sonraki sahnenin üstüne düşmesin).
    /// Yavaş çeviride (ücretsiz motor, zayıf işlemci) art arda gelen satırların çevirisi satır kalktıktan bir iki saniye
    /// sonra gelir; sınır 1 sn iken üç satırlık konuşmanın yalnız ilki görünüyordu.
    /// </summary>
    public const int LateResultMs = 2500;
    /// <summary>Çeviri sürerken sırada en çok bu kadar satır bekler; daha eskisi atlanır (kuyruk konuşma hızıyla büyümesin).</summary>
    public const int MaxWaiting = 2;
    /// <summary>
    /// Paketler açıkken bozuk okunan (OCR izi taşıyan) ve pakette bulunmayan satır en çok bu kadar bekletilir: aynı
    /// satırın düzgün okuması gelirse paketteki Türkçesi gösterilir, gelmezse satır her zamanki gibi çevrilir.
    /// GTA V'te bozuk okumaların yarısında düzgün okuma bir saniye içinde geliyordu.
    /// </summary>
    public const int PackWaitMs = 800;
    /// <summary>Bekleme süresi (0: beklenmez); testler değiştirir.</summary>
    public int PackWait { get; set; } = PackWaitMs;
    /// <summary>
    /// Temiz okunan ama pakette bulunmayan satırın bekleme süresi (0: beklenmez). GTA V'te kalan yanlış çevirilerin çoğu
    /// satırın yarısının okunmasındandı ("hijacked.", "the at?"); yarım okuma sözlükçe temizdir ama pakette yoktur.
    /// Pakette hiç olmayan satır da en çok bu kadar gecikir.
    /// </summary>
    public const int CleanWaitMs = 300;
    /// <summary>Bekletilen okuma bu kadar sonra aynen yeniden okunursa beklemenin kalanı atlanır.</summary>
    public const int SettledAfterMs = 200;
    /// <summary>
    /// Erken bırakma süresi (0: kapalı, bekleme hep sonuna kadar sürer). Paketi olan oyunda bozuk okuma paketteki düzgün
    /// okumayı beklemek için sonuna kadar tutulur; paketi olmayan oyunda aynen yinelenen okumayı bekletmek yalnız gecikmedir.
    /// </summary>
    public int SettledRelease { get; set; }
    /// <summary>
    /// Açıkken ayrı satırdaki konuşmacı adı söze eklenir (<see cref="Reading.WithSpeakerLine"/>) ve yalnız başlık gibi
    /// satırlardan oluşan okuma atılır (<see cref="Reading.WithoutHeadings"/>). Uygulama açar.
    /// </summary>
    public bool TidySpeakersAndHeadings { get; set; }
    /// <summary>
    /// Okunan alandaki satırlardan altyazı olanları seçen süzgeç (okuma, alanın karedeki yeri); null ise hepsi kalır.
    /// </summary>
    public Func<Reading, TextBox, Reading>? LineFilter { get; set; }
    /// <summary>Okuma çevrilemeyecek kadar bozuk mu (uygulama yazım denetimiyle verir); null ise hiçbir okuma atılmaz.</summary>
    public Func<string, bool>? IsGarbage { get; set; }
    public int CleanWait { get; set; } = CleanWaitMs;
    /// <summary>Okuma bozuk mu (bekletilecek mi); uygulama yazım denetimiyle daha iyisini verebilir.</summary>
    public Func<string, bool> LooksMisread { get; set; } = text => PackFuzzy.Damaged(text) || (ExtraMisreadCheck?.Invoke(text) ?? false);
    /// <summary>Uygulamanın verdiği ek bozuk okuma ölçüsü (Windows'ta yazım denetimi); yoksa yalnız OCR izi kuralı.</summary>
    public static Func<string, bool>? ExtraMisreadCheck { get; set; }
    /// <summary>
    /// Okumanın puanı (yüksek: daha çok gerçek sözcük, daha uzun). Bekleme süresince aynı satırın okumalarından en iyisi
    /// seçilir. Uygulama sözlük puanı verebilir (<see cref="ExtraReadingScore"/>); yoksa <see cref="OcrNoise.Score"/>.
    /// </summary>
    public Func<string, int> ReadingScore { get; set; } = text => (ExtraReadingScore ?? OcrNoise.Score)(text);
    public static Func<string, int>? ExtraReadingScore { get; set; }
    /// <summary>Uygulamanın verdiği "çevrilemeyecek kadar bozuk" ölçüsü (Windows'ta yazım denetimi); bkz. <see cref="IsGarbage"/>.</summary>
    public static Func<string, bool>? ExtraGarbageCheck { get; set; }
    /// <summary>Uygulamanın verdiği sözcük denetimi (Windows'ta yazım denetimi); bekletilen okumalar bununla birleştirilir.</summary>
    public static Func<string, bool>? ExtraWordCheck { get; set; }
    /// <summary>Çevrilen satırın daha iyi olmayan yeniden okuması bu süre içinde yeni satır sayılmaz.</summary>
    public const int RereadWithinMs = 4000;
    private const int RememberedPairs = 8;
    /// <summary>
    /// Bekletilen okuma (kaynak, yer, bekletilmeye başlandığı an, en çok bekleme, puanı, ilk okunduğu kare). Ölçümlerde
    /// gecikme satırın ilk okunduğu kareden sayılır; bekleme de gecikmeye girer.
    /// </summary>
    private (string Source, TextBox? Box, long Since, int Wait, int Score, ReadInfo? Read)? held;
    /// <summary>Bekletilen satırın bekleme süresince gelen bütün okumaları (sözcük sözcük birleştirmek için).</summary>
    private readonly List<string> heldReadings = [];
    /// <summary>Son çevrilen (motora ya da pakete giden) okuma, puanı ve zamanı.</summary>
    private (string Source, int Score, long At)? lastSent;

    private readonly object gate = new();
    private readonly Func<long> now = clock ?? DefaultClock;
    /// <summary>Varsayılanı her kareyi okur; uygulama gereksiz okumaları atlayan planı verir.</summary>
    private readonly ReadScheduler schedule = scheduler ?? ReadScheduler.Always();
    private readonly SubtitleStabilizer stabilizer = new(clock: clock ?? DefaultClock, cleanFastPathOnly: translator.Prefetches);
    /// <summary>En son önceden çevirisi başlatılan okuma; aynı metin her karede yeniden istenmez.</summary>
    private string lastPrefetched = "";
    /// <summary>
    /// Her çeviri isteği sıra numarası alır. Aynı anda yalnız bir çeviri sürer, en çok <see cref="MaxWaiting"/> satır sırada
    /// bekler: hızlı konuşmada satırlar sırayla çevrilir, kuyruk konuşma hızıyla büyümez. Bekleyen satırın uzamış ya da
    /// düzelmiş okuması gelirse eskisi sıradan çıkar.
    /// </summary>
    private int lastRequested;
    private int lastShown;
    private Request? inFlight;
    private readonly List<Request> waiting = [];
    private CancellationTokenSource? inFlightCancel;
    private Task pump = Task.CompletedTask;
    /// <summary>Şu an oyun ekranında duran satırın numarası (bölge boşalınca null).</summary>
    private int? lineOnScreen;
    /// <summary>Son çevrilen satırlar (kaynak → çeviri; zaten hedef dildeyse null). Geri gelen satır bunlardan yeniden gösterilir.</summary>
    private readonly List<(int Number, string Source, string? Translation)> pairs = [];
    /// <summary>Son çevrilen satırların ne zaman çevrildiği (adsız yinelemeleri tanımak için).</summary>
    private readonly Dictionary<string, long> shownAt = [];
    /// <summary>Okuma durdurulunca artar; önceki oturumdan dönen çeviriler gösterilmez.</summary>
    private int session;
    /// <summary>Son okunan satırlar; kare değişmediyse yeniden okunmaz, bunlar kullanılır.</summary>
    private Reading lastReading = Reading.Empty;
    /// <summary>Oturumun (hat kurulunca ya da sıfırlanınca) başladığı an; ilk karenin ne kadar sonra geldiği günlüğe yazılır.</summary>
    private long sessionStart = (clock ?? DefaultClock)();
    private bool sawFrame;
    private bool sawText;
    private StabilizerNote? lastNote;
    /// <summary>Son gerçek okumanın süresi (ms); kare değişmediği için yeniden okunmayınca bu kullanılır.</summary>
    private int? lastReadMs;
    /// <summary>Son işlenen karenin okuma bilgisi; o karede doğrulanan satırın isteğine eklenir (ölçümler için).</summary>
    private ReadInfo? currentRead;

    private static long DefaultClock() => Environment.TickCount64;

    /// <summary>Satırın okunduğu kare: geliş anı, okumanın süresi ve yazı tanımanın güveni (0–1).</summary>
    private readonly record struct ReadInfo(long CapturedAt, int? OcrMs, double? Confidence);

    private sealed class Request(int number, string source, TextBox? box, int session)
    {
        public int Number { get; } = number;
        public string Source { get; } = source;
        public TextBox? Box { get; } = box;
        public int Session { get; } = session;
        /// <summary>Satırın ekrandan kalktığı an (hâlâ ekrandaysa null).</summary>
        public long? LeftAt { get; set; }
        /// <summary>Yerine aynı cümlenin uzamış okuması geldi (daktilo efekti); çevirisi gösterilmez.</summary>
        public bool Superseded { get; set; }
        /// <summary>Satırın okunduğu kare (ölçümler için).</summary>
        public ReadInfo Read { get; init; }
    }

    /// <summary>Süren ve sırada bekleyen istekler.</summary>
    private IEnumerable<Request> Requests => inFlight is null ? waiting : waiting.Prepend(inFlight);

    public (string Source, string Translation)? LastPair { get; private set; }
    /// <summary>Son gösterilen çevirinin oyundaki altyazısının karedeki yeri.</summary>
    public TextBox? LastBox { get; private set; }
    public TranslatorStatus? LastError { get; private set; }

    /// <summary>Yeni çeviri gösterilince çağrılır (kaynak, çeviri).</summary>
    public event Action<string, string>? PairShown;

    /// <summary>
    /// Daha iyi ama yavaş çevirmen (çevrimiçi yapay zekâ). Verilirse satır önce hızlı çevirmenle hemen gösterilir; satır
    /// <see cref="UpgradeDelayMs"/> sonra hâlâ ekrandaysa bununla da çevrilir ve sonuç ekrandakinin yerine geçer. Satır
    /// o arada kalkarsa sorulmaz (menüde gezinirken kayan yazılar hak harcamaz), sonuç geç gelirse gösterilmez.
    /// </summary>
    public ITextTranslator? Upgrader { get; set; }
    /// <summary>Hızlı çevirinin gösterilmesinden sonra iyileştirme için beklenen süre.</summary>
    public int UpgradeDelayMs { get; set; } = 250;
    /// <summary>Ekrandaki çeviri iyileştirilince çağrılır (kaynak, yeni çeviri).</summary>
    public event Action<string, string>? PairImproved;

    /// <summary>
    /// Bundan az sözcüklü satır iyileştirilmez: kısa satırda ("Skip", "Exactly!") iki çeviri arasındaki fark küçük, ekrandaki
    /// yazının değişmesi ise "iki kez göründü" gibi rahatsız ediyordu.
    /// </summary>
    public const int UpgradeMinWords = 4;

    private async Task UpgradeAsync(ITextTranslator upgrader, Request request, string source, string first)
    {
        var speech = WithoutSpeaker(source) ?? source;
        if (speech.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Count(word => word.Any(char.IsLetter)) < UpgradeMinWords) return;
        await Task.Delay(UpgradeDelayMs).ConfigureAwait(false);
        lock (gate)
            if (request.Session != session || request.Number != lineOnScreen || lastShown != request.Number) return;
        string better;
        var started = now();
        try { better = (await upgrader.TranslateAsync(source).ConfigureAwait(false)).Trim(); }
        catch (Exception error)
        {
            var why = (error as TranslatorException)?.Status.ToString() ?? error.GetType().Name;
            lock (gate) Write(request, $"iyileştirme yapılamadı ({why}), hızlı çeviri kaldı");
            return;
        }
        lock (gate)
        {
            if (request.Session != session || request.Number != lineOnScreen || lastShown != request.Number)
            {
                Write(request, $"iyileştirme {now() - started} ms, geç: satır kalktı");
                return;
            }
            if (better.Length == 0 || better == first || !stabilizer.ShouldSend(source, better)) return;
            // Neredeyse aynı çeviri için ekrandaki yazı değiştirilmez (göz yine "iki kez geldi" diye algılıyor).
            if (TextMatch.IsSimilar(TextMatch.Normalize(better), TextMatch.Normalize(first), 0.75))
            {
                Write(request, $"iyileştirme {now() - started} ms, hızlı çeviriye çok benziyor, değiştirilmedi");
                return;
            }
            Write(request, $"iyileştirildi ({now() - started} ms): {SubtitleLog.Excerpt(better)}");
            sender.SendSubtitle(better, 15000, request.Box, replaces: true);
            LastPair = (source, better);
            // Satır yeniden okunup geri gelirse (Restore) iyileşmiş çeviri gösterilsin.
            Remember(request.Number, source, better);
        }
        PairImproved?.Invoke(source, better);
    }
    /// <summary>TV'ye giden her yeni satırın ölçümleri; <see cref="PairShown"/>'dan hemen önce çağrılır.</summary>
    public event Action<LineMetrics>? MetricsReady;
    /// <summary>TV'ye giden son satırın ölçümleri (henüz satır gitmediyse null).</summary>
    public LineMetrics? LastMetrics { get; private set; }
    /// <summary>TV'ye giden her yeni altyazının seslendirilecek cümleleri (dublaj).</summary>
    public event Action<IReadOnlyList<SpokenLine>>? SpeechReady;
    /// <summary>Her çeviri denemesinden sonra çağrılır (başarılıysa null).</summary>
    public event Action<TranslatorStatus?>? TranslationResult;

    /// <summary>
    /// Oyun paketi: kararlı satırın hazır Türkçesi (yoksa null). Çeviri motorundan ve önbellekten önce bakılır; bulunursa
    /// motor hiç çağrılmaz ve çeviri beklemeden gösterilir. Uygulama paketler açıkken verir.
    /// </summary>
    public Func<string, PackMatch?>? PackLookup { get; set; }
    /// <summary>Hiçbir pakette bulunmayan kararlı satır (ortak havuz için).</summary>
    public event Action<string>? PackMissed;
    /// <summary>Son gösterilen çevirinin nereden geldiği: "paket" ya da "motor" (günlük ve sayım için).</summary>
    public string? LastOrigin { get; private set; }
    /// <summary>Bu hatta paketten gelen satır sayısı.</summary>
    public int PackHits { get; private set; }

    /// <summary>
    /// Altyazı günlüğü (<see cref="SubtitleLog"/>): ilk kare, okunan her kararlı satır ve akıbeti (paket, önbellek, çeviri,
    /// geç kaldı, atıldı), çöp sayılıp bırakılan ve yok sayılan yeniden okumalar. Kararları değiştirmez; hızlı dönmeli
    /// (kilit tutulurken çağrılır).
    /// </summary>
    public Action<string>? Log { get; set; }
    /// <summary>Paket isabetinde satırın geldiği paket (günlük için; bilinmiyorsa null).</summary>
    public Func<string?>? PackName { get; set; }

    private void Write(string message) => Log?.Invoke(message);

    private void Write(Request request, string message) => Log?.Invoke($"#{request.Number} {message}");

    /// <summary>Okuma çeviriyi beklemez; böylece çeviri sürerken gelen satırlar da yakalanır.</summary>
    /// <param name="capturedAt">Karenin geldiği an (aynı saatle); verilmezse şimdi. Gecikme bu andan ölçülür.</param>
    public async Task ProcessAsync(Frame frame, CropRegion region, long? capturedAt = null)
    {
        var captured = capturedAt ?? now();
        // Okuma sürerken hat sıfırlandıysa (çeviri durdu, hat yeniden kuruldu) bu karenin sonucu yeni oturuma karışmaz.
        int startedSession;
        lock (gate)
        {
            startedSession = session;
            if (!sawFrame)
            {
                sawFrame = true;
                Write($"ilk kare: oturum başından {now() - sessionStart} ms sonra");
            }
        }
        // Yazı tanıma uzun sürebilir; çağıranı (arayüzü) bekletmemek için iş parçacığı havuzunda yapılır.
        var (raw, ocrMs, signature) = await Task.Run(() =>
        {
            byte[]? signature = null;
            try
            {
                var area = RegionCropper.Crop(frame, region);
                signature = RegionCropper.Signature(area);
                ReadPlan plan;
                lock (gate)
                {
                    plan = schedule.Plan(signature);
                    if (plan.Reuse) return (lastReading, lastReadMs, signature);
                }
                var readStarted = now();
                var read = reader.ReadLines(area, plan.Deep);
                var readMs = (int)Math.Clamp(now() - readStarted, 0, int.MaxValue);
                lock (gate)
                {
                    schedule.Record(read.Text);
                    lastReading = read;
                    lastReadMs = readMs;
                }
                return (read, (int?)readMs, signature);
            }
            catch { return (Reading.Empty, (int?)null, signature); }
        });
        lock (gate)
        {
            if (session != startedSession)
            {
                Write("eski okuma bitti, hat sıfırlanmıştı; atıldı");
                return;
            }
        }
        // Kumanda ipuçları ("R2 Swing") altyazı değildir; çevrilmez, yeri de altyazının yerine katılmaz.
        // Yazı tanımanın uydurduğu sözcük çöpleri ("ou$3e") de çevirmene gitmez.
        // Alandaki menü ve köşe göstergeleri de altyazı değildir; yalnız altyazı bloğu çevrilir ve kutusu ona göre olur.
        var area = new TextBox(region.Left, region.Top, region.Right, region.Bottom);
        var cleaned = raw.WithoutButtonPrompts().WithoutOcrNoise();
        // Karışan harfler ("nol" → "not", "Io" → "to") sözcük denetimi varsa onarılır.
        if (ExtraWordCheck is { } wordCheck)
            cleaned = new Reading(cleaned.Lines.Select(line => line with { Text = OcrConfusions.Repair(line.Text, wordCheck) }));
        // Uygulama altyazı satırlarını kendisi seçebilir (otomatik algılama): okunan alan geniştir, satırlar süzülür.
        if (LineFilter is { } filter) cleaned = filter(cleaned, area);
        var reading = cleaned.SubtitleBlock(area);
        // Ayrı satırdaki konuşmacı adı söze eklenir; yalnız başlık ve ekran yazısından oluşan okuma çevrilmez.
        if (TidySpeakersAndHeadings) reading = reading.WithSpeakerLine().WithoutHeadings();
        // Büyük harfli addaki küçük okunan harfler ("ENzo:") paketten gelen çeviride de düzgün görünsün.
        // Art arda iki addan öndeki ("HSS: GAETANO: …") sahneden okunan çöptür.
        static string Labels(string text) => SpeakerNames.FixLabelCaps(SpeakerNames.WithoutLeadingJunkLabel(text));
        if (reading.Lines.Any(line => Labels(line.Text) != line.Text))
            reading = new Reading(reading.Lines.Select(line => line with { Text = Labels(line.Text) }));

        Action? after = null;
        Action? flushed = null;
        lock (gate)
        {
            if (!sawText && reading.Text.Trim().Length > 0)
            {
                sawText = true;
                Write($"ilk yazı: oturum başından {now() - sessionStart} ms sonra {SubtitleLog.Excerpt(reading.Text)}");
            }
            currentRead = new ReadInfo(captured, ocrMs, reading.Confidence);
            // Bölge izi ve satırın yeri: okuma boş dönse de satırın yeri değişmediyse satır silinmez (parlak zemin).
            var action = stabilizer.Feed(reading.Text, signature, reading.Box);
            // Ekranda duran kötü yeniden okuma her karede not edilir; günlüğe bir kez yazılır.
            if (stabilizer.Note is { } note && note != lastNote)
            {
                lastNote = note;
                Write(note.Kind == StabilizerNoteKind.WorseReread
                    ? $"yeniden-okuma: {SubtitleLog.Excerpt(note.Text)} gösterilenden kötü, yok sayıldı"
                    : $"çöp: {SubtitleLog.Excerpt(note.Text)} kararlı olmadan kalktı, gönderilmedi");
            }
            var box = reading.Box?.PlacedIn(area).CenteredOnScreen();
            // Satır henüz doğrulanmadı: çevirisi şimdiden başlasın, doğrulanınca beklemeden gösterilsin.
            if (action.Kind == StabilizerKind.None && translator.Prefetches && reading.Text.Trim() is { Length: >= 6 } early && early != lastPrefetched)
            {
                lastPrefetched = early;
                translator.Prefetch(early);
            }
            if (held is { } waiting)
            {
                if (action.Kind == StabilizerKind.Translate)
                {
                    // Bozuk ve yarım okumaların her biri kararlayıcıya yeni satır gibi görünür.
                    var source = action.Text!;
                    var wait = Math.Max(waiting.Wait, WaitFor(source));
                    if (PackLookup?.Invoke(source) is not null)
                    {
                        // Pakette bulundu: bekleyen (bozuk/yarım) okuma çevrilmez, bu okuma her zamanki yoldan gider.
                        held = null;
                        Write($"bekleyen atıldı: {SubtitleLog.Excerpt(waiting.Source)} yerine paketteki satır geldi");
                    }
                    else if ((IsRereadOf(source, waiting.Source) || IsRereadOf(waiting.Source, source)) && now() - waiting.Since < wait)
                    {
                        // Aynı satırın başka bir okuması: daha iyisi tutulur, süre baştan başlamaz.
                        NoteHeldReading(source);
                        var score = ReadingScore(source);
                        if (score > waiting.Score)
                        {
                            var merged = KeepMissingLines(source, waiting.Source);
                            held = (merged, box ?? waiting.Box, waiting.Since, wait, ReadingScore(merged), waiting.Read);
                        }
                        action = StabilizerAction.None;
                        LineLeft();
                    }
                    else if (LooksMisread(waiting.Source))
                    {
                        // Bekleyen bozuk okumaydı ve yerine başka bir okuma geldi: bozuk okuma çevrilmez.
                        held = null;
                        Write($"bozuk okuma atıldı: {SubtitleLog.Excerpt(waiting.Source)} yerine başka satır geldi");
                    }
                    else if (LooksMisread(source) && now() - waiting.Since < waiting.Wait)
                    {
                        // Araya giren bozuk ve ilgisiz okuma ("Go to" beklerken "Bluffe") bekleyeni bozmaz; yok sayılır.
                        action = StabilizerAction.None;
                    }
                    else
                    {
                        // Bekleyen temiz bir satırdı, yerine başka satır geldi: önce o çevrilir.
                        held = null;
                        flushed = Enqueue(Settle(waiting.Source), waiting.Box, waiting.Read);
                    }
                }
                else if (action.Kind != StabilizerKind.None)
                {
                    // Bölge boşaldı ya da eski satır geri geldi: bekleyen temiz satır her zamanki gibi çevrilir; bozuk
                    // okuma ("Bluffe") çevrilmez.
                    held = null;
                    if (!LooksMisread(waiting.Source)) flushed = Enqueue(Settle(waiting.Source), waiting.Box, waiting.Read);
                    else Write($"bozuk okuma atıldı: {SubtitleLog.Excerpt(waiting.Source)} beklerken kalktı");
                }
                else if (reading.Text.Trim().Length >= 3 && PackLookup?.Invoke(reading.Text) is { } packed)
                {
                    // Aynı satır bu kez düzgün okundu: paketteki Türkçesi gösterilir, bozuk okuma çevrilmez.
                    held = null;
                    var request = new Request(++lastRequested, reading.Text.Trim(), box ?? waiting.Box, session)
                        { Read = waiting.Read ?? currentRead ?? new ReadInfo(now(), null, null) };
                    lineOnScreen = request.Number;
                    after = ShowPacked(request, packed);
                }
                else
                {
                    // Kararlayıcı aynı satır saydı; okuma daha iyiyse (ör. yarım okumanın tamamı) o tutulur.
                    var text = reading.Text.Trim();
                    if (text.Length >= 3 && Related(text, waiting.Source)) NoteHeldReading(text);
                    if (text.Length >= 3 && Related(text, waiting.Source) && ReadingScore(text) > waiting.Score)
                    {
                        var merged = KeepMissingLines(text, waiting.Source);
                        held = waiting = (merged, box ?? waiting.Box, waiting.Since, waiting.Wait, ReadingScore(merged), waiting.Read);
                    }
                    // Aynı okuma yine geldiyse yazı tanıma satırı hep böyle okuyordur (ör. kesme işaretini hiç görmüyor);
                    // daha iyisi gelmeyecek, sürenin dolması beklenmez.
                    var settled = SettledRelease > 0 && TextMatch.Normalize(text) == TextMatch.Normalize(waiting.Source) &&
                                  now() - waiting.Since >= SettledRelease;
                    if (settled || now() - waiting.Since >= waiting.Wait)
                    {
                        held = null;
                        after = Enqueue(Settle(waiting.Source), waiting.Box, waiting.Read);
                    }
                }
            }
            switch (action.Kind)
            {
                case StabilizerKind.Clear:
                    LineLeft();
                    sender.Clear();
                    Write("kalktı: bölge boş okundu, ekran temizlendi");
                    break;
                case StabilizerKind.Translate:
                    LineLeft();
                    after = TranslateOrHold(action.Text!, box);
                    break;
                case StabilizerKind.Restore:
                    LineLeft();
                    after = Restore(action.Text!, box);
                    break;
            }
        }
        // Olaylar kilidin dışında çağrılır.
        flushed?.Invoke();
        after?.Invoke();
    }

    /// <summary>Satırın süreleri günlüğe: kare alınınca başlayan toplam gecikme ve içindeki okuma ve çeviri payı.</summary>
    private static string Timing(LineMetrics metrics) =>
        $"süre: okuma {metrics.OcrMs?.ToString() ?? "-"} ms, çeviri {metrics.TranslationMs?.ToString() ?? "-"} ms, toplam {metrics.TotalMs} ms";

    private void NoteHeldReading(string reading)
    {
        if (heldReadings.Count < 8 && !heldReadings.Contains(reading)) heldReadings.Add(reading);
    }

    /// <summary>
    /// Bekleyen satırın çevrilecek hâli: bekleme süresince gelen okumalar sözcük sözcük birleştirilir
    /// (<see cref="ReadingConsensus"/>); birleşen okuma günlüğe yazılır.
    /// </summary>
    private string Settle(string source)
    {
        var merged = ReadingConsensus.Merge(source, heldReadings, ExtraWordCheck);
        heldReadings.Clear();
        if (merged != source) Write($"birleşik okuma: {SubtitleLog.Excerpt(source)} → {SubtitleLog.Excerpt(merged)}");
        return merged;
    }

    /// <summary>
    /// Paketler açıkken bozuk okunan ve pakette bulunmayan satır hemen çevrilmez, <see cref="PackWaitMs"/> kadar
    /// bekletilir; temiz okunan ya da pakette bulunan satır her zamanki yoldan gider.
    /// </summary>
    private Action? TranslateOrHold(string source, TextBox? box)
    {
        // Yeniden okuma denetimi gecikme eklemez; bekleme süreleri 0 olsa da çalışır.
        var enabled = PackLookup is not null || HoldWithoutPacks;
        if (!enabled) return Enqueue(source, box);
        // Az önce çevrilen satırın daha iyi olmayan yeniden okuması yeni satır değildir (TV'de üst üste binmesin).
        // Paketten önce bakılır: satırın yarım okunan sonu ("look good.", "that.") pakette tek başına da bulunuyor ve
        // ekranda bir an "Güzel görün." diye beliriyordu.
        // Tam cümle gibi görünen gürültülü okuma da ("Yeah? Dihnnr.") buna dahildir; bu yüzden beklemeden önce bakılır.
        if (lastSent is { } last && now() - last.At < RereadWithinMs && AllLinesCovered(source, last.Source) && ReadingScore(source) <= last.Score)
        {
            lastSent = last with { At = now() };
            Write($"yeniden-okuma: {SubtitleLog.Excerpt(source)} az önce çevrilenden iyi değil, yok sayıldı");
            return null;
        }
        // Konuşmacı adı kareden kareye görünüp kayboluyorsa araya başka okumalar girebilir; az önce adıyla çevrilmiş
        // satırın adsız hâli yine aynı satırdır ("ANNA: Come up now!" … "Come up now!").
        var bare = TextMatch.Normalize(source);
        if (bare.Length > 0 && shownAt.Any(entry => now() - entry.Value < RereadWithinMs &&
                WithoutSpeaker(entry.Key) is { } spoken && TextMatch.Normalize(spoken) == bare))
        {
            Write($"yeniden-okuma: {SubtitleLog.Excerpt(source)} az önce konuşmacı adıyla çevrildi, yok sayıldı");
            return null;
        }
        if (PackLookup?.Invoke(source) is not null) return Enqueue(source, box);
        var wait = WaitFor(source);
        if (wait <= 0) return Enqueue(source, box);
        held = (source, box, now(), wait, ReadingScore(source), currentRead);
        heldReadings.Clear();
        heldReadings.Add(source);
        Write($"bekletiliyor (en çok {wait} ms): {SubtitleLog.Excerpt(source)}");
        return null;
    }

    /// <summary>
    /// Pakette bulunmayan okumanın bekleme süresi: bozuksa <see cref="PackWait"/>; temiz ama yarım olabilecekse
    /// (küçük harfle başlıyor ya da cümle sonu işareti yok: "Get Franklin close to the") <see cref="CleanWait"/>;
    /// temiz ve tam cümleyse beklenmez (gecikme olmasın).
    /// </summary>
    private int WaitFor(string source)
    {
        if (PackLookup is null && !HoldWithoutPacks) return 0;
        if (LooksMisread(source)) return Math.Max(0, PackWait);
        return LooksComplete(source) ? 0 : Math.Max(0, CleanWait);
    }

    /// <summary>
    /// Okumanın her satırı az önce çevrilenin (aynı ya da yeniden okunmuş) bir satırı mı. İki kişi konuşurken
    /// "He's a bum!" ardından "He's a bum! / Oh my God!" gelirse ikinci satır yenidir; okuma tekrar sayılmaz.
    /// </summary>
    private bool AllLinesCovered(string reading, string previous)
    {
        var lines = reading.Split('\n').Select(line => line.Trim()).Where(line => line.Length > 0).ToList();
        return lines.Count > 0 && lines.All(line => Covered(line, previous));
    }

    private bool Covered(string line, string previous)
    {
        var norm = TextMatch.Normalize(line);
        if (norm.Length == 0) return true;
        // Başka konuşmacının satırı öncekinin yarım okuması değildir ("Vargas: "Just?"" önceki satırda "Vargas" ve
        // "just" geçse de yenidir).
        if (SpeakerOf(line) is { } speaker && !previous.Split('\n').Any(old => SpeakerOf(old) is not { } other || other == speaker))
            return false;
        var flatPrevious = previous.Replace('\n', ' ');
        if (IsRereadOf(line, flatPrevious)) return true;
        if (previous.Split('\n').Any(old => TextMatch.Normalize(old) == norm || IsRereadOf(line, old))) return true;
        // Konuşmacı adı bir karede okunup ötekinde kaçabiliyor ("Kraven: Pathetic." ardından "Pathetic."): adsız okuma
        // aynı satırdır, yeni satır değil (aynı çeviri bir adlı bir adsız iki kez gösteriliyordu).
        return previous.Split('\n').Select(WithoutSpeaker).Any(bare => bare is not null && (TextMatch.Normalize(bare) == norm || IsRereadOf(line, bare)));
    }

    /// <summary>Harflerinin en az üçte biri küçük harf ("EXECUTIVE PRODUCER: GUILLAUME de FONDAUMIERE" değil).</summary>
    private static bool MostlyLowercase(string row)
    {
        var letters = row.Where(char.IsLetter).ToList();
        return letters.Count > 0 && letters.Count(char.IsLower) * 3 >= letters.Count;
    }

    /// <summary>"Kraven: Pathetic." → "Kraven"; satır konuşmacı adıyla başlamıyorsa null.</summary>
    private static string? SpeakerOf(string line)
    {
        var trimmed = line.Trim();
        var colon = trimmed.IndexOf(": ", StringComparison.Ordinal);
        if (colon is < 2 or > 30 || !char.IsUpper(trimmed[0])) return null;
        var name = trimmed[..colon];
        return name.Split(' ').Length <= 3 && name.All(c => char.IsLetter(c) || c is ' ' or '-' or '.' or '\'' or '’') ? name : null;
    }

    /// <summary>"Kraven: Pathetic." → "Pathetic."; satır konuşmacı adıyla başlamıyorsa null.</summary>
    private static string? WithoutSpeaker(string line)
    {
        var trimmed = line.Trim();
        var colon = trimmed.IndexOf(':');
        if (colon is < 2 or > 30 || !char.IsUpper(trimmed[0]) || colon >= trimmed.Length - 2) return null;
        return trimmed[(colon + 1)..].Trim();
    }

    /// <summary>
    /// Daha iyi okuma bekleyenin yerine geçerken bekleyende olup yenisinde olmayan temiz satırlar korunur (iki satırlı
    /// altyazının ikinci satırı bir okumada çıkıp ötekinde kaçabiliyor: "I don't give a shit!").
    /// </summary>
    private string KeepMissingLines(string better, string older)
    {
        var extra = older.Split('\n').Select(line => line.Trim())
            .Where(line => line.Length > 0 && !LooksMisread(line) && !Covered(line, better))
            .ToList();
        return extra.Count == 0 ? better : better.TrimEnd() + "\n" + string.Join('\n', extra);
    }

    /// <summary><paramref name="x"/> sözcükleri <paramref name="y"/>'de aynı sırada geçiyor ama bitişik bir parça değil.</summary>
    private static bool IsGappedSubsequence(string[] x, string[] y)
    {
        int i = 0, firstMatch = -1, lastMatch = -1;
        for (var j = 0; j < y.Length && i < x.Length; j++)
        {
            if (y[j] != x[i]) continue;
            if (firstMatch < 0) firstMatch = j;
            lastMatch = j;
            i++;
        }
        return i == x.Length && lastMatch - firstMatch + 1 > x.Length;
    }

    /// <summary>Her satırı büyük harfle başlayıp nokta, soru, ünlem ya da üç noktayla biten okuma.</summary>
    internal static bool LooksComplete(string text)
    {
        var lines = text.Split('\n').Select(line => line.Trim()).Where(line => line.Length > 0).ToList();
        return lines.Count > 0 && lines.All(line =>
            line.FirstOrDefault(char.IsLetter) is var first && char.IsUpper(first) && SubtitleStabilizer.EndsSentence(line));
    }

    /// <summary>
    /// <paramref name="newer"/>, <paramref name="older"/>'ın yeniden okuması mı: biri bozuksa ortak sözcükler yeter
    /// (<see cref="Related"/>); ikisi de temizse yeni okuma eskinin kesilmiş bir parçası olmalı ve cümle sonu işareti
    /// taşımamalı ("Get Franklin close to the"). "I swear to God, you kill me!" ardından gelen "You kill me!" ayrı satırdır.
    /// </summary>
    private bool IsRereadOf(string newer, string older)
    {
        // Harf harf çok benzeyen, aynı sayıda sözcüklü okuma aynı satırın gürültülü hâlidir ("Yeah? Damme" /
        // "Yeäh? Damn." / "Yeah? Damn."): sözlük büyük harfli bozuk sözcüğü özel ad sanabiliyor.
        var normNewer = TextMatch.Normalize(newer);
        var normOlder = TextMatch.Normalize(older);
        var x = normNewer.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var y = normOlder.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (normNewer.Length >= 4 && x.Length == y.Length && TextMatch.IsSimilar(normNewer, normOlder, 0.75)) return true;
        // Aynı sayıda sözcük ve yalnız sözlükte olmayan sözcüklerde ayrışma ("Yeah? Dihnnr." / "Yeah? Damn."): bozuk tekrar.
        if (x.Length >= 2 && x.Length == y.Length)
        {
            var differing = Enumerable.Range(0, x.Length).Where(i => x[i] != y[i]).ToList();
            if (differing.Count >= 1 && differing.Count * 2 <= x.Length && differing.All(i => LooksMisread(x[i]))) return true;
        }
        if (LooksMisread(newer) || LooksMisread(older)) return Related(newer, older);
        if (x.Length == 0 || x.Length > y.Length) return false;
        // Aradan sözcük düşmüş okuma ("Go to Bluffs." / "Go to Pacific Bluffs."): sözcükler aynı sırada ama bitişik değil.
        if (x.Length >= 2 && x.Length < y.Length && IsGappedSubsequence(x, y)) return true;
        // Soldan kesik okuma küçük harfle ya da harf olmayan bir işaretle başlar ("can always buy another boat.",
        // "prick!"); büyük harfle başlayan ayrı satır ("You kill me!") yeniden okuma sayılmaz.
        var startsLower = newer.TrimStart().FirstOrDefault() is var head && !char.IsUpper(head);
        if (SubtitleStabilizer.EndsSentence(newer) && !(startsLower && x.Length < y.Length)) return false;
        for (var start = 0; start + x.Length <= y.Length; start++)
            if (y.AsSpan(start, x.Length).SequenceEqual(x)) return true;
        return false;
    }

    /// <summary>
    /// Paketler kapalıyken (ya da paketi olmayan oyunda) da okumalar bekletilip en iyisi seçilsin mi. Varsayılanı
    /// <see cref="DefaultHoldWithoutPacks"/>; Windows uygulaması yazım denetimi varken açar.
    /// </summary>
    public bool HoldWithoutPacks { get; set; } = DefaultHoldWithoutPacks;
    public static bool DefaultHoldWithoutPacks { get; set; }

    /// <summary>
    /// İki okuma aynı altyazının okunuşları mı: ortak sözcükler kısa olanın en az yarısı (iki sözcükten kısa satırlarda
    /// biri ötekini içermeli). "And you watch your language!" / "r guage! fair!" ilgisizdir (bozuk okuma ayrıca elenir).
    /// </summary>
    /// <summary><paramref name="newer"/> aynı satırın sonraki (uzamış ya da düzelmiş) okuması mı.</summary>
    private static bool SameLineRead(string newer, string older) =>
        TextMatch.IsRevision(newer, older) || Related(WithoutSpeaker(newer) ?? newer, WithoutSpeaker(older) ?? older);

    internal static bool Related(string a, string b)
    {
        var x = TextMatch.Normalize(a).Split(' ', StringSplitOptions.RemoveEmptyEntries).ToList();
        var y = TextMatch.Normalize(b).Split(' ', StringSplitOptions.RemoveEmptyEntries).ToList();
        if (x.Count == 0 || y.Count == 0) return false;
        var remaining = new List<string>(y);
        var shared = x.Count(word => remaining.Remove(word));
        var shorter = Math.Min(x.Count, y.Count);
        return shorter <= 1 ? shared >= 1 : shared >= 2 && shared * 2 >= shorter;
    }

    /// <summary>Ekrandaki satır kalktı (ya da yerine başkası geldi); çevirisi sürüyorsa ne zaman kalktığı not edilir.</summary>
    private void LineLeft()
    {
        if (lineOnScreen is not { } number) return;
        var time = now();
        foreach (var request in Requests)
            if (request.Number == number) request.LeftAt ??= time;
        lineOnScreen = null;
    }

    /// <returns>Kilit bırakıldıktan sonra çağrılacak olaylar (paketten gelen satır).</returns>
    private Action? Enqueue(string source, TextBox? box, ReadInfo? read = null)
    {
        // Bekleme süresinde düzgünü gelmeyen, sözcüklerinin çoğu gerçek olmayan okuma hiç çevrilmez: anlamsız bir
        // Türkçe satır göstermektense o satırı kaçırmak yeğdir (düzgün okuması gelirse o gösterilir).
        if (IsGarbage?.Invoke(source) == true && PackLookup?.Invoke(source) is null)
        {
            Write($"çöp: {SubtitleLog.Excerpt(source)} okunamadı, çevrilmedi");
            return null;
        }
        var request = new Request(++lastRequested, source, box, session) { Read = read ?? currentRead ?? new ReadInfo(now(), null, null) };
        lineOnScreen = request.Number;
        lastSent = (source, ReadingScore(source), now());
        if (PackLookup?.Invoke(source) is { } packed) return ShowPacked(request, packed);
        var missed = PackMissed;
        if (inFlight is not { } current)
        {
            Write(request, $"{SubtitleLog.Excerpt(source)} → çeviriye");
            inFlight = request;
            pump = Pump(request);
        }
        else
        {
            Write(request, $"{SubtitleLog.Excerpt(source)} → sırada (çeviri sürüyor: #{current.Number})");
            // Aynı cümlenin eski okuması sırada bekliyorsa çıkar; sıra dolduysa en eski bekleyen atlanır.
            foreach (var old in waiting.Where(w => TextMatch.IsRevision(source, w.Source)))
                Write(old, $"atıldı: yerine düzelmiş okuması geldi (#{request.Number})");
            waiting.RemoveAll(w => TextMatch.IsRevision(source, w.Source));
            waiting.Add(request);
            if (waiting.Count > MaxWaiting)
            {
                foreach (var old in waiting.Take(waiting.Count - MaxWaiting)) Write(old, "atıldı: sıra doldu");
                waiting.RemoveRange(0, waiting.Count - MaxWaiting);
            }
            // Süren çeviri bu cümlenin yarım okumasınınsa (daktilo efekti) beklenmez: bırakılır, tamamı hemen çevrilir.
            // İptal en sonda: sıra iptalle aynı iş parçacığında ilerleyebilir, yeni satır o zaman sırada olmalı.
            if (!current.Superseded && current.Session == session && TextMatch.IsGrowth(source, current.Source))
            {
                Write(current, $"bırakıldı: uzamış okuması geldi (#{request.Number})");
                current.Superseded = true;
                inFlightCancel?.Cancel();
            }
        }
        return missed is null ? null : () => missed(source);
    }

    /// <summary>Satır az önce gösterilenin uzamış ya da düzelmiş okuması mı (TV yerine koyar, üstüne yığmaz).</summary>
    private bool RevisesShown(string source)
    {
        if (LastPair is not { } shown) return false;
        if (TextMatch.IsRevision(source, shown.Source)) return true;
        // Önce adsız okunup sonra konuşmacı adıyla gelen satır aynı satırın düzelmiş hâlidir ("I know!" ardından
        // "Ganke: I know!"): TV'de öncekinin üstüne yığılmaz, yerine geçer.
        return source.Split('\n').Length == 1 && WithoutSpeaker(source) is { } bare &&
               (TextMatch.Normalize(bare) == TextMatch.Normalize(shown.Source) || TextMatch.IsRevision(bare, shown.Source) ||
                TextMatch.IsSimilar(TextMatch.Normalize(bare), TextMatch.Normalize(shown.Source), 0.8));
    }

    /// <summary>Paketteki Türkçe hemen gösterilir; süren çevirinin sonucu (eski satır) artık gösterilmez.</summary>
    private Action? ShowPacked(Request request, PackMatch packed)
    {
        foreach (var old in waiting) Write(old, $"atıldı: sonraki satır paketten geldi (#{request.Number})");
        waiting.Clear();
        PackHits++;
        var source = request.Source;
        var translated = packed.Text;
        var shouldSend = stabilizer.ShouldSend(source, translated);
        Remember(request.Number, source, shouldSend ? translated : null);
        var pack = PackName?.Invoke() is { } name ? "paket:" + name : "paket";
        if (!shouldSend)
        {
            Write(request, $"{SubtitleLog.Excerpt(source)} → {pack}, zaten hedef dilde, gösterilmedi");
            return null;
        }
        Write(request, $"{SubtitleLog.Excerpt(source)} → {pack}");
        lastShown = request.Number;
        sender.SendSubtitle(translated, 15000, request.Box, replaces: RevisesShown(source));
        LastPair = (source, translated);
        LastBox = request.Box;
        LastOrigin = "paket";
        var read = request.Read;
        var metrics = LineMetrics.Measure(read.CapturedAt, read.OcrMs, null, now(), read.Confidence, LineOrigin.Pack);
        LastMetrics = metrics;
        Write(request, Timing(metrics));
        var measured = MetricsReady;
        var shown = PairShown;
        var speech = SpeechReady;
        return () =>
        {
            measured?.Invoke(metrics);
            shown?.Invoke(source, translated);
            speech?.Invoke(packed.Spoken);
        };
    }

    /// <summary>Az önce kalkıp geri gelen satır: çevirmene gitmeden eski çevirisi yeniden gösterilir.</summary>
    private Action? Restore(string source, TextBox? box)
    {
        // Geri gelen satır hâlâ ekrandaki satırdır; yarım yeniden okumaları yeni satır sayılmasın.
        if (lastSent is { } last && (Related(source, last.Source) || AllLinesCovered(source, last.Source)))
        {
            // Geri gelen okuma daha iyiyse ("Go to Pacific Bluffs."), artık ekrandaki satır odur.
            var restoredScore = ReadingScore(source);
            lastSent = restoredScore > last.Score ? (source, restoredScore, now()) : last with { At = now() };
            // Geri gelen okuma son çevrilen tam satırın yarım hâliyse ("Get Franklin close to the"), yarım okumanın
            // eski çevirisi değil tam satırın çevirisi gösterilir.
            if (HoldWithoutPacks || PackLookup is not null)
            {
                var full = pairs.FindLastIndex(pair => pair.Source == last.Source);
                if (full >= 0 && last.Source != source && AllLinesCovered(source, last.Source) && ReadingScore(source) < last.Score)
                {
                    var (number, _, translation) = pairs[full];
                    lineOnScreen = number;
                    Write($"#{number} geri geldi (yarım okuması): {SubtitleLog.Excerpt(source)}");
                    if (translation is not null)
                    {
                        sender.SendSubtitle(translation, 15000, box, replaces: true);
                        LastPair = (last.Source, translation);
                        LastBox = box;
                    }
                    return null;
                }
            }
        }
        var index = pairs.FindLastIndex(pair => pair.Source == source);
        if (index >= 0)
        {
            var (number, _, translation) = pairs[index];
            lineOnScreen = number;
            Write($"#{number} geri geldi: {SubtitleLog.Excerpt(source)}");
            if (translation is null) return null;
            sender.SendSubtitle(translation, 15000, box, replaces: RevisesShown(source));
            LastPair = (source, translation);
            LastBox = box;
            return null;
        }
        // Çevirisi henüz gelmediyse istek sürüyordur; satır yeniden ekranda sayılır.
        foreach (var request in Requests)
        {
            if (request.Source != source || request.Session != session || request.Superseded) continue;
            request.LeftAt = null;
            lineOnScreen = request.Number;
            return null;
        }
        // Çevirisi hiç yoksa (atlanmış ya da başarısız olmuş) normal yoldan çevrilir; bekleme ve yeniden okuma denetimi
        // de uygulanır (bozuk okuma "Yeäh? Damn." bu yoldan doğrudan çeviriye gidiyordu).
        return TranslateOrHold(source, box);
    }

    /// <summary>Süren çeviriyi, bitince de sıradakini çevirir; sıra boşalınca durur.</summary>
    private async Task Pump(Request first)
    {
        var request = first;
        while (true)
        {
            var cancel = new CancellationTokenSource();
            lock (gate) inFlightCancel = cancel;
            // Olay işleyicilerinden biri hata verse de sıra takılı kalmasın.
            try { await Translate(request, cancel.Token); }
            catch { }
            lock (gate)
            {
                inFlightCancel = null;
                cancel.Dispose();
                // Ekrandan çoktan kalkmış satır çevrilmez; çevirisi zaten gösterilmeyecekti.
                var time = now();
                foreach (var old in waiting)
                {
                    if (old.Session != session) Write(old, "atıldı: oturum bitti");
                    else if (old.LeftAt is { } gone && time - gone > LateResultMs)
                        Write(old, $"atıldı: çevrilmeden ekrandan kalktı ({time - gone} ms önce)");
                }
                waiting.RemoveAll(w => w.Session != session || w.LeftAt is { } left && time - left > LateResultMs);
                // Ekrandan kalkmış satırın arkasından aynı satırın başka bir okuması geldiyse eski okuma çevrilmez: yavaş
                // motorda (çevrimiçi) yazı belirirken gelen bozuk okumalar sıraya diziliyor, satır gittikten sonra art arda
                // gösteriliyordu (Metro: "Shut I can't / Shi!!", "Shut I can't believe Just"). Farklı satırlar kalır.
                var superseded = waiting.Where(w => w.Number != lineOnScreen &&
                    waiting.Any(later => later.Number > w.Number && SameLineRead(later.Source, w.Source))).ToList();
                foreach (var old in superseded) Write(old, "atıldı: ekrandan kalktı, aynı satırın yeni okuması geldi");
                waiting.RemoveAll(superseded.Contains);
                var next = waiting.Count > 0 ? waiting[0] : null;
                if (next is not null) waiting.RemoveAt(0);
                inFlight = next;
                if (next is null) return;
                request = next;
            }
        }
    }

    /// <summary>Süren bütün çevirilerin bitmesini bekler.</summary>
    public async Task WaitForTranslationsAsync()
    {
        while (true)
        {
            Task running;
            lock (gate) running = pump;
            if (running.IsCompleted) return;
            await running;
        }
    }

    /// <summary>Satır ekrandan kalktıktan sonra gelen çevirinin TV'de kalacağı süre (TV uygulamasıyla aynı kural).</summary>
    public static int ReadingTime(string text) => Math.Min(8000, 2000 + (text.Length * 60));

    private async Task Translate(Request request, CancellationToken token)
    {
        var source = request.Source;
        var started = now();
        // Önbellekten mi geldi, hangi motor çevirdi: yalnız günlük için (bu yöntemin beklediği çağrılar görür).
        var probe = new TranslationProbe();
        TranslationProbe.Current = probe;
        string translated;
        try
        {
            translated = await translator.TranslateAsync(source, token);
        }
        catch (Exception error)
        {
            lock (gate)
            {
                // Yerine uzamış okuması gelen satırın bırakılan çevirisi hata sayılmaz.
                if (request.Session != session || request.Superseded) return;
                var retry = request.Number == lineOnScreen ? ", satır ekrandayken yeniden denenecek" : "";
                Write(request, $"hata ({now() - started} ms): {(error as TranslatorException)?.Status.ToString() ?? error.GetType().Name}{retry}");
                // Model eksikse ya da geçici bir hata olduysa satır ekranda kaldıkça (saniyede en çok bir kez) yeniden denenir.
                LastError = (error as TranslatorException)?.Status;
                if (request.Number == lineOnScreen) stabilizer.ForgetSent();
            }
            TranslationResult?.Invoke(LastError);
            return;
        }

        var finished = now();
        var result = $"{probe.Outcome()} {now() - started} ms";
        lock (gate)
        {
            if (request.Session != session)
            {
                Write(request, $"{result}, atıldı: oturum bitti");
                return;
            }
            LastError = null;
        }
        TranslationResult?.Invoke(null);

        LineMetrics metrics;
        lock (gate)
        {
            if (request.Session != session) return;
            // Çevirisi kendisiyle aynı dönen satır çoğunlukla zaten hedef dildedir; ama konuşmacısı belli satırda bu, çevrilmeyen
            // bir ad ya da büyüdür ("Scott Coleman: Protego!"). O satır da gösterilir: yoksa TV'de önceki çeviri kalıyordu.
            // Sözünde küçük harf olmalı: büyük harfli jenerik satırı ("PRODUCTION DIRECTOR: SOPHIE BUHLER") konuşma değildir.
            var shouldSend = stabilizer.ShouldSend(source, translated) ||
                             source.Split('\n').Any(row => SpeakerOf(row) is not null && MostlyLowercase(row));
            Remember(request.Number, source, shouldSend ? translated : null);
            if (request.Number <= lastShown || !shouldSend || request.Superseded)
            {
                var reason = !shouldSend ? "zaten hedef dilde"
                    : request.Superseded ? "uzamış okuması geldi" : $"daha yeni satır gösterildi (#{lastShown})";
                Write(request, $"{result}, atıldı: {reason}");
                return;
            }
            var onScreen = request.Number == lineOnScreen;
            // Satır kalktı ve aynı satırın yeni bir okuması çevrilmek üzere: eski okumanın çevirisi gösterilmez.
            if (!onScreen && lastRequested > request.Number && lastSent is { } newer && SameLineRead(newer.Source, source))
            {
                Write(request, $"{result}, atıldı: ekrandan kalktı, aynı satırın yeni okuması geldi (#{lastRequested})");
                return;
            }
            // Satır ekrandan çoktan kalktıysa çevirisi sonraki sahnenin üstüne düşmesin.
            if (!onScreen && request.LeftAt is { } left && now() - left > LateResultMs)
            {
                Write(request, $"{result}, geç: satır {now() - left} ms önce kalktı, gösterilmedi");
                return;
            }
            Write(request, $"{result}, gösterildi{(onScreen ? "" : " (satır kalkmıştı)")}");
            lastShown = request.Number;
            // Satır hâlâ ekrandaysa kalkınca silinir; kalktıysa okunacak kadar gösterilir.
            sender.SendSubtitle(translated, onScreen ? 15000 : ReadingTime(translated), request.Box, replaces: RevisesShown(source));
            LastPair = (source, translated);
            LastBox = request.Box;
            LastOrigin = "motor";
            var read = request.Read;
            metrics = LineMetrics.Measure(read.CapturedAt, read.OcrMs, (started, finished), now(), read.Confidence, LineOrigin.Engine);
            LastMetrics = metrics;
            Write(request, Timing(metrics));
        }
        MetricsReady?.Invoke(metrics);
        PairShown?.Invoke(source, translated);
        if (SpeechReady is { } speech) speech(translator.SpokenLines(source));
        if (Upgrader is { } upgrader) _ = UpgradeAsync(upgrader, request, source, translated);
    }

    private void Remember(int number, string source, string? translation)
    {
        shownAt[source] = now();
        foreach (var old in shownAt.Where(entry => now() - entry.Value > RereadWithinMs * 3).Select(entry => entry.Key).ToList()) shownAt.Remove(old);
        pairs.RemoveAll(pair => pair.Source == source);
        pairs.Add((number, source, translation));
        if (pairs.Count > RememberedPairs) pairs.RemoveAt(0);
    }

    /// <summary>Okuma durunca TV'deki son altyazıyı kaldırır.</summary>
    public void Reset()
    {
        lock (gate)
        {
            Write($"hat sıfırlandı (paketten {PackHits} satır)");
            sessionStart = now();
            sawFrame = false;
            sawText = false;
            lastNote = null;
            session++;
            lineOnScreen = null;
            waiting.Clear();
            held = null;
            lastSent = null;
            inFlightCancel?.Cancel();
            pairs.Clear();
            lastReading = Reading.Empty;
            lastReadMs = null;
            currentRead = null;
            schedule.Reset();
            if (stabilizer.Reset() == StabilizerAction.Clear) sender.Clear();
        }
    }
}

