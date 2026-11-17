// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Altyazıyı ekranın tamamından, kullanıcı alan seçmeden bulur. Yazının yerine değil davranışına bakar: altyazı
/// ortalıdır, cümle gibidir, birkaç saniyede bir değişir ve hep aynı şeritte çıkar; arayüz yazısı (görev hedefi,
/// gösterge) uzun süre aynı yerde aynı kalır, menü kısa ve noktalamasız satırlardır, kumanda ipucu düğme adı taşır.
/// Şerit, son bir buçuk dakikada görülen açıkça konuşma olan satırların en çok toplandığı yerdir. Konuşmacısı belli
/// satırlar ("Ad: söz" ya da üstünde büyük harfli ad satırı) üç kat sayılır: diyalogda konuşmacı olur, yükleme
/// ekranındaki ipuçlarında ve eğitim yazılarında olmaz. Şerit, başka bir yer belirgin biçimde ağır basınca değişir;
/// konuşmacılı satırlarla kurulmuş şeridi yalnız konuşmacılı satırlar yerinden eder (ipuçları eder).
/// Kutular karenin tamamına oranladır (0–1). Durum tutar; tek iş parçacığından çağrılır.
/// </summary>
public sealed class SubtitleFinder
{
    public enum Verdict { Subtitle, Prompt, Menu, Static, OffCenter, NotSentence, OutsideBand }

    public sealed record Finding(TextLine Line, Verdict Verdict);

    /// <summary>Öğrenilen altyazı şeridi (karenin yüksekliğine oranla); henüz öğrenilmediyse null.</summary>
    public (double Top, double Bottom)? Band { get; private set; }

    /// <summary>Şeridin kurulması için gereken kanıt ağırlığı (düz satır 1, konuşmacılı satır <see cref="SpeakerWeight"/>).</summary>
    public const int WeightToLearn = 4;
    /// <summary>Konuşmacısı belli satırın ağırlığı.</summary>
    public const int SpeakerWeight = 3;
    /// <summary>Başka bir yerin şeridi yerinden etmesi için şeritteki kanıttan bu kadar ağır basması gerekir.</summary>
    public const int WeightToMove = 3;
    /// <summary>Kanıt bu kadar süre geçerlidir.</summary>
    public const int EvidenceMs = 90000;
    /// <summary>Aynı yerde aynı yazı bu kadar süre kalırsa arayüzdür.</summary>
    public const int StaticAfterMs = 9000;
    /// <summary>Satırın ortası ekranın ortasından en çok bu kadar uzak olabilir.</summary>
    public const double CenterTolerance = 0.12;
    /// <summary>
    /// Okunan geniş alandan altyazı seçilirken satırın ortası ekranın ortasından en çok bu kadar uzak olabilir (sola yaslı
    /// uzun altyazı satırı ve iki konuşmacının yan yana satırları için <see cref="CenterTolerance"/>'tan geniş).
    /// </summary>
    public const double CoreCenterTolerance = 0.22;
    /// <summary>Ortaları birbirine bu kadar yakın satırlar aynı yerdedir (iki satırlı altyazının iki satırı).</summary>
    private const double SamePlace = 0.05;

    private sealed record Seen(long First, long Last);
    private sealed record Evidence(double Middle, double Height, string Text, long At, int Weight);

    private readonly Dictionary<string, Seen> seen = [];
    private readonly List<Evidence> evidence = [];
    /// <summary>Şerit konuşmacılı satırlarla mı kuruldu (öyleyse yalnız konuşmacılı satırlar yerinden eder).</summary>
    private bool bandHasSpeakers;

