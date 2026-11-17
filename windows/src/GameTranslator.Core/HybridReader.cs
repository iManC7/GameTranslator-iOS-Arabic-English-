// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// İki okuyucuyu birlikte kullanır: hızlı olan (Windows'un yazı tanıması) her karede çalışır; okuması bozuk görünürse
/// aynı görüntü güçlü ama yavaş olanla (PP-OCR) da okunur ve daha iyi puan alan seçilir. Düz zeminde hızlı okuyucu
/// kusursuzdur ve güçlü okuyucu hiç çalışmaz; hareketli, parlak zeminde ya da yazı belirirken hızlı okuyucunun
/// bozduğu satırı güçlü okuyucu kurtarır. Hızlı okuyucu hiç yazı bulamadığında güçlü okuyucu yalnız aralıklı
/// denenir (parlak zeminde hızlı okuyucu yazıyı hiç göremeyebilir), yoksa boş her karede boşa çalışırdı.
/// Okuyucuların sahibi değildir (güçlü okuyucu okuma hatları arasında paylaşılır); onları kuran kapatır.
/// Bir örnek tek iş parçacığından çağrılır.
/// </summary>
public sealed partial class HybridReader(ITextReader fast, ITextReader strong, Func<long>? clock = null) : ITextReader
{
    /// <summary>
    /// Hızlı okuyucu boş döndüğünde güçlü okuyucu en sık bu aralıkla denenir. Güçlü okuyucu ve çeviri modeli aynı
    /// işlemci çekirdeklerini paylaşır; sık deneme çeviriyi yavaşlatıyordu.
    /// </summary>
    public const int ProbeEveryMs = 1200;
    /// <summary>
    /// Aynı hızlı okuma (ekranda duran altyazı ya da ipucu kutusu) için güçlü okuyucunun kararı bu kadar süre geçerlidir;
    /// her karede yeniden okunmaz. Ölçülen oturumda tek bir cümle 4 saniyede 20 kez yeniden okunuyordu. 4 sn denendi:
    /// yarım okunan satır (yazı belirirken) o kadar kalıyor, harf hatası artıyordu; 1,5 sn hem hızlı hem doğru çıktı.
    /// </summary>
    public const int RememberMs = 1500;

    private readonly Func<long> now = clock ?? (() => Environment.TickCount64);
    private long lastProbe = long.MinValue / 2;
    /// <summary>Son güçlü okumanın sorulduğu hızlı okuma, sonucu (null: hızlı okuma kaldı) ve zamanı.</summary>
    private (string Quick, Reading? Result, long At)? remembered;
    /// <summary>Son güçlü okumanın süresi (günlük için).</summary>
    private int lastStrongMs;
    /// <summary>Son güçlü okuma (ad satırı aranır).</summary>
    private Reading lastStrongReading = Reading.Empty;

    /// <summary>Okuma bozuk mu (yazım denetimi); verilmezse yalnız <see cref="OcrNoise.LooksGarbled"/>.</summary>
    public Func<string, bool>? LooksMisread { get; set; }
    /// <summary>Okumanın puanı (yüksek: daha çok gerçek sözcük); verilmezse <see cref="OcrNoise.Score"/>.</summary>
    public Func<string, int>? Score { get; set; }
    /// <summary>
    /// Satır onarımı (karışan harfler, boşluksuz okunmuş sözcükler: <see cref="OcrConfusions.Repair"/>). İki okuma
    /// karşılaştırılmadan önce ikisi de onarılır; onarılınca temizlenen hızlı okuma için güçlü okuyucu çalışmaz.
    /// </summary>
    public Func<string, string>? Repair { get; set; }
    /// <summary>Güçlü okuyucunun devreye girdiği her kare için bir satır (altyazı günlüğü).</summary>
    public Action<string>? Log { get; set; }

    /// <summary>Güçlü okuyucunun çalıştığı ve okuması seçilen kare sayıları (ölçüm için).</summary>
    public int StrongRuns { get; private set; }
    public int StrongWins { get; private set; }

