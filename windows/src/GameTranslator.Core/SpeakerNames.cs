// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Konuşmacı adlarını oyundan öğrenir ve bozuk okunmuş adı doğrusuna çevirir. Adlar sözlükte olmadığı için yazım
/// denetimi "Minnir" ile "Mimir"i ayıramaz; ama oyun aynı adı onlarca kez gösterir, yazı tanıma çoğunda doğru okur.
/// Sık görülen ad bilinen addır; ilk kez (ya da ikinci kez) görülen ve bilinen bir ada çok benzeyen ad onun bozuk
/// okumasıdır ("Minnir", "Mimnir", "Mimire" → "Mimir"; "Kracos" → "Kratos"). Birbirine benzeyen iki gerçek ad
/// ("Maria", "Marie") ikisi de yeterince görülünce ayrı kalır. Durum tutar; tek iş parçacığından çağrılır.
/// </summary>
public sealed class SpeakerNames
{
    /// <summary>Bir ad bu kadar görülünce bilinen ad olur.</summary>
    public const int KnownAfter = 3;
    /// <summary>
    /// Bilinen ad, benzer addan en az bu kat sık görülmeliyse onun doğrusu sayılır. Yazı tanıma bir adı hep aynı biçimde
    /// bozabiliyor ("Mimir" her beş okumadan birinde "Minnir"), bu yüzden bozuk ad da defalarca görülür; iki gerçek ad
    /// ("Maria", "Marie") ise birbirine yakın sıklıkta geçer.
    /// </summary>
    public const int Ratio = 3;

    private readonly Dictionary<string, int> seen = new(StringComparer.Ordinal);
    /// <summary>Güçlü okuyucunun okuduğu adlar ve kaç kez okuduğu.</summary>
    private readonly Dictionary<string, int> confirmed = new(StringComparer.Ordinal);
    private readonly object gate = new();

    /// <summary>Güçlü okuyucu bir adı bu kadar okuyunca ad doğrulanmış sayılır.</summary>
    public const int ConfirmedAfter = 2;

    /// <summary>
    /// Güçlü okuyucunun okumasındaki konuşmacı adlarını kaydeder. Windows'un okuyucusu bazı adları hep aynı biçimde
    /// bozuyor ("Aloy" → "Alou", "Mimir" → "Minnir"); sık görülen ad bu yüzden doğru ad olmayabiliyor. Güçlü okuyucu
    /// adları neredeyse hep doğru okuyor: onun okuduğu ad, benzer okumaların doğrusu sayılır.
    /// </summary>
    public void Confirm(Reading reading)
    {
        lock (gate)
        {
            foreach (var line in reading.Lines)
            {
                if (Label(line.Text) is not { } read) continue;
                var name = FixCaps(read);
                confirmed[name] = confirmed.GetValueOrDefault(name) + 1;
            }
            if (confirmed.Count > 300) confirmed.Clear();
        }
    }

    /// <summary>
    /// Okumanın konuşmacı adı henüz doğrulanmadı mı (güçlü okuyucu bu adı ya da benzerini henüz yeterince okumadı).
    /// Öyleyse satır güçlü okuyucuyla da okunmalı.
    /// </summary>
    public bool NeedsCheck(string text)
    {
        if (Label(text.Split('\n')[0]) is not { } name) return false;
        lock (gate) return Confirmed(name) is null;
    }

    /// <summary>Ad (ya da benzeri) güçlü okuyucuyla doğrulandı ya da oyunda yeterince görüldü.</summary>
    public bool IsKnown(string name)
    {
        lock (gate)
            return Confirmed(name) is not null ||
                   seen.Any(pair => pair.Value >= KnownAfter && (pair.Key == name || Alike(name, pair.Key)));
    }

    /// <summary>Adın doğrulanmış hâli: kendisi doğrulandıysa kendisi, değilse en çok okunan benzer doğrulanmış ad.</summary>
    private string? Confirmed(string name)
    {
        if (confirmed.GetValueOrDefault(name) >= ConfirmedAfter) return name;
        string? best = null;
        var bestCount = ConfirmedAfter - 1;
        foreach (var (known, count) in confirmed)
            if (count > bestCount && Alike(name, known)) (best, bestCount) = (known, count);
        return best;
    }

    /// <summary>"Aloy: Let's go." → "Aloy"; en çok üç sözcük, baş harfi büyük.</summary>
    private static string? Label(string text)
    {
        var line = text.TrimStart();
        var colon = line.IndexOf(": ", StringComparison.Ordinal);
        if (colon is < 2 or > 30 || !char.IsUpper(line[0])) return null;
        var name = line[..colon];
        return name.Split(' ').Length <= 3 && name.All(c => char.IsLetter(c) || c is ' ' or '-' or '.' or '\'' or '’') ? name : null;
    }

    /// <summary>
    /// Büyük harfle yazılan adda küçük okunan harfler büyütülür: "GAETANo" → "GAETANO", "ENzo" → "ENZO", "DAMiR" →
    /// "DAMIR". İlk iki harfi büyük olan (en az üç harfli) sözcük büyük harfli sayılır; "Mimir", "McKay" dokunulmaz.
    /// </summary>
    public static string FixCaps(string name)
    {
        if (!name.Any(char.IsLower)) return name;
        var words = name.Split(' ');
        var changed = false;
        for (var i = 0; i < words.Length; i++)
        {
            var letters = words[i].Where(char.IsLetter).ToList();
            if (letters.Count < 3 || !char.IsUpper(letters[0]) || !char.IsUpper(letters[1]) || !letters.Any(char.IsLower)) continue;
            words[i] = words[i].ToUpperInvariant();
            changed = true;
        }
        return changed ? string.Join(' ', words) : name;
    }

