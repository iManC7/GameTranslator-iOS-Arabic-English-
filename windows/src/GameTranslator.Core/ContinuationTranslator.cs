// SPDX-License-Identifier: AGPL-3.0-only

using System.Text.RegularExpressions;
using GameTranslator.Core.Dubbing;

namespace GameTranslator.Core;

/// <summary>
/// Oyunlar uzun cümleyi art arda gelen birkaç altyazıya böler ("You're the ones" → "who are gonna need help..." →
/// "when they come for you."). Parçalar tek tek çevrilince anlam dağılır ("Sizlersiniz" / "Kimin yardıma ihtiyacı
/// olacak..."). Bu sarmalayıcı, cümlesi bitmemiş satırın ardından aynı konuşmacıdan gelen devamı önceki parçayla
/// birlikte çevirir ve cümlenin o ana kadarki tamamının çevirisini verir.
/// Ayrıca aynı okumada iki kez gelen satırı ("A fate you will not share." alt alta iki kez) teke indirir.
/// Kendi durumunu tutar; başka bir çevirmeni sarar.
/// </summary>
public sealed partial class ContinuationTranslator(ITextTranslator inner, Func<long>? clock = null, Func<string, bool>? looksMisread = null) : ITextTranslator
{
    /// <summary>Önceki parçadan en çok bu kadar sonra gelen satır onun devamı sayılabilir.</summary>
    public const int WithinMs = 8000;
    /// <summary>Birleşen cümle bundan uzunsa yeni satır tek başına çevrilir (zincir sonsuza uzamasın).</summary>
    public const int MaxLength = 260;

    private readonly Func<long> now = clock ?? (() => Environment.TickCount64);
    private readonly object gate = new();
    private (string? Speaker, string Body, string Raw, long At)? previous;
    private readonly SpeakerNames names = new();
    /// <summary>Konuşmacı adları (okuma hattıyla paylaşılır: güçlü okuyucunun okuduğu adlar doğrulanmış sayılır).</summary>
    public SpeakerNames Names { init => names = value; }

    /// <summary>
    /// Kısa ünlemlerin hazır karşılığı (<see cref="ShortPhrases.Translate"/>; İngilizce→Türkçe). Verilirse ve sözün
    /// karşılığı varsa söz çevirmene gönderilmez.
    /// </summary>
    public Func<string, string?>? Phrasebook { get; init; }

    public bool Prefetches => inner.Prefetches;
    public void Prefetch(string text) => inner.Prefetch(text);
    public IReadOnlyList<SpokenLine> SpokenLines(string text) => inner.SpokenLines(text);

    public async Task<string> TranslateAsync(string text, CancellationToken cancellationToken = default)
    {
        var source = Relabel(WithoutBareLabels(WithIconLabels(WithoutRepeatedLines(text))));
        // Birkaç kişi konuşuyorsa her konuşma kendi adıyla ayrı çevrilir (aynı anda); adlar çevrilmez.
        if (Turns(source) is { Count: > 1 } all)
        {
            // Sözü olmayan konuşma (bir sonraki konuşmanın önce beliren adı: "… / Mimir:") gösterilmez.
            var turns = all.Where(turn => turn.Body.Any(char.IsLetter)).ToList();
            if (turns.Count == 0) turns = all;
            lock (gate) previous = null;
            var parts = await Task.WhenAll(turns.Select(turn => TranslateTurn(turn.Speaker, turn.Body, cancellationToken))).ConfigureAwait(false);
            return string.Join('\n', parts);
        }
        string? speaker;
        string body;
        lock (gate) (speaker, body) = Combine(source);
        return await TranslateTurn(speaker, body, cancellationToken).ConfigureAwait(false);
    }