    /// <summary>Karenin tamamının okumasını sınıflar. <paramref name="now"/> milisaniyedir (tekdüze artan saat).</summary>
    public IReadOnlyList<Finding> Classify(Reading reading, long now)
    {
        Forget(now);
        var menu = MenuLines(reading);
        var findings = new List<Finding>();
        foreach (var line in reading.Lines)
        {
            if (line.Box is not { } box || line.Text.Trim().Length == 0) continue;
            var key = Key(line.Text, box);
            var first = seen.TryGetValue(key, out var earlier) ? earlier.First : now;
            seen[key] = new Seen(first, now);

            Verdict verdict;
            if (ButtonPrompts.IsPrompt(line.Text)) verdict = Verdict.Prompt;
            else if (menu.Contains(line)) verdict = Verdict.Menu;
            else if (now - first >= StaticAfterMs) verdict = Verdict.Static;
            else if (Math.Abs(((box.Left + box.Right) / 2) - 0.5) > CenterTolerance) verdict = Verdict.OffCenter;
            else if (!LooksSpoken(line.Text)) verdict = Verdict.NotSentence;
            else verdict = InBand(box) ? Verdict.Subtitle : Verdict.OutsideBand;

            // Şeridi yalnız açıkça konuşma olan satırlar belirler; "Spider Barrage" gibi kısa yazılar belirlemez.
            if (verdict is Verdict.Subtitle or Verdict.OutsideBand)
            {
                var speaker = HasSpeaker(line, reading);
                if (speaker || IsClearlySpoken(line.Text)) Note(line.Text, box, now, speaker ? SpeakerWeight : 1);
            }
            findings.Add(new Finding(line, verdict));
        }
        if (Relearn(now))
        {
            // Şerit değişti: bu karedeki satırlar yeni şeride göre yeniden değerlendirilir.
            for (var i = 0; i < findings.Count; i++)
                if (findings[i].Verdict is Verdict.Subtitle or Verdict.OutsideBand && findings[i].Line.Box is { } box)
                    findings[i] = findings[i] with { Verdict = InBand(box) ? Verdict.Subtitle : Verdict.OutsideBand };
        }
        return findings;
    }

    /// <summary>Altyazı sayılan satırlar, yukarıdan aşağı.</summary>
    /// <summary>
    /// Geniş bir alanın okumasından altyazı bloğunu seçer: şeridin içindeki satırlar çekirdektir; onlara dikeyde bitişik
    /// ve yatayda hizalı satırlar da (altyazının üçüncü, dördüncü satırı, üstteki konuşmacı adı) bloğa katılır. Böylece
    /// altyazı uzayınca alt satırı kesilmez, şeritten uzaktaki yazılar (ipucu, gösterge) ise dışarıda kalır.
    /// Şeritte hiç satır yoksa okuma boştur. <paramref name="area"/> okunan alanın karedeki yeridir; satır kutuları
    /// alana göredir ve öyle döner.
    /// </summary>
    public static Reading Grow(Reading reading, TextBox area, (double Top, double Bottom) band)
    {
        var lines = reading.Lines.Where(line => line.Box is not null).ToList();
        if (lines.Count == 0) return reading;
        TextBox Place(TextLine line) => line.Box!.Value.PlacedIn(area);
        // Çekirdek satır şeritte ve ekranın ortasına yakın olmalı: şeritle aynı yükseklikteki köşe yazıları (sağ alttaki tuş
        // ipuçları "Call Horse Press Twice", "Witcher Senses Hold") altyazı değildir.
        var kept = lines.Where(line =>
        {
            var box = Place(line);
            var middle = (box.Top + box.Bottom) / 2;
            return middle >= band.Top && middle <= band.Bottom && Math.Abs(((box.Left + box.Right) / 2) - 0.5) <= CoreCenterTolerance;
        }).ToList();
        var grew = kept.Count > 0;
        while (grew)
        {
            grew = false;
            foreach (var line in lines)
            {
                if (kept.Contains(line)) continue;
                var box = Place(line);
                if (!kept.Any(other => Adjoins(box, Place(other)))) continue;
                kept.Add(line);
                grew = true;
            }
        }
        return new Reading(reading.Lines.Where(kept.Contains));
    }

    /// <summary>İki satır alt alta mı: aralarındaki boşluk bir satır yüksekliğinden az ve yatayda hizalı (ortaları yakın ya da üst üste biniyor).</summary>
    private static bool Adjoins(TextBox a, TextBox b)
    {
        var height = Math.Max(a.Bottom - a.Top, b.Bottom - b.Top);
        var gap = Math.Max(a.Top, b.Top) - Math.Min(a.Bottom, b.Bottom);
        if (gap > height * 0.9) return false;
        var overlap = Math.Min(a.Right, b.Right) - Math.Max(a.Left, b.Left);
        var narrower = Math.Min(a.Right - a.Left, b.Right - b.Left);
        return Math.Abs(((a.Left + a.Right) / 2) - ((b.Left + b.Right) / 2)) <= CenterTolerance || (overlap > 0 && overlap >= narrower * 0.5);
    }

    public Reading Subtitles(Reading reading, long now) =>
        new(Classify(reading, now).Where(f => f.Verdict == Verdict.Subtitle).Select(f => f.Line));

