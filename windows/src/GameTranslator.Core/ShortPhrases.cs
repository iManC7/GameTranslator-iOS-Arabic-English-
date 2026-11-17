// SPDX-License-Identifier: AGPL-3.0-only

using System.Globalization;
using System.Text.RegularExpressions;

namespace GameTranslator.Core;

/// <summary>
/// Oyunlarda sık geçen kısa ünlemlerin İngilizce→Türkçe karşılıkları. Bağlamsız kısa satırı çevirmenler sözlük
/// anlamıyla çeviriyor: "Well?" → "Kuyu?", "See?" → "Görmek?", "Brother?" → "Erkek kardeş?", "Hurry!" → "Acele
/// etmek!", "Okay." → "Tamam aşkım.", "Morning!" → "Sabah!". Satırın her cümlesi tablodaysa satır buradan çevrilir;
/// biri bile değilse satırın tamamı her zamanki gibi çevirmene gider (yarı yarıya çeviri yapılmaz). Cümlenin sonundaki
/// noktalama kaynaktaki gibi kalır. Oyuna özgü değildir.
/// </summary>
public static partial class ShortPhrases
{
    private static readonly CultureInfo Turkish = CultureInfo.GetCultureInfo("tr-TR");

    /// <summary>Cümle sonu "?" ise kullanılan karşılık önce, değilse ikinci (yoksa ilki her ikisinde).</summary>
    private static readonly Dictionary<string, (string Question, string Statement)> Table = new(StringComparer.OrdinalIgnoreCase)
    {
        ["okay"] = ("Tamam mı", "Tamam"), ["ok"] = ("Tamam mı", "Tamam"), ["alright"] = ("Tamam mı", "Peki"),
        ["all right"] = ("Tamam mı", "Peki"), ["fine"] = ("Peki", "Peki"), ["good"] = ("İyi mi", "Güzel"),
        ["yes"] = ("Evet mi", "Evet"), ["yeah"] = ("Öyle mi", "Evet"), ["yep"] = ("Evet", "Evet"), ["yup"] = ("Evet", "Evet"),
        ["no"] = ("Hayır mı", "Hayır"), ["nope"] = ("Hayır", "Hayır"), ["nah"] = ("Yok", "Yok"),
        ["sure"] = ("Emin misin", "Tabii"), ["of course"] = ("Elbette", "Elbette"), ["right"] = ("Değil mi", "Doğru"),
        ["well"] = ("Ee", "Şey"), ["see"] = ("Gördün mü", "Gördün mü"), ["huh"] = ("Ha", "Ha"), ["what"] = ("Ne", "Ne"),
        ["why"] = ("Neden", "Neden"), ["how"] = ("Nasıl", "Nasıl"), ["where"] = ("Nerede", "Nerede"), ["who"] = ("Kim", "Kim"),
        ["really"] = ("Gerçekten mi", "Gerçekten"), ["what now"] = ("Şimdi ne olacak", "Şimdi ne olacak"),
        ["wait"] = ("Bekle", "Bekle"), ["hurry"] = ("Acele et", "Acele et"), ["hurry up"] = ("Acele et", "Acele et"),
        ["come"] = ("Gel", "Gel"), ["come on"] = ("Hadi", "Hadi"), ["come here"] = ("Buraya gel", "Buraya gel"),
        ["go"] = ("Git", "Git"), ["run"] = ("Koş", "Koş"), ["stop"] = ("Dur", "Dur"), ["look"] = ("Bak", "Bak"),
        ["listen"] = ("Dinle", "Dinle"), ["help"] = ("İmdat", "İmdat"), ["move"] = ("Çekil", "Çekil"),
        ["get down"] = ("Eğil", "Eğil"), ["look out"] = ("Dikkat et", "Dikkat et"), ["watch out"] = ("Dikkat et", "Dikkat et"),
        ["let's go"] = ("Gidelim mi", "Hadi gidelim"), ["quiet"] = ("Sessiz ol", "Sessiz ol"), ["enough"] = ("Yeter", "Yeter"),
        ["behind you"] = ("Arkanda", "Arkanda"), ["got it"] = ("Anladın mı", "Anladım"), ["understood"] = ("Anlaşıldı mı", "Anlaşıldı"),
        ["thanks"] = ("Teşekkürler", "Teşekkürler"), ["thank you"] = ("Teşekkür ederim", "Teşekkür ederim"),
        ["sorry"] = ("Pardon", "Özür dilerim"), ["please"] = ("Lütfen", "Lütfen"), ["hello"] = ("Merhaba", "Merhaba"),
        ["hi"] = ("Selam", "Selam"), ["hey"] = ("Hey", "Hey"), ["morning"] = ("Günaydın", "Günaydın"),
        ["good morning"] = ("Günaydın", "Günaydın"), ["good night"] = ("İyi geceler", "İyi geceler"), ["bye"] = ("Hoşça kal", "Hoşça kal"),
        ["damn"] = ("Lanet olsun", "Lanet olsun"), ["damn it"] = ("Kahretsin", "Kahretsin"), ["shit"] = ("Kahretsin", "Kahretsin"),
        ["oh"] = ("Ah", "Ah"), ["ah"] = ("Ah", "Ah"), ["hmm"] = ("Hmm", "Hmm"), ["uh"] = ("Ee", "Ee"),
        ["brother"] = ("Kardeşim", "Kardeşim"), ["father"] = ("Baba", "Baba"), ["mother"] = ("Anne", "Anne"),
        ["dad"] = ("Baba", "Baba"), ["mom"] = ("Anne", "Anne"), ["boy"] = ("Evlat", "Evlat"), ["kid"] = ("Evlat", "Evlat"),
        ["sir"] = ("Efendim", "Efendim"), ["boss"] = ("Patron", "Patron"),
        // Ara sahne düğmesi: "Skip" → "Atlamak" çıkıyordu.
        ["skip"] = ("Geç", "Geç"),
        // Telsiz dili: "Over!" → "Üzerinde!", "Roger that" → "Roger bu" çıkıyordu.
        ["over"] = ("Tamam", "Tamam"), ["over and out"] = ("Tamam, kapatıyorum", "Tamam, kapatıyorum"),
        ["roger"] = ("Anlaşıldı", "Anlaşıldı"), ["roger that"] = ("Anlaşıldı", "Anlaşıldı"),
        ["copy"] = ("Duydun mu", "Anlaşıldı"), ["copy that"] = ("Anlaşıldı", "Anlaşıldı"),
    };