    /// <summary>
    /// İki nokta üst üstesi okunmamış konuşmacı adını ("Stintsy Fuck, he's here.") oyunda daha önce görülen adla
    /// "Stints: Fuck, he's here." biçimine getirir; adın çevrilmesi ve söze karışması önlenir.
    /// </summary>
    private string Relabel(string source)
    {
        var rows = source.Split('\n');
        var changed = false;
        lock (gate)
        {
            for (var i = 0; i < rows.Length; i++)
            {
                var row = rows[i].Trim();
                if (row.Length == 0 || SpeakerLabel().IsMatch(row)) continue;
                var words = row.Split(' ', 4, StringSplitOptions.RemoveEmptyEntries);
                // İki sözcüklü ad: "Charles Rookwoods Jelve done…" (ikinci sözcüğe ":" harf olarak yapışmış).
                if (words.Length >= 3 && names.LabelIn(words[0] + " " + words[1], words[2]) is { } longName)
                {
                    rows[i] = $"{longName}: {string.Join(' ', words.Skip(2))}";
                    changed = true;
                    continue;
                }
                if (words.Length < 2 || names.LabelIn(words[0], words[1]) is not { } name) continue;
                rows[i] = $"{name}: {row[(row.IndexOf(' ') + 1)..].TrimStart()}";
                changed = true;
            }
        }
        return changed ? string.Join('\n', rows) : source;
    }

    /// <summary>
    /// Sözü çevirir, konuşmacı adını olduğu gibi başına koyar. Ad çevirmene verilmez: çevirmen onu sıradan sözcük sanıp
    /// çeviriyor ("ANNA:" → "ANNE:", "MILLER:" → "DEĞİRMENCİ:") ve aynı ad bir öyle bir böyle çıkıyordu.
    /// </summary>
    private async Task<string> TranslateTurn(string? speaker, string body, CancellationToken cancellationToken)
    {
        // Gerçek adın önüne çöp bir "ad" eklenmiş ("QHI: Mimir: Uzun zaman oldu..."): söz bilinen bir adla başlıyorsa
        // ve öndeki ad bilinmiyorsa konuşmacı içteki addır.
        if (speaker is not null && SpeakerLabel().Match(body) is { Success: true } innerLabel &&
            names.IsKnown(innerLabel.Groups["name"].Value) && !names.IsKnown(speaker))
        {
            speaker = innerLabel.Groups["name"].Value;
            body = body[innerLabel.Length..].Trim();
        }
        // Bozuk okunmuş ad ("Minnir") oyunda sık geçen doğrusuna ("Mimir") çevrilir.
        if (speaker is not null) lock (gate) speaker = CapsName(names.Canonical(speaker));
        if (body.Length == 0) return speaker is null ? "" : speaker + ":";
        string translated;
        if (Phrasebook?.Invoke(body) is { } ready) translated = ready;
        else if (Phrasebook is not null && ShortPhrases.SplitRadioTail(body) is { } radio)
            translated = ShortPhrases.FixShouting(radio.Main, (await inner.TranslateAsync(radio.Main, cancellationToken).ConfigureAwait(false)).Trim()) + " " + radio.Tail;
        else translated = ShortPhrases.FixShouting(body, (await inner.TranslateAsync(body, cancellationToken).ConfigureAwait(false)).Trim());
        return speaker is null ? translated : $"{speaker}: {translated}";
    }

    /// <summary>
    /// Büyük harfle yazılan adda yazı tanımanın küçük okuduğu "i" ("DAMiR", "SOLDiER") büyütülür. Harflerin hepsi
    /// "i" dışında büyükse ad büyük harfli sayılır.
    /// </summary>
    internal static string CapsName(string name) => SpeakerNames.FixCaps(name);

    /// <summary>
    /// Okumayı konuşmalara böler: konuşmacı adıyla başlayan her satır yeni bir konuşmadır, adsız satırlar bir öncekinin
    /// devamıdır (ekranda sarılmış). İkiden az konuşmacı varsa null.
    /// </summary>
    private static List<(string? Speaker, string Body)>? Turns(string source)
    {
        var rows = source.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        // İki adlı satır ya da adsız bir satırın (önceki konuşmanın ekranda kalan sonu) ardından gelen adlı satır.
        var labelled = rows.Count(row => SpeakerLabel().IsMatch(row));
        var tailThenSpeaker = rows.Length > 1 && !SpeakerLabel().IsMatch(rows[0]) && labelled >= 1;
        if (labelled < 2 && !tailThenSpeaker) return null;
        var turns = new List<(string? Speaker, string Body)>();
        foreach (var row in rows)
        {
            var (speaker, body) = Split(row);
            if (speaker is null && turns.Count > 0) turns[^1] = (turns[^1].Speaker, (turns[^1].Body + " " + body).Trim());
            else turns.Add((speaker, body));
        }
        return turns;
    }