    private bool InBand(TextBox box)
    {
        if (Band is not { } band) return true;
        var middle = (box.Top + box.Bottom) / 2;
        return middle >= band.Top && middle <= band.Bottom;
    }

    /// <summary>
    /// Satırın konuşmacısı belli mi: "Ad: söz" biçiminde başlar ya da hemen üstünde, ortalı, büyük harfli kısa bir ad
    /// satırı vardır ("MARKOS" / "We have no option but to try!").
    /// </summary>
    private static bool HasSpeaker(TextLine line, Reading reading)
    {
        var text = line.Text.TrimStart();
        var colon = text.IndexOf(": ", StringComparison.Ordinal);
        if (colon is >= 2 and <= 30 && char.IsUpper(text[0]) && text[..colon].Split(' ').Length <= 3 &&
            text[..colon].All(c => char.IsLetter(c) || c is ' ' or '-' or '.' or '\'' or '’'))
            return true;
        if (line.Box is not { } box) return false;
        var height = box.Bottom - box.Top;
        return reading.Lines.Any(other => other.Box is { } above && Reading.IsSpeakerLine(other.Text) &&
            above.Bottom <= box.Top + (height * 0.5) && box.Top - above.Bottom <= height * 1.5 &&
            Math.Abs(((above.Left + above.Right) / 2) - ((box.Left + box.Right) / 2)) <= CenterTolerance);
    }

    private void Note(string text, TextBox box, long now, int weight)
    {
        var normal = TextMatch.Normalize(text);
        var known = evidence.FindIndex(item => item.Text == normal);
        // Aynı satır yeniden görülünce tarihi yenilenir; ağırlığı artmaz (ekranda duran yazı şeridi çekmesin).
        if (known >= 0) evidence[known] = evidence[known] with { At = now, Weight = Math.Max(evidence[known].Weight, weight) };
        else evidence.Add(new Evidence((box.Top + box.Bottom) / 2, box.Bottom - box.Top, normal, now, weight));
        if (evidence.Count > 40) evidence.RemoveAt(0);
    }

    /// <summary>Kanıtın en çok toplandığı yeri bulur; şerit yoksa kurar, başka yer ağır basıyorsa oraya taşır. Değiştiyse true.</summary>
    private bool Relearn(long now)
    {
        evidence.RemoveAll(item => now - item.At > EvidenceMs);
        if (evidence.Count == 0) return false;
        List<Evidence> Around(double middle) => evidence.Where(item => Math.Abs(item.Middle - middle) <= SamePlace).ToList();
        var best = evidence.Select(item => Around(item.Middle))
            .OrderByDescending(cluster => cluster.Sum(item => item.Weight)).ThenByDescending(cluster => cluster.Max(item => item.At)).First();
        var weight = best.Sum(item => item.Weight);
        var speakers = best.Any(item => item.Weight >= SpeakerWeight);
        var candidate = BandOf(best.Select(item => (item.Middle, item.Height)).ToList());

        if (Band is not { } band)
        {
            if (weight < WeightToLearn) return false;
            (Band, bandHasSpeakers) = (candidate, speakers);
            return true;
        }
        var inBand = evidence.Where(item => item.Middle >= band.Top && item.Middle <= band.Bottom).ToList();
        var center = Median(best.Select(item => item.Middle));
        if (center >= band.Top && center <= band.Bottom)
        {
            // Aynı yer: şerit ince ayarlanır.
            bandHasSpeakers |= speakers;
            if (Math.Abs(candidate.Top - band.Top) < 0.005 && Math.Abs(candidate.Bottom - band.Bottom) < 0.005) return false;
            Band = candidate;
            return true;
        }
        // Başka yer: belirgin biçimde ağır basmalı; konuşmacılı şeridi konuşmacısız yazılar (ipuçları) yerinden etmez.
        var stillSpeakers = bandHasSpeakers && inBand.Any(item => item.Weight >= SpeakerWeight);
        // Konuşmacılı satırlar konuşmacısız bir şeridi (ipuçlarından öğrenilmiş) eşit ağırlıkta bile yerinden eder.
        var margin = speakers && !stillSpeakers ? 0 : WeightToMove;
        if (weight < inBand.Sum(item => item.Weight) + margin || (stillSpeakers && !speakers) || weight < WeightToLearn) return false;
        (Band, bandHasSpeakers) = (candidate, speakers);
        return true;
    }