    [GeneratedRegex(@"^(?<main>.*\S[.!?…])\s+(?<tail>(?:Over|Over and out)[.!]*)$")]
    private static partial Regex RadioTail();

    /// <summary>
    /// Telsiz konuşmasının sonundaki "Over!" ayrılır: ("Base, we got him!", "Tamam!"). Çevirmen onu cümleyle birlikte
    /// "Üzerinde!" diye çeviriyordu. Sonunda yoksa null.
    /// </summary>
    public static (string Main, string Tail)? SplitRadioTail(string text)
    {
        var match = RadioTail().Match(text.Trim());
        if (!match.Success || match.Groups["main"].Value.Count(char.IsLetter) < 3) return null;
        return (match.Groups["main"].Value, Translate(match.Groups["tail"].Value) ?? "Tamam.");
    }

    [GeneratedRegex(@"(?<=[.!?…])\s+")]
    private static partial Regex SentenceBreak();

    [GeneratedRegex(@"^(?<lead>[.…—\-\s]*)(?<body>.*?)(?<end>[.!?…,]*)$")]
    private static partial Regex Parts();

    /// <summary>Satırın Türkçesi (her cümlesi tablodaysa); değilse null.</summary>
    public static string? Translate(string text)
    {
        text = text.Trim();
        if (text.Length == 0 || text.Length > 40 || text.Contains('\n')) return null;
        var sentences = SentenceBreak().Split(text);
        var result = new List<string>(sentences.Length);
        foreach (var sentence in sentences)
        {
            var parts = Parts().Match(sentence);
            var body = parts.Groups["body"].Value.Trim().Replace('’', '\'');
            var end = parts.Groups["end"].Value;
            if (!Table.TryGetValue(body, out var turkish)) return null;
            var phrase = end.Contains('?') ? turkish.Question : turkish.Statement;
            // "Tamam mı?" gibi karşılık soru ekini içeriyor; kaynakta soru işareti yoksa bile soru olarak kalır.
            result.Add(parts.Groups["lead"].Value.Trim() + phrase + end);
        }
        return string.Join(' ', result);
    }

    /// <summary>
    /// Kaynak normal yazılmışken çevirmenin bütünüyle büyük harfle döndürdüğü çeviri ("No..." → "HAYIR...") normal
    /// yazıma çevrilir: küçük harf, ilk harf büyük. Kaynak da büyük harfle yazılmışsa (bağırma, başlık) dokunulmaz.
    /// </summary>
    public static string FixShouting(string source, string translation)
    {
        var sourceLetters = source.Where(char.IsLetter).ToList();
        var letters = translation.Where(char.IsLetter).ToList();
        if (letters.Count < 3 || !letters.All(char.IsUpper) || sourceLetters.Count == 0 || sourceLetters.All(char.IsUpper)) return translation;
        var lower = translation.ToLower(Turkish);
        var first = lower.IndexOf(lower.First(char.IsLetter));
        return lower[..first] + char.ToUpper(lower[first], Turkish) + lower[(first + 1)..];
    }
}