    /// <summary>
    /// Okuma bozuk görünmese de güçlü okuyucunun da bakması gereken satır (ör. konuşmacı adı henüz doğrulanmadı).
    /// Böyle satırda hızlı okuma kalır; güçlü okuyucunun okuması yalnız <see cref="StrongRead"/>'e verilir.
    /// </summary>
    public Func<string, bool>? NeedsStrong { get; set; }
    /// <summary>Güçlü okuyucunun her okuması (konuşmacı adlarını doğrulamak için).</summary>
    public Action<Reading>? StrongRead { get; set; }

    public string Read(Frame image) => ReadLines(image, deep: true).Text;

    public string Read(Frame image, bool deep) => ReadLines(image, deep).Text;

    public Reading ReadLines(Frame image, bool deep)
    {
        var quick = fast.ReadLines(image, deep);
        var text = quick.Text.Trim();
        if (text.Length == 0)
        {
            // Hızlı okuyucu boş: çoğu zaman ekranda altyazı yoktur. Güçlü okuyucu seyrek denenir.
            if (now() - lastProbe < ProbeEveryMs) return quick;
            lastProbe = now();
            var probed = Strong(image, deep);
            // Güçlü okuyucu boş sahnede de bir şeyler "okur" (dokudan "MEEEEEI", tek harfler, başka yazı sisteminden
            // harfler); yalnız gerçekten yazıya benzeyen okuma kabul edilir.
            if (!LooksLikeText(probed.Text) || Points(probed.Text) <= 0) return quick;
            StrongWins++;
            Log?.Invoke($"güçlü okuyucu ({lastStrongMs} ms): hızlı okuyucu boş döndü → {SubtitleLog.Excerpt(probed.Text)}");
            return probed;
        }
        // Aynı yazı hâlâ ekranda: güçlü okuyucunun az önceki kararı kullanılır.
        // Hızlı okuyucu ekranda duran yazıyı kareden kareye biraz farklı okur; neredeyse aynı okuma aynı yazıdır.
        // Yazı uzuyorsa (kelime kelime beliren altyazı) eski karar kullanılmaz; yoksa sonu kaybolurdu.
        if (remembered is { } memo && now() - memo.At < RememberMs && SameText(memo.Quick, text) &&
            Letters(text) * 10 <= Letters(memo.Quick) * 11)
            return memo.Result ?? (Misread(text) ? Tidy(quick) : quick);
        if (!Misread(text))
        {
            // Oyun konuşmacı adını sözün üstünde ayrı (çoğu zaman renkli) satırda gösteriyor ve hızlı okuyucu o satırı
            // göremiyorsa (FF7: "Jessie" / "Well, I'm glad that's over with."), adsız yeni satırda ad güçlü okuyucudan alınır.
            if (nameRowsSeen >= NameRowsToTrust && !SpeakerLabel().IsMatch(text))
            {
                var named = Strong(image, deep);
                // Hızlı okuyucu ad satırını zaten okuduysa eklenmez (satır birleştirmesi onu ada çevirir).
                var withName = NameAbove(named, text) is { } row &&
                             !quick.Lines[0].Text.Contains(row.Name, StringComparison.OrdinalIgnoreCase)
                    ? WithName(quick, row.Name) : null;
                remembered = (text, withName, now());
                if (withName is not null) return withName;
            }
            else if (NeedsStrong?.Invoke(text) == true)
            {
                Strong(image, deep);
                remembered = (text, null, now());
            }
            return quick;
        }
        var asked = text;
        // Onarılabilen okuma ("Tinne is running out, ny love.") güçlü okuyucuyu beklemeden düzelir.
        quick = Tidy(quick);
        text = quick.Text.Trim();
        if (!Misread(text)) return quick;

        var result = Decide(quick, text, image, deep);
        // Ad satırını yalnız güçlü okuyucu görüyorsa (FF7) bozuk okuma yolunda da ad onun okumasından alınır.
        if (nameRowsSeen >= NameRowsToTrust && result.Text.Trim() is var chosen && !SpeakerLabel().IsMatch(chosen) &&
            NameAbove(lastStrongReading, chosen) is { } found && !result.Lines[0].Text.Contains(found.Name, StringComparison.OrdinalIgnoreCase))
            result = WithName(result, found.Name);
        remembered = (asked, ReferenceEquals(result, quick) ? null : result, now());
        return result;
    }