    /// <summary>
    /// Satır ortalarının ortancası çevresinde şerit: iki satırlı altyazı ve küçük kaymalar için yukarı ve aşağı
    /// iki buçuk satır yüksekliği pay bırakılır. Aykırı tek satır (ortancadan uzak) şeridi genişletmez.
    /// </summary>
    private static (double Top, double Bottom) BandOf(List<(double Middle, double Height)> lines)
    {
        var middle = Median(lines.Select(line => line.Middle));
        var height = Math.Max(0.015, Median(lines.Select(line => line.Height)));
        return (Math.Max(0, middle - (height * 2.5)), Math.Min(1, middle + (height * 2.5)));
    }

    private static double Median(IEnumerable<double> values)
    {
        var sorted = values.Order().ToList();
        return sorted.Count % 2 == 1 ? sorted[sorted.Count / 2] : (sorted[(sorted.Count / 2) - 1] + sorted[sorted.Count / 2]) / 2;
    }

    /// <summary>
    /// Konuşma satırı gibi mi: en az iki sözcük ya da noktalamayla biten tek sözcük ("Run!"), harflerinin çoğu küçük
    /// harf ya da cümle sonu işaretiyle biter (tümü büyük harfli kısa yazılar çoğunlukla başlık ve göstergedir).
    /// </summary>
    internal static bool LooksSpoken(string text)
    {
        var words = text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Where(word => word.Any(char.IsLetter)).ToList();
        if (words.Count == 0) return false;
        var ends = SubtitleStabilizer.EndsSentence(text);
        if (words.Count <= 2 && !ends) return false;
        var letters = text.Where(char.IsLetter).ToList();
        if (letters.Count < 3) return false;
        var lower = letters.Count(char.IsLower);
        return lower * 2 >= letters.Count || (ends && words.Count >= 2);
    }

    /// <summary>
    /// Şeridi öğretecek kadar açık konuşma: en az üç sözcük ve ya cümle sonu işaretiyle biter ya da "Ad:" ile başlar.
    /// Dövüş sırasında ekranın ortasında çıkan beceri adları ve ipuçları şeridi yanlış yere çekiyordu.
    /// </summary>
    internal static bool IsClearlySpoken(string text)
    {
        var words = text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Count(word => word.Any(char.IsLetter));
        if (words < 3 || !LooksSpoken(text)) return false;
        var colon = text.IndexOf(':');
        var labelled = colon is > 1 and <= 30 && char.IsUpper(text[0]) && colon < text.Length - 2;
        return labelled || SubtitleStabilizer.EndsSentence(text);
    }

    /// <summary>Alt alta dizilmiş, sola hizalı ya da aynı ortalı, kısa ve noktalamasız üç ve daha çok satır menüdür.</summary>
    private static HashSet<TextLine> MenuLines(Reading reading)
    {
        var result = new HashSet<TextLine>();
        var shorts = reading.Lines
            .Where(line => line.Box is not null && WordCount(line.Text) <= 3 && !SubtitleStabilizer.EndsSentence(line.Text))
            .OrderBy(line => line.Box!.Value.Top).ToList();
        foreach (var line in shorts)
        {
            var box = line.Box!.Value;
            var column = shorts.Where(other =>
            {
                var o = other.Box!.Value;
                return Math.Abs(o.Left - box.Left) <= 0.02 || Math.Abs(((o.Left + o.Right) / 2) - ((box.Left + box.Right) / 2)) <= 0.02;
            }).ToList();
            if (column.Count >= 3) foreach (var member in column) result.Add(member);
        }
        return result;
    }

    private static int WordCount(string text) => text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;

    /// <summary>Aynı yerdeki aynı yazı: yer yüzde ikilik ızgaraya yuvarlanır (yazı tanıma kutuları kare kare oynar).</summary>
    private static string Key(string text, TextBox box) =>
        $"{Math.Round((box.Left + box.Right) / 2 / 0.02)}:{Math.Round((box.Top + box.Bottom) / 2 / 0.02)}:{TextMatch.Normalize(text)}";

    /// <summary>Bir süredir görülmeyen yazılar unutulur (aynı altyazı sonra yeniden gelirse sabit sayılmasın).</summary>
    private void Forget(long now)
    {
        foreach (var key in seen.Where(pair => now - pair.Value.Last > 4000).Select(pair => pair.Key).ToList())
            seen.Remove(key);
    }
}