    /// <summary>Satır önceki parçanın devamıysa ikisi birlikte, değilse kendisi. Durumu günceller.</summary>
    private (string? Speaker, string Body) Combine(string source)
    {
        var (speaker, body) = Split(source);
        var at = now();
        // Konuşmacı adı bozuk okunmuşsa ("anke: …", önceki satır "Ganke: …") ad sözün parçası sayılmasın.
        if (speaker is null && previous is { Speaker: { } known } && at - previous.Value.At <= WithinMs)
        {
            var colon = body.IndexOf(": ", StringComparison.Ordinal);
            if (colon is >= 2 and <= 24 && !body[..colon].Contains(' ') == !known.Contains(' ') && SameName(body[..colon], known))
            {
                speaker = known;
                body = body[(colon + 2)..].Trim();
                source = $"{known}: {body}";
            }
        }
        // Ekranda iki üç satıra sarılmış söz tek cümledir; satır başında konuşmacı tiresi varsa ayrı konuşmalardır.
        if (body.Contains('\n'))
        {
            var rows = body.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            if (!rows.Skip(1).Any(row => row.StartsWith('-') || row.StartsWith('–') || row.StartsWith('—') || row.StartsWith(">>", StringComparison.Ordinal)))
            {
                body = string.Join(' ', rows);
                source = speaker is null ? body : $"{speaker}: {body}";
            }
        }
        var whole = body;
        if (previous is { } last && at - last.At <= WithinMs && !body.Contains('\n') && !last.Body.Contains('\n') &&
            (speaker is null || speaker == last.Speaker) && Continues(last.Body, body) &&
            !SameLine(last.Raw, source) && last.Body.Length + body.Length + 1 <= MaxLength)
        {
            whole = last.Body + " " + body;
            speaker ??= last.Speaker;
        }
        // Aynı satırın yeniden okunması zinciri ilerletmez (yoksa satır kendisiyle birleşirdi).
        if (previous is not { } kept || !SameLine(kept.Raw, source))
            previous = (speaker, whole, source, at);
        return (speaker, whole);
    }