    /// <summary>Bozuk hızlı okuma ile güçlü okuyucunun okumasından iyisi.</summary>
    private Reading Decide(Reading quick, string text, Frame image, bool deep)
    {
        var careful = Tidy(Strong(image, deep));
        var other = careful.Text.Trim();
        var (quickPoints, carefulPoints) = (Points(text), Points(other));
        // Hızlı okuma bozuk. Güçlü okuma bozuk görünmüyorsa kazanır (yalnız harf sayan puan bozuk okumayı
        // "daha uzun" diye üstün sayabiliyor); ama satırın küçük bir parçası olmamalı. İkisi de bozuksa puan
        // belirler; eşitlikte hızlı okuma kalır, hattın geri kalanı onun satır kutularına göre ayarlandı.
        // Sözcük sayısı da yakın olmalı: güçlü okuyucu bazen satırı boşluksuz okuyor ("Kirkitrustimlikeobrother.").
        var clean = other.Length > 0 && !Misread(other) && Letters(other) * 10 >= Letters(text) * 6 && Words(other) * 10 >= Words(text) * 6;
        if (other.Length == 0 || (!clean && carefulPoints <= quickPoints))
        {
            Log?.Invoke($"güçlü okuyucu ({lastStrongMs} ms): hızlı okuma kaldı ({quickPoints} ≥ {carefulPoints}) {SubtitleLog.Excerpt(text)}");
            return quick;
        }
        StrongWins++;
        Log?.Invoke($"güçlü okuyucu ({lastStrongMs} ms): {SubtitleLog.Excerpt(text)} → {SubtitleLog.Excerpt(other)}");
        return careful;
    }

    private Reading Strong(Frame image, bool deep)
    {
        StrongRuns++;
        var started = System.Diagnostics.Stopwatch.GetTimestamp();
        try
        {
            var reading = strong.ReadLines(image, deep);
            lastStrongMs = (int)System.Diagnostics.Stopwatch.GetElapsedTime(started).TotalMilliseconds;
            lastStrongReading = reading;
            if (nameRowsSeen < NameRowsToTrust && NameRow(reading, anyRow: true) is not null) nameRowsSeen++;
            StrongRead?.Invoke(reading);
            return reading;
        }
        catch
        {
            // Güçlü okuyucu çalışamazsa (model, bellek) hızlı okuma kullanılır; okuma hattı durmaz.
            return Reading.Empty;
        }
    }

    /// <summary>
    /// Hızlı okuyucunun göremediği yerde güçlü okuyucunun bulduğu yazı gerçek mi: en az iki sözcük ve sekiz harf,
    /// harflerin hepsi Latin yazısından ve yazım denetimine göre bozuk değil.
    /// </summary>
    private bool LooksLikeText(string text)
    {
        text = text.Trim();
        var letters = text.Where(char.IsLetter).ToList();
        if (letters.Count < 8 || letters.Any(letter => letter > 'ɏ')) return false;
        var words = text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Count(word => word.Count(char.IsLetter) >= 2);
        return words >= 2 && !Misread(text);
    }

    /// <summary>
    /// Satırları onarır ve birden çok satırlı okumadan çöp satırları ("HIITIIE", "MKIceAng": zemindeki dokudan okunan
    /// harfler) çıkarır: bozuk ve hiç gerçek sözcüğü olmayan satır. Okumada en az bir satır kalır.
    /// </summary>
    private Reading Tidy(Reading reading)
    {
        if (reading.Lines.Count == 0) return reading;
        var lines = Repair is { } repair ? reading.Lines.Select(line => line with { Text = repair(line.Text) }).ToList() : [.. reading.Lines];
        if (lines.Count > 1)
        {
            var kept = lines.Where(line => !(Misread(line.Text) && Points(line.Text) <= 0)).ToList();
            if (kept.Count > 0) lines = kept;
        }
        return new Reading(lines);
    }