    /// <summary>
    /// Satır başında art arda iki ad varsa öndeki atılır: "HSS: GAETANO: Worries are for tomorrow." → "GAETANO: …".
    /// Öndeki, sahnedeki dokudan okunup ayrı satırda ad sanılan çöptür; gerçek altyazıda iki ad yan yana gelmez.
    /// </summary>
    public static string WithoutLeadingJunkLabel(string line)
    {
        if (Label(line) is not { } first || first.Length > 12) return line;
        var start = line.IndexOf(first + ": ", StringComparison.Ordinal);
        if (start < 0) return line;
        var rest = line[(start + first.Length + 2)..].TrimStart();
        return Label(rest) is { } second && second != first ? rest : line;
    }

    /// <summary>Satırın başındaki konuşmacı adı <see cref="FixCaps"/> ile düzeltilmiş hâli ("ENzo: Here." → "ENZO: Here.").</summary>
    public static string FixLabelCaps(string line)
    {
        if (Label(line) is not { } name || FixCaps(name) is var fixedName && fixedName == name) return line;
        var start = line.IndexOf(name, StringComparison.Ordinal);
        return line[..start] + fixedName + line[(start + name.Length)..];
    }

    /// <summary>Adı kaydeder ve doğrusunu döner (bilinen bir adın bozuk okumasıysa o ad, değilse kendisi).</summary>
    public string Canonical(string name)
    {
        name = FixCaps(name);
        lock (gate)
            if (Confirmed(name) is { } sure)
            {
                seen[sure] = seen.GetValueOrDefault(sure) + 1;
                return sure;
            }
        seen[name] = seen.GetValueOrDefault(name) + 1;
        if (seen.Count > 300) Forget();
        if (name.Length < 4) return name;
        string? best = null;
        var bestCount = 0;
        foreach (var (known, count) in seen)
        {
            if (count < KnownAfter || count <= bestCount || known == name) continue;
            if (count < seen[name] * Ratio || !Alike(name, known)) continue;
            (best, bestCount) = (known, count);
        }
        return best ?? name;
    }

    /// <summary>
    /// Satır başındaki parça, iki nokta üst üstesi okunmamış bilinen bir ad mı: adın ardına bir iki harf yapışmış
    /// ("Stintsy Fuck", "Stintsi Suggestin'": ":" harf okunmuş) ya da ada çok benzeyen ve ardından büyük harfle başlayan
    /// söz gelen parça ("Jockte Hey..."). Öyleyse bilinen ad; değilse null. Adın kendisine (ad sözün içindeyse: "Jackie is
    /// here") dokunulmaz.
    /// </summary>
    public string? LabelIn(string first, string? next)
    {
        var token = first.TrimEnd('.', ',', ';', ':');
        if (token.Length < 3 || !char.IsUpper(token[0])) return null;
        List<string> names;
        lock (gate) names = [.. seen.Where(pair => pair.Value >= KnownAfter).Select(pair => pair.Key)
            .Concat(confirmed.Where(pair => pair.Value >= ConfirmedAfter).Select(pair => pair.Key)).Distinct()];
        foreach (var known in names)
        {
            // Sözcük sayısı aynı olmalı (iki sözcüklü ad iki sözcüklü parçayla karşılaştırılır).
            // Büyük harfle yazılan bilinen ad ayraçsız da gelebilir ("BODE Using the Empire's tools"): ardından büyük harfle
            // başlayan söz geliyorsa addır. Baş harfi büyük ad ise sözün içinde de geçebilir ("Jackie is here"), dokunulmaz.
            if (token == known && known.Length >= 3 && known.All(c => !char.IsLetter(c) || char.IsUpper(c)) &&
                next is { Length: > 0 } && char.IsUpper(next[0]))
                return known;
            if (known.Length < 4 || known.Count(c => c == ' ') != token.Count(c => c == ' ') || token == known) continue;
            var extra = token.Length - known.Length;
            if (token.StartsWith(known, StringComparison.Ordinal) && extra is 1 or 2 && token[known.Length..].All(char.IsLower)) return known;
            if (token.Length >= 5 && next is { Length: > 0 } && char.IsUpper(next[0]) && Alike(token, known)) return known;
        }
        return null;
    }

    /// <summary>Aynı sayıda sözcük ve harflerin çoğu aynı (uzunluk farkı en çok iki).</summary>
    private static bool Alike(string read, string known)
    {
        if (known.Length < 4 || Math.Abs(read.Length - known.Length) > 2) return false;
        if (read.Count(c => c == ' ') != known.Count(c => c == ' ')) return false;
        return TextMatch.IsSimilar(read.ToLowerInvariant(), known.ToLowerInvariant(), 0.6);
    }

    /// <summary>Bir kez görülmüş adlar (çoğu bozuk okuma) atılır.</summary>
    private void Forget()
    {
        foreach (var name in seen.Where(pair => pair.Value < 2).Select(pair => pair.Key).ToList()) seen.Remove(name);
    }
}