    /// <summary>Önceki parça cümleyi bitirmediyse ya da yeni parça küçük harfle başlıyorsa devamdır.</summary>
    private bool Continues(string before, string after)
    {
        var first = after.FirstOrDefault(char.IsLetter);
        if (first == default) return false;
        // Gösterge ve sayaç yazıları ("19m", "x3") söz değildir; birbirine eklenmez.
        if (!IsSpeech(before) || !IsSpeech(after)) return false;
        // Bozuk okunmuş parçalar birbirine eklenmez (anlamsız parçalar zincir olup uzuyordu).
        if (looksMisread is not null && (looksMisread(before) || looksMisread(after))) return false;
        // Sondaki tırnak ve yazı tanıma artıkları ("wait--'") sayılmaz.
        var trimmed = before.TrimEnd().TrimEnd('\'', '"', '’', '”', '`', ' ');
        // Baştaki tek harf ("r and Hit Indicators…": "Air"in kesik okuması) yarım okunmuş başka bir yazıdır, devam değil.
        var head = after.TrimStart().Split(' ', 2)[0].Trim('.', ',', '\'', '"');
        if (char.IsLower(first) && head.Length == 1 && head is not ("a" or "i")) return false;
        // Küçük harfle başlayan satır her zaman bir öncekinin devamıdır ("...need help..." → "when they come for you.").
        if (char.IsLower(first)) return trimmed.Length > 0 && !".!?".Contains(trimmed[^1]) || trimmed.EndsWith("...", StringComparison.Ordinal) || trimmed.EndsWith('…');
        // Büyük harfle başlayan satır yalnız önceki söz açıkça yarıda kaldıysa devamdır: virgülle ya da bağlayıcı bir
        // sözcükle bitiyorsa ("…in your old age," → "Sergei."; "…in the caves beneath" → "Kephallonia when…").
        // Üç noktayla biten sözden sonra gelen büyük harfli satır yeni bir cümledir ("At least it held..." → "Well, …"),
        // noktalamasız biten sıradan satırdan sonra gelen de ("Got another" yarım okumadır, "LEVEL 2" başka bir yazıdır).
        if (trimmed.EndsWith(',') || trimmed.EndsWith(';')) return true;
        var lastWord = trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries).LastOrDefault()?.ToLowerInvariant();
        return lastWord is not null && Connectors.Contains(lastWord);
    }

    /// <summary>Cümlenin ortasında kalındığını gösteren son sözcükler (edat, bağlaç, tanımlık).</summary>
    private static readonly HashSet<string> Connectors =
    [
        "a", "an", "the", "of", "to", "in", "on", "at", "by", "for", "from", "with", "without", "into", "onto", "over", "under",
        "beneath", "between", "through", "about", "against", "and", "or", "but", "that", "which", "who", "whose", "than", "as",
        "if", "because", "when", "while", "my", "your", "his", "her", "our", "their", "its", "this", "these", "those",
    ];

    /// <summary>En az iki harfli bir sözcüğü olan ve rakamla başlamayan yazı.</summary>
    private static bool IsSpeech(string text)
    {
        var trimmed = text.TrimStart();
        return trimmed.Length > 0 && !char.IsDigit(trimmed[0]) && text.Count(char.IsLetter) >= 3;
    }

    /// <summary>Okunan ad, bilinen adın birkaç harfi eksik ya da yanlış hâli mi ("anke", "Gankc" → "Ganke").</summary>
    private static bool SameName(string read, string known)
    {
        var (a, b) = (read.Trim('-', '—', '_', ' ', '.', '•').ToLowerInvariant(), known.ToLowerInvariant());
        if (a.Length < 3 || b.Length < 4) return false;
        return b.EndsWith(a, StringComparison.Ordinal) || TextMatch.IsSimilar(a, b, 0.75);
    }

    private static bool SameLine(string a, string b)
    {
        var (left, right) = (TextMatch.Normalize(a), TextMatch.Normalize(b));
        return left == right || TextMatch.IsSimilar(left, right, 0.8) || (left.Length >= 8 && right.Length >= 8 && (left.Contains(right) || right.Contains(left)));
    }

    /// <summary>"Flint Marko: who are gonna need help..." → ("Flint Marko", "who are gonna need help...").</summary>
    private static (string? Speaker, string Body) Split(string text)
    {
        var match = SpeakerLabel().Match(text);
        if (!match.Success) return (null, text.Trim());
        var name = match.Groups["name"].Value;
        var body = text[match.Length..].Trim();
        // Satır değişirken ad iki kez okunabiliyor ("Faye: Faye: This way.", "Kratos: Kratos. The tracks stop here.").
        while (true)
        {
            var rest = body.TrimStart('"', '“', '\'', '•', '-', '—', '(', ' ');
            // Virgül sayılmaz: "Sam: Sam, wait!" seslenmedir.
            if (rest.StartsWith(name, StringComparison.Ordinal) && rest.Length >= name.Length + 2 && ":.;•".Contains(rest[name.Length]))
            {
                body = rest[(name.Length + 1)..].Trim();
                continue;
            }
            // İki sözcüklü ad noktalamasız yinelenmiş: "Woman's Voice: Woman's Voice The Zero Dawn system".
            if (name.Contains(' ') && rest.StartsWith(name + " ", StringComparison.Ordinal) && rest.Length > name.Length + 2 && char.IsUpper(rest[name.Length + 1]))
            {
                body = rest[(name.Length + 1)..].Trim();
                continue;
            }
            // Adın bozuk ikinci okuması ("Lae'zel: Lae'ze: It cannot be helped.").
            var colon = rest.IndexOf(": ", StringComparison.Ordinal);
            if (colon < 3 || colon > name.Length + 2 || rest[..colon].Contains(' ') != name.Contains(' ') || !SameName(rest[..colon], name)) break;
            body = rest[(colon + 2)..].Trim();
        }
        // Addan sonra tek başına okunan harf, konuşmacı simgesinin artığıdır ("Faye: S This way.", "Faye: Faye:S This
        // way."). "I" ve "A" sözdür.
        if (body.Length > 3 && char.IsUpper(body[0]) && body[0] is not ('I' or 'A') && body[1] == ' ' && char.IsUpper(body[2]))
            body = body[2..];
        return (name, body);
    }

    [GeneratedRegex(@"^(?<name>\p{Lu}[\p{L}.’'-]*(?: \p{Lu}[\p{L}.’'-]*){0,2}):\s")]
    private static partial Regex SpeakerLabel();

    [GeneratedRegex(@"^\p{Lu}[\p{L}.’'-]*(?: \p{Lu}[\p{L}.’'-]*){0,2}:$")]
    private static partial Regex BareLabel();

    /// <summary>Sözü olmayan ad satırı ("… / Mimir:": bir sonraki konuşmanın önce beliren adı) başka satır varsa atılır.</summary>
    // Ayraç simge, yıldız, tire ya da bunların noktayla karışığıdır ("·-", ".-", "*-", "-"); tek başına nokta ayraç değildir.
    // Addan önce tek bir artık harf olabilir ("Z YERMAK•. come here": simgenin kenarı harf okunmuş).
    [GeneratedRegex(@"^(?:[\p{Lu}\d] )?(?<name>\p{Lu}[\p{Lu}'’-]{2,14}(?: \p{Lu}[\p{Lu}'’-]{1,14})?)\s*(?=[•·▸►>▶‣◆■*\-–—.]*[•·▸►>▶‣◆■*\-–—])[•·▸►>▶‣◆■*\-–—.]+\s*(?<body>\S.*)$")]
    private static partial Regex IconLabel();

    /// <summary>
    /// Bazı oyunlar adı iki nokta yerine simgeyle ayırır ("CAL • Think BD wants…", "BODE ·- Now I'm…"). Büyük harfli ad
    /// ve ardından gelen simge "Ad: söz" biçimine çevrilir; yoksa ad sözün parçası sanılıp çevriliyordu.
    /// </summary>
    private static string WithIconLabels(string text)
    {
        var rows = text.Split('\n');
        var changed = false;
        for (var i = 0; i < rows.Length; i++)
        {
            var match = IconLabel().Match(rows[i].Trim());
            if (!match.Success) continue;
            rows[i] = $"{match.Groups["name"].Value}: {match.Groups["body"].Value.Trim()}";
            changed = true;
        }
        return changed ? string.Join('\n', rows) : text;
    }

    private static string WithoutBareLabels(string text)
    {
        var rows = text.Split('\n').Select(row => row.Trim()).Where(row => row.Length > 0).ToList();
        var kept = rows.Where(row => !BareLabel().IsMatch(row)).ToList();
        return kept.Count == rows.Count || kept.Count == 0 ? text : string.Join('\n', kept);
    }

    private static bool IsTailCopy(string line, string earlier)
    {
        var a = TextMatch.Normalize(line).Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var b = TextMatch.Normalize(earlier).Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return a.Length >= 3 && a.Length <= b.Length && a[^1] == b[^1] && a[^2] == b[^2];
    }

    /// <summary>Alt alta gelen neredeyse aynı satırlardan (aynı altyazının iki okuması) daha düzgün okunan kalır.</summary>
    public static string WithoutRepeatedLines(string text)
    {
        var lines = text.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (lines.Length < 2) return text.Trim();
        var kept = new List<string>();
        foreach (var line in lines)
        {
            // Tekrar hemen alttaki satır olmayabilir ("A / B / A'nın ikinci okuması"). Önceki satırın sonunun bozuk bir
            // kopyası da tekrardır: son iki sözcüğü aynıdır ve daha uzun değildir.
            var twin = kept.FindIndex(earlier => TextMatch.IsSimilar(TextMatch.Normalize(earlier), TextMatch.Normalize(line), 0.8) || IsTailCopy(line, earlier));
            if (twin >= 0)
            {
                // Puan eşitse sözcükleri ayrı okunan kazanır ("yowwill" yerine "you will").
                var (better, current) = (OcrNoise.Score(line), OcrNoise.Score(kept[twin]));
                if (better > current || (better == current && line.Count(c => c == ' ') > kept[twin].Count(c => c == ' '))) kept[twin] = line;
                continue;
            }
            kept.Add(line);
        }
        return string.Join('\n', kept);
    }
}