    /// <summary>Güçlü okuyucu sözün üstünde ayrı ad satırı bu kadar kez görünce oyunun adları böyle gösterdiği kabul edilir.</summary>
    public const int NameRowsToTrust = 2;
    private int nameRowsSeen;

    [System.Text.RegularExpressions.GeneratedRegex(@"^\p{Lu}[\p{L}.’'-]*(?: \p{Lu}[\p{L}.’'-]*){0,2}:\s")]
    private static partial System.Text.RegularExpressions.Regex SpeakerLabel();

    /// <summary>
    /// Okumanın ilk satırı tek başına bir ad mı ("Jessie", "BARRET"; okumanın artığı "/", "¯", tırnak atılır) ve altında
    /// söz var mı: (ad, söz). Değilse null.
    /// </summary>
    internal static (string Name, string Speech)? NameRow(Reading reading, bool anyRow = false) => NameAbove(reading, null, anyRow);

    /// <summary>
    /// Okumada sözün hemen üstündeki ad satırı: <paramref name="speech"/> verilirse altındaki satırlar ona benzemeli
    /// (okumada üstte başka yazılar, altta menü yazısı olabiliyor: "exploring." / "Tifa" / "We were, but…" / "Commands
    /// Menu"); verilmezse ad satırı ilk satır olmalı. Ad: tek başına bir iki sözcük ("Jessie", "BARRET"; okumanın artığı
    /// "/", "¯", tırnak atılır). Altındaki söz zaten adla başlıyorsa ad sayılmaz ("Examine" / "Geralt: …").
    /// </summary>
    internal static (string Name, string Speech)? NameAbove(Reading reading, string? speech, bool anyRow = false)
    {
        var lines = reading.Lines;
        var speechRows = speech is null ? 0 : speech.Split('\n').Length;
        for (var i = 0; i < lines.Count - 1; i++)
        {
            if (speech is null && !anyRow && i > 0) break;
            var name = lines[i].Text.Trim().Trim('/', '\\', '|', '¯', '"', '\'', '`', ':', ';', ',', '.', '-', '_', ' ');
            if (name.Length is < 2 or > 20 || !(Reading.IsTitleName(name) || Reading.IsSpeakerLine(name))) continue;
            var below = lines.Skip(i + 1).Take(speechRows > 0 ? speechRows : lines.Count).Select(line => line.Text.Trim());
            var rest = string.Join("\n", below).Trim();
            if (rest.Count(char.IsLetter) < 3 || SpeakerLabel().IsMatch(rest)) continue;
            if (speech is not null && !SameText(rest, speech)) continue;
            return (name, rest);
        }
        return null;
    }

    /// <summary>Hızlı okumanın ilk satırının başına ad eklenir ("Jessie: Well, …"); satır kutuları aynen kalır.</summary>
    private static Reading WithName(Reading quick, string name)
    {
        var lines = quick.Lines.ToList();
        lines[0] = lines[0] with { Text = $"{name}: {lines[0].Text.Trim()}" };
        return new Reading(lines);
    }

    /// <summary>İki okuma aynı yazının okuması mı (birebir ya da harflerinin çoğu aynı).</summary>
    private static bool SameText(string a, string b)
    {
        if (a == b) return true;
        var (left, right) = (TextMatch.Normalize(a), TextMatch.Normalize(b));
        return left.Length >= 6 && right.Length >= 6 && TextMatch.IsSimilar(left, right, 0.75);
    }

    private bool Misread(string text) => OcrNoise.LooksGarbled(text) || (LooksMisread?.Invoke(text) ?? false);

    private int Points(string text) => (Score ?? OcrNoise.Score)(text);

    private static int Letters(string text) => text.Count(char.IsLetter);

    private static int Words(string text) => text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Count(word => word.Any(char.IsLetter));
}
