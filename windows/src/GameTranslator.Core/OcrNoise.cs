// SPDX-License-Identifier: AGPL-3.0-only

using System.Globalization;
using System.Text.RegularExpressions;

namespace GameTranslator.Core;

/// <summary>
/// Süslü yazı tiplerinde, solan ya da titreyen altyazıda yazı tanıma bazı sözcükleri harf, rakam ve simge
/// karışımı çöpe çevirir ("ou$3e", "waters2aljd"). Bunlar hiçbir dilde sözcük değildir; çevirmen onları
/// olduğu gibi taşır. Sözcük ortasında simge ya da harflerle rakamların iç içe geçtiği parçalar atılır;
/// gerçek bir sözcüğe yapışmış çöp ("waters2aljd") sözcükten ayrılır. "PS5", "R2", "2nd", "100m", "$500"
/// gibi olağan biçimler korunur (Mac'teki OcrNoise ile aynı kurallar).
/// </summary>
public static partial class OcrNoise
{
    private const string Symbols = "$@#%^*_=|\\~<>{}¢£¥§©®°±µ¶¤";

    public static string Clean(string line)
    {
        line = FixSpeaker(line);
        var kept = new List<string>();
        var tokens = line.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);
        for (var index = 0; index < tokens.Length; index++)
        {
            var token = tokens[index];
            var (lead, core, trail) = Split(token);
            // Tek başına "l" ya da "|" çoğu zaman yanlış okunmuş "I"dır ("l don't know", "|'ll go"); ardından küçük
            // harfle süren sözcük gelmiyorsa altyazı kutusunun kenarıdır ("| Get in the car."), atılır.
            if (MisreadI(core) is { } pronoun)
            {
                var next = index + 1 < tokens.Length ? tokens[index + 1].FirstOrDefault(char.IsLetter) : '\0';
                if (pronoun != "I" || char.IsLower(next)) kept.Add(lead + pronoun + trail);
                continue;
            }
            // Yalnız "?!", ".", "," gibi işaretlerden oluşan parça: satır başında ya da cümle bittikten sonra yazı
            // tanımanın uydurmasıdır ("?! Where", "car. ?!"); sözcükten ayrı düşmüşse sözcüğe yapışır ("going ?!").
            if (core.Length == 0 && IsStrayPunctuation(token))
            {
                if (kept.Count > 0 && !".?!…,;:".Contains(kept[^1][^1])) kept[^1] += token;
                continue;
            }
            if (CleanCore(core) is { } fixedCore)
                kept.Add(lead + fixedCore + trail);
            else if (trail.Length > 0 && kept.Count > 0)
                // Atılan çöpün ardındaki noktalama cümleye aittir ("ou$3e," → virgül kalır).
                kept[^1] += trail;
        }
        // Altyazının yanındaki göstergenin sayısı satırın başına yapışıyor ("9? We'll lose", "100. Mac and John").
        // Mesafe işareti de öyle ("23m CESARE: Here!"). Tek başına sayı ve ardından büyük harfle başlayan cümle: sayı atılır.
        if (kept.Count >= 3 && LeadingNumber().IsMatch(kept[0]) && char.IsUpper(kept[1][0])) kept.RemoveAt(0);
        return FixLineEnd(string.Join(' ', kept));
    }

    /// <summary>
    /// Konuşmacı adı ile iki nokta arasındaki küçük simge (Spider-Man 2'de adın yanındaki maske) harf sanılıyor:
    /// "Spider-Man •g: You'll…", "Spider-Man O: No comment." → "Spider-Man: …". Ad büyük harfle başlayan en çok üç
    /// sözcüktür; simge ya bir işaretle başlayan en çok üç karakter ya da tek başına yuvarlak bir harftir.
    /// </summary>
    [GeneratedRegex(@"^(?<name>\p{Lu}[\p{L}.'’-]+(?: \p{Lu}[\p{L}.'’-]+){0,2}) (?:(?=[^\s:;]{0,2}[^\p{L}\d\s:;])[^\s:;]{1,3}|[Oo0])\s*[:;]")]
    private static partial Regex SpeakerIcon();

    [GeneratedRegex(@"^(?<name>\p{Lu}\p{L}[\p{L}.’'-]*(?<![’'])(?: \p{Lu}\p{L}[\p{L}.’'-]*(?<![’'])){0,2}):(?=\s|$)")]
    private static partial Regex SpeakerLabel();

    /// <summary>Düzgün okunmuş hâli görülen konuşmacı adları ("Spider-Man:") ve kaç kez görüldükleri.</summary>
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<string, int> Speakers = new(StringComparer.Ordinal);
    private const int MaxSpeakers = 200;

    internal static void ForgetSpeakers() => Speakers.Clear();

    /// <summary>
    /// Konuşmacı adının yanındaki simge her karede başka okunur ("so:", "S'.", "'2':", "v:") ya da iki noktayı yutar
    /// ("Spider-Man BOOM!"). Adı en az iki kez düzgün okunmuş konuşmacıda ad ile söz arasındaki en çok üç karakterlik
    /// parça atılır, iki nokta eksikse eklenir. Tanınmayan adlara dokunulmaz ("Guard 2:", "Listen up:").
    /// </summary>
    private static string FixSpeaker(string line)
    {
        line = WithoutLeadingJunk(SpeakerIcon().Replace(line, "${name}:"));
        if (SpeakerLabel().Match(line) is { Success: true } label)
        {
            var read = label.Groups["name"].Value;
            // Henüz tanınmayan ad, tanınan bir adın tek harf farklı okumasıysa ("Spider-Mam:") o addır.
            if (!(Speakers.TryGetValue(read, out var times) && times >= 2) &&
                Speakers.Where(pair => pair.Value >= 2).Select(pair => pair.Key)
                    .FirstOrDefault(known => Misread(read, known, 1) || GluedLetter(read, known)) is { } real)
                return real + line[read.Length..];
            if (Speakers.Count < MaxSpeakers || Speakers.ContainsKey(read))
                Speakers.AddOrUpdate(read, 1, (_, seen) => seen + 1);
            return line;
        }
        foreach (var name in Speakers.Where(pair => pair.Value >= 2).Select(pair => pair.Key).OrderByDescending(key => key.Length))
        {
            if (line.StartsWith(name + " ", StringComparison.Ordinal))
                return WithSpeaker(name, line[(name.Length + 1)..].TrimStart()) ?? line;
            // Adın kendisi bozuk okunmuş ya da simge ada yapışmış: "pider-Man What…", "Spider-Mame•: Wish…".
            var count = name.Count(c => c == ' ') + 2;
            var words = line.Split(' ', count, StringSplitOptions.RemoveEmptyEntries);
            if (words.Length != count) continue;
            var head = string.Join(' ', words[..^1]);
            var core = new string(head.Reverse().SkipWhile(c => !char.IsLetterOrDigit(c)).Reverse().ToArray());
            var marked = core.Length < head.Length;
            var same = core == name;
            if (!same && !Misread(core, name, name.Length >= 9 ? 2 : 1)) continue;
            if (same && !marked) continue;
            if (head.EndsWith(':')) return name + ": " + words[^1];
            if (WithSpeaker(name, words[^1]) is { } repaired) return repaired;
        }
        return line;
    }

    /// <summary>
    /// Bu uzunluğun altındaki ad benzerlikle onarılmaz: kısa adlar birbirine ve sıradan sözcüklere fazla yakındır
    /// ("Rio", "Marko"; "Father" ile "Mother" arasında yalnız iki harf var).
    /// </summary>
    private const int MinFuzzyName = 7;

    /// <summary>
    /// Tanınan konuşmacı adının önüne okunmuş çöp atılır: "'ANNA: …", "--—ANNA: …", "j ANNA: …". Ad satırın ilk
    /// dört karakteri içinde başlamalı ve öncesinde iki harfli bir sözcük bulunmamalıdır.
    /// </summary>
    private static string WithoutLeadingJunk(string line)
    {
        foreach (var name in Speakers.Where(pair => pair.Value >= 2).Select(pair => pair.Key).OrderByDescending(key => key.Length))
        {
            var at = line.IndexOf(name + ":", StringComparison.Ordinal);
            if (at is < 1 or > 4) continue;
            var before = line[..at];
            if (before.Count(char.IsLetter) <= 1 && !char.IsLetterOrDigit(before[^1])) return line[at..];
        }
        return line;
    }

    /// <summary>Tanınan adın başına tek harf yapışmış mı ("IANNA", "JANNA" → "ANNA"); kısa adlarda da güvenlidir.</summary>
    private static bool GluedLetter(string read, string known) =>
        known.Length >= 4 && read.Length == known.Length + 1 && read.EndsWith(known, StringComparison.Ordinal);

    /// <summary><paramref name="read"/>, <paramref name="name"/> adının en çok <paramref name="limit"/> harf farklı okuması mı (çoğul eki sayılmaz).</summary>
    private static bool Misread(string read, string name, int limit) =>
        name.Length >= MinFuzzyName && read != name && read != name + "s" && name != read + "s" &&
        Math.Abs(read.Length - name.Length) <= limit && Distance(read, name) <= limit;

    /// <summary>
    /// Addan sonraki kısım konuşmaysa "Ad: konuşma". Baştaki en çok üç karakterlik simge çöpü ("so:", "S'.", "04:")
    /// atılır; iki nokta yoksa ve söz büyük harfle başlıyorsa eklenir. Konuşmaya benzemiyorsa ("Spider-Man is here.") null.
    /// </summary>
    private static string? WithSpeaker(string name, string rest)
    {
        // İki nokta (ya da öyle okunan ";") hemen baştaysa öncesi simge çöpüdür: "so:", "s i:", "•e;", "04:".
        var mark = rest.IndexOfAny([':', ';']);
        if (mark is > 0 and <= 5)
        {
            var junk = rest[..mark];
            var longestWord = junk.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(part => part.Count(char.IsLetter)).DefaultIfEmpty(0).Max();
            var loneDigit = junk.Trim().Length == 1 && char.IsDigit(junk.Trim()[0]);
            if (longestWord < 3 && !loneDigit) return name + ": " + rest[(mark + 1)..].TrimStart();
        }
        var space = rest.IndexOf(' ');
        if (space > 0 && rest[space - 1] == '.')
        {
            var core = rest[..(space - 1)];
            var symbol = core.Any(c => !char.IsLetterOrDigit(c));
            if (core.Length is >= 1 and <= 3 && (symbol || char.IsLower(core[0]))) return name + ":" + rest[space..];
        }
        // Harf içermeyen kısa parça ("\"", "•", "' •") iki noktanın yerine okunmuş simgedir.
        if (space is > 0 and <= 3 && !rest[..space].Any(char.IsLetterOrDigit))
            return name + ": " + rest[(space + 1)..].TrimStart();
        return rest.Length > 0 && char.IsUpper(rest[0]) ? name + ": " + rest : null;
    }

    /// <summary>Düzenleme uzaklığı (ekleme, silme, değiştirme).</summary>
    private static int Distance(string a, string b)
    {
        var previous = Enumerable.Range(0, b.Length + 1).ToArray();
        for (var i = 1; i <= a.Length; i++)
        {
            var current = new int[b.Length + 1];
            current[0] = i;
            for (var j = 1; j <= b.Length; j++)
                current[j] = Math.Min(Math.Min(current[j - 1], previous[j]) + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
            previous = current;
        }
        return previous[b.Length];
    }

    /// <summary>
    /// Cümle sonuna yapışan çöp: yazı tanıma sondaki noktadan sonra bir iki harf uyduruyor ("Focus.ie", "now.l.") ve
    /// üç noktayı alt tırnakla okuyor ("me„.", "kidding.„"). Kısaltmalar ("p.m", "e.g") korunur: noktadan önce en az üç harf aranır.
    /// </summary>
    private static string FixLineEnd(string line)
    {
        var text = TrailingJunk().Replace(LowQuoteDots().Replace(line, "..."), "");
        // Cümle bittikten sonra okunan kısa artıklar ("…right?! i 'o/", "…too! t)", "…okay? 'NV") atılır.
        return StrayTail().Replace(text, "");
    }

    /// <summary>Cümle sonu işaretinden sonra gelen, en çok üç karakterlik, harf dışı işaret içeren ya da tek harflik parça.</summary>
    [GeneratedRegex(@"(?<=[.!?…])(?:\s+(?:(?=\S{0,2}[^\p{L}\d\s.!?…])\S{1,3}|\p{L}))+$")]
    private static partial Regex StrayTail();

    [GeneratedRegex(@"(?<=\p{L}{3}[.!?…])\p{Ll}{1,2}[.?]?$")]
    private static partial Regex TrailingJunk();

    [GeneratedRegex(@"\.„\.?|„\.")]
    private static partial Regex LowQuoteDots();

    [GeneratedRegex(@"^\d+(?:m|km|ft|yd)?[.?!:;]?$")]
    private static partial Regex LeadingNumber();

    /// <summary>
    /// Bir okumanın ne kadar sözcük gibi göründüğü: düzgün sözcüklerin harfleri artı, çöp ve karışık büyük-küçük
    /// harfli parçalar ("CESAREiVJütt'h") eksi sayılır. Aynı karenin iki okumasından iyisini seçmek için.
    /// </summary>
    public static int Score(string text)
    {
        var score = 0;
        foreach (var token in text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
        {
            var core = Split(token).Core;
            var letters = core.Count(char.IsLetter);
            if (letters == 0) continue;
            // Sözcük ortasındaki parantez ("the[lil") de okuma karışıklığıdır.
            var clean = CleanCore(core) == core && NormalCase(core) && core.IndexOfAny(['[', ']', '(', ')']) < 0;
            score += clean ? letters : -2 * letters;
        }
        return score;
    }

    /// <summary>
    /// Okuma çöp gibi mi: harflerinin altıda birinden çoğu bozuk sözcüklerde (karışık büyük-küçük harf, simge, ünlüsüz
    /// "Gtt"). Altyazılar geçişte birbirinin üstüne solarken yazı tanıma iki satırı karıştırıp ("Gtt solkolfege.")
    /// noktayla biten bir çöp okuyordu; nokta yüzünden ilk karede çevriliyor, TV'de anlamsız bir cümle beliriyordu (Mac ile aynı).
    /// </summary>
    public static bool LooksGarbled(string text)
    {
        int good = 0, bad = 0;
        foreach (var token in text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
        {
            var core = Split(token).Core;
            var letters = new string(core.Where(char.IsLetter).ToArray());
            if (letters.Length == 0) continue;
            var clean = CleanCore(core) == core && NormalCase(core) && core.IndexOfAny(['[', ']', '(', ')']) < 0 && !Vowelless(letters);
            if (clean) good += letters.Length; else bad += letters.Length;
        }
        return bad * 6 > good + bad;
    }

    /// <summary>Üç ve daha çok harfli, ünlüsüz ve kısaltma olmayan (tümü büyük harf değil) sözcük: İngilizcede olmaz ("Gtt", "rnnk").</summary>
    private static bool Vowelless(string letters) =>
        letters.Length >= 3 && !letters.All(char.IsUpper) && letters.ToLowerInvariant().IndexOfAny("aeiouyäöüıàáâèéêìíîòóôùúû".ToCharArray()) < 0;

    /// <summary>"word", "WORD", "Word", "McDonald", "don't": büyük harf yalnız başta ya da baştan bir dizi.</summary>
    private static bool NormalCase(string core)
    {
        var letters = core.Where(char.IsLetter).ToArray();
        if (letters.All(char.IsUpper) || letters.Skip(1).All(char.IsLower)) return true;
        // Tek iç büyük harf ("McDonald", "iPhone") olağan; daha fazlası OCR karışıklığıdır.
        return letters.Skip(1).Count(char.IsUpper) == 1 && letters.Count(char.IsLower) >= 2;
    }

    /// <summary>"l", "|", "l'm", "|'ll" → "I", "I'm", "I'll" (null: böyle bir okuma değil).</summary>
    private static string? MisreadI(string core)
    {
        if (core.Length == 0 || core[0] is not ('l' or '|')) return null;
        if (core.Length == 1) return "I";
        if (core[1] is not ('\'' or '’') || core[2..] is not ("m" or "ll" or "ve" or "d")) return null;
        return "I" + core[1..];
    }

    /// <summary>Yalnız ? ! . , ; : işaretlerinden oluşan parça; üç nokta ("...") gerçek noktalamadır.</summary>
    private static bool IsStrayPunctuation(string token) =>
        token.Length > 0 && token.All(c => "?!.,;:".Contains(c)) && !(token.Length >= 2 && token.All(c => c == '.'));

    /// <summary>Sözcüğün kendisi; null ise tamamen çöptür.</summary>
    private static string? CleanCore(string core)
    {
        var letters = core.Count(char.IsLetter);
        var digits = core.Count(char.IsNumber);
        var hasSymbol = core.Any(c => Symbols.Contains(c));
        if (letters == 0) return core;  // "24", "$500", "…"
        if (!hasSymbol && digits == 0) return core;
        if (!hasSymbol && IsUsualMix(core)) return core;
        // Gerçek sözcüğe yapışmış çöp: baştaki en az 3 harf korunur ("waters2aljd" → "waters").
        var prefix = new string(core.TakeWhile(c => char.IsLetter(c) || c is '\'' or '’' or '-').ToArray());
        return prefix.Count(char.IsLetter) >= 3 ? prefix : null;
    }

    /// <summary>"PS5", "R2", "MK2", "2nd", "100m", "4K", "60fps", "x2", "1980s", "R2-D2": olağan harf-rakam karışımları.</summary>
    private static bool IsUsualMix(string core) =>
        core.Split('-').All(part => !part.Any(char.IsNumber) || Usual().IsMatch(part));

    [GeneratedRegex(@"^(?:[A-Za-z]{1,4}\d{1,4}|\d+(?:st|nd|rd|th|s|k|K|m|km|kg|cm|mm|p|x|fps|hp|HP|XP|xp|v|V|D|d)|[xX]\d{1,3}|\d+[.,]\d+[A-Za-z]{0,3}|\d{1,2}[:.]\d{2}(?:am|pm|AM|PM)?)$")]
    private static partial Regex Usual();

    private static bool IsEdge(char c) =>
        !Symbols.Contains(c) && (char.IsPunctuation(c) || char.IsSymbol(c) || "\"'“”‘’«»()[]".Contains(c));

    private static (string Lead, string Core, string Trail) Split(string token)
    {
        int start = 0, end = token.Length;
        while (start < end && IsEdge(token[start])) start++;
        while (end > start && IsEdge(token[end - 1])) end--;
        return (token[..start], token[start..end], token[end..]);
    }
}

