// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>Yazının yeri, içinde bulunduğu alanın kenarlarına oranla (0–1, üstten ve soldan).</summary>
public readonly record struct TextBox(double Left, double Top, double Right, double Bottom)
{
    public TextBox Union(TextBox other) =>
        new(Math.Min(Left, other.Left), Math.Min(Top, other.Top), Math.Max(Right, other.Right), Math.Max(Bottom, other.Bottom));

    /// <summary>Bu kutu <paramref name="area"/> içindeki oranlarsa, aynı yerin <paramref name="area"/>'yı içeren çerçevedeki oranları.</summary>
    public TextBox PlacedIn(TextBox area)
    {
        var width = area.Right - area.Left;
        var height = area.Bottom - area.Top;
        return new(area.Left + (Left * width), area.Top + (Top * height), area.Left + (Right * width), area.Top + (Bottom * height));
    }

    /// <summary>
    /// Ekranın ortasındaki altyazının kutusu ortaya göre simetrik genişletilir. Açık zeminde ya da renkli yazıda yazı
    /// tanıma satırın bir ucunu okuyamayabilir; kutu yalnız okunan parçayı örterse İngilizcenin geri kalanı yanda görünür
    /// ve çeviri ortalanmamış durur. Ortadan uzak (köşedeki) yazıya dokunulmaz (Mac: TextBox.centeredOnScreen).
    /// </summary>
    public TextBox CenteredOnScreen()
    {
        var middle = (Left + Right) / 2;
        if (middle <= 0.3 || middle >= 0.7) return this;
        return this with { Left = Math.Max(0, Math.Min(Left, 1 - Right)), Right = Math.Min(1, Math.Max(Right, 1 - Left)) };
    }
}

/// <summary>
/// Yazı tanımanın bulduğu bir satır; kutu okunan alana göredir, bilinmiyorsa null. Güven 0–1'dir; okuyucu vermiyorsa
/// null (Windows'un yazı tanıması vermez).
/// </summary>
public sealed record TextLine(string Text, TextBox? Box = null, double? Confidence = null);

/// <summary>Bir karenin okunan satırları, yukarıdan aşağı (Mac: GameTranslatorCore/Reading.swift).</summary>
public sealed class Reading
{
    public static readonly Reading Empty = new([]);

    public Reading(IEnumerable<TextLine> lines) =>
        Lines = [.. lines.Where(line => !string.IsNullOrWhiteSpace(line.Text))];

    public IReadOnlyList<TextLine> Lines { get; }

    /// <summary>Satırları ayrı ayrı bilinmeyen okuyucular için: her satır sonu bir satırdır.</summary>
    public static Reading FromText(string text) =>
        new(text.Replace("\r\n", "\n").Split('\n').Select(line => new TextLine(line.Trim())));

    public string Text => string.Join('\n', Lines.Select(line => line.Text));

    /// <summary>
    /// Aynı satırdaki iki sözcük arasındaki boşluk (piksel) ayrı yazılara mı işaret ediyor? Yalnız hem satır yüksekliğinin
    /// dört katından hem görüntü genişliğinin %12'sinden genişse: soldaki menü ile sağdaki gösterge böyle ayrılır.
    /// Daha dar boşluk çoğunlukla okunamayan sözcüklerdir (açık zemindeki ince altyazıda yazı tanıma bazı sözcükleri
    /// atlar); orada bölmek cümleyi parçalara ayırır, parçanın çevirisi anlamsızlaşır ve kutusu satırı örtmez (GTA V).
    /// </summary>
    public static bool IsSeparateText(double gap, double lineHeight, double imageWidth) =>
        gap > lineHeight * 4 && gap > imageWidth * 0.12;

    /// <summary>Bütün satırları içine alan kutu; hiçbir satırın yeri bilinmiyorsa null.</summary>
    public TextBox? Box
    {
        get
        {
            TextBox? total = null;
            foreach (var line in Lines)
                if (line.Box is { } box) total = total?.Union(box) ?? box;
            return total;
        }
    }

    /// <summary>Satırların ortalama tanıma güveni (0–1); okuyucu güven vermiyorsa null.</summary>
    public double? Confidence =>
        Lines.Where(line => line.Confidence is not null).Select(line => line.Confidence!.Value).ToList() is { Count: > 0 } values
            ? values.Average() : null;

    /// <summary>Oyunun düğme ipuçları ("R2 Swing", "△ Pick up") çıkarılmış hali; bunlar altyazı değildir.</summary>
    public Reading WithoutButtonPrompts() => new(Lines.Where(line => !ButtonPrompts.IsPrompt(line.Text)));

    /// <summary>
    /// Yazı tanımanın uydurduğu sözcük çöpleri ("ou$3e", "waters2aljd") ayıklanmış hali; çevirmen bunları olduğu
    /// gibi taşıyıp TV'de anlamsız harfler gösteriyordu.
    /// </summary>
    public Reading WithoutOcrNoise() => new(Lines.Select(line => line with { Text = OcrNoise.Clean(line.Text) }));

    /// <summary>
    /// Alandaki altyazı bloğu. Seçilen alanda altyazının yanında menü ("MAP / HELP / SETTINGS" alt alta), köşedeki
    /// gösterge ("9", "PHOTO MODE") da okunuyordu; hepsi tek cümle gibi çevrilip TV'de bütün alanı kaplayan kutuyla
    /// gösteriliyordu. Satırlar yerlerine göre bloklara ayrılır; ortalanmış ve menü olmayan en alttaki blok altyazıdır.
    /// Ortalanmış blok yoksa en az üç sözcüklü, menü olmayan en alttaki blok alınır. Satırların yeri bilinmiyorsa
    /// okuma olduğu gibi kalır. <paramref name="area"/>, okunan alanın karedeki yeridir (Mac: Reading.subtitleBlock).
    /// </summary>
    public Reading SubtitleBlock(TextBox area)
    {
        if (Lines.Count == 0 || Lines.Any(line => line.Box is null)) return this;
        var blocks = new List<List<TextLine>>();
        foreach (var line in Lines.OrderBy(line => line.Box!.Value.Top))
        {
            var box = line.Box!.Value.PlacedIn(area);
            var index = blocks.FindLastIndex(block => Belongs(box, block, area));
            if (index >= 0) blocks[index].Add(line);
            else blocks.Add([line]);
        }
        var candidates = blocks.Select(block => new Reading(block)).Where(reading => !reading.IsMenu).ToList();
        var centered = candidates.Where(reading =>
        {
            var box = reading.Box!.Value.PlacedIn(area);
            return Math.Abs(((box.Left + box.Right) / 2) - 0.5) <= 0.12;
        }).ToList();
        if (centered.Count > 0) return centered.MaxBy(reading => reading.Box!.Value.Bottom)!;
        return candidates.Where(reading => WordCount(reading.Text) >= 3).MaxBy(reading => reading.Box!.Value.Bottom) ?? Empty;
    }

    /// <summary>
    /// Bazı oyunlar konuşmacı adını sözün üstünde ayrı bir satırda, büyük harflerle ve iki noktasız gösterir
    /// ("MARKOS" / "We have no option but to try!"). Ad ilk söz satırının başına "MARKOS: …" olarak taşınır; böylece
    /// adı satır içinde gösteren oyunlarla aynı biçim olur (ad cümlenin öznesi sanılmaz, bölünen cümleler birleşir).
    /// </summary>
    public Reading WithSpeakerLine()
    {
        if (Lines.Count < 2 || IsHeading(Lines[1].Text)) return this;
        // Ad büyük harfle ("MARKOS") ya da baş harfi büyük tek sözcükle ("Sojiro", "Manager") yazılır. İkincisi yalnız
        // ad kutusu sözün sol üstündeyse sayılır (ortalı "Yeah / I know." iki satırlık altyazıdır) ve alttaki satır yeni
        // bir cümle başlatmalı ("Sojiro / will be taking care of me." sarılmış tek cümledir).
        if (!IsSpeakerLine(Lines[0].Text) && !(IsTitleName(Lines[0].Text) && StartsSentence(Lines[1].Text) && NameBoxAbove(Lines[0], Lines[1])))
            return this;
        var (name, first) = (Lines[0] with { Text = Lines[0].Text.Trim().TrimEnd('.') }, Lines[1]);
        var box = name.Box is { } a && first.Box is { } b ? a.Union(b) : first.Box ?? name.Box;
        return new Reading([first with { Text = $"{name.Text.Trim()}: {first.Text.Trim()}", Box = box }, .. Lines.Skip(2)]);
    }

    /// <summary>Konuşmada tek başına satır olabilen sözcükler; ad sayılmaz.</summary>
    private static readonly HashSet<string> Interjections = new(StringComparer.OrdinalIgnoreCase)
    {
        "yeah", "yes", "no", "okay", "ok", "wait", "hey", "look", "listen", "well", "sorry", "thanks", "please", "hello",
        "right", "fine", "sure", "come", "run", "stop", "go", "now", "then", "hmm", "huh", "oh", "ah", "uh", "um", "what",
        "why", "how", "who", "where", "really", "maybe", "never", "help", "quiet", "enough", "again", "here", "there",
    };

    /// <summary>
    /// Baş harfi büyük, gerisi küçük bir iki sözcük: "Sojiro", "Manager", "Tifa's Dad". Sonda okunan nokta ("Barret.")
    /// sayılmaz.
    /// </summary>
    internal static bool IsTitleName(string text)
    {
        var name = text.Trim().TrimEnd('.');
        var words = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return words.Length is 1 or 2 && name.Length is >= 3 and <= 20 && !Interjections.Contains(words[0]) &&
               words.All(word => word.Length >= 2 && char.IsUpper(word[0]) && word.Skip(1).All(c => char.IsLower(c) || c is '-' or '\'' or '’'));
    }

    /// <summary>Ad kutusu sözün sol üstünde mi: sol kenarı sözünkinden sağda değil, ortası belirgin biçimde solda.</summary>
    private static bool NameBoxAbove(TextLine name, TextLine speech)
    {
        if (name.Box is not { } a || speech.Box is not { } b) return false;
        return a.Left <= b.Left + 0.02 && (a.Left + a.Right) / 2 < ((b.Left + b.Right) / 2) - 0.05;
    }

    /// <summary>Satır yeni bir cümle başlatıyor mu: ilk harfi büyük (önündeki "..." ya da tırnak sayılmaz).</summary>
    private static bool StartsSentence(string text)
    {
        var first = text.FirstOrDefault(char.IsLetterOrDigit);
        return first != default && (char.IsUpper(first) || char.IsDigit(first));
    }

    /// <summary>En çok üç sözcüklü, tümü büyük harf, noktalamasız satır: konuşmacı adı ("MARKOS", "YOUNG ALEXIOS").</summary>
    internal static bool IsSpeakerLine(string text)
    {
        var trimmed = text.Trim();
        var letters = trimmed.Where(char.IsLetter).ToList();
        return letters.Count >= 2 && letters.All(char.IsUpper) && WordCount(trimmed) <= 3 &&
               trimmed.All(c => char.IsLetter(c) || c is ' ' or '-' or '.' or '\'' or '’');
    }

    /// <summary>
    /// Başlık, menü ya da ekran yazısı gibi duran satırlardan oluşan okuma boş sayılır ("Engraving Challenges",
    /// "SORT BY: CATEGORY", "LEVEL 2", tek başına konuşmacı adı). Konuşma içeren okumaya dokunulmaz.
    /// </summary>
    public Reading WithoutHeadings() => Lines.Count > 0 && Lines.All(line => IsHeading(line.Text)) ? Empty : this;

    private static readonly HashSet<string> SmallWords = new(StringComparer.OrdinalIgnoreCase)
        { "a", "an", "the", "of", "and", "or", "to", "in", "on", "for", "by", "at", "with", "&" };

    /// <summary>
    /// Cümle gibi bitmeyen, virgülsüz, en çok beş sözcüklü ve ya tümü büyük harf ya da her sözcüğü büyük harfle başlayan
    /// satır ("Gear Visual Customization", "ACHAIA"). "Thank you" ya da "Hold the gate" başlık değildir.
    /// </summary>
    internal static bool IsHeading(string text)
    {
        var trimmed = text.Trim();
        if (trimmed.Length == 0) return true;
        if (SubtitleStabilizer.EndsSentence(trimmed) || trimmed.Contains(',') || trimmed.EndsWith("--", StringComparison.Ordinal)) return false;
        var words = trimmed.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Where(word => word.Any(char.IsLetter)).ToList();
        if (words.Count is 0 or > 5) return words.Count == 0;
        var letters = trimmed.Where(char.IsLetter).ToList();
        if (letters.All(char.IsUpper)) return true;
        // Mesafe ve sayaç göstergeleri ("19m", "12 m", "x3"): rakam ve en çok iki harf.
        if (letters.Count <= 2 && trimmed.Any(char.IsDigit)) return true;
        if (words.Count < 2) return false;
        return words.All(word => SmallWords.Contains(word) || char.IsUpper(word.First(char.IsLetter)));
    }

    /// <summary>Bloğun son satırının hemen altında ve yatayda onunla üst üste binen satır o bloğa aittir.</summary>
    private static bool Belongs(TextBox box, List<TextLine> block, TextBox area)
    {
        var last = block[^1].Box!.Value.PlacedIn(area);
        var height = Math.Max(box.Bottom - box.Top, last.Bottom - last.Top);
        if (box.Top - last.Bottom >= height * 0.8 || box.Top < last.Top) return false;
        var overlap = Math.Min(box.Right, last.Right) - Math.Max(box.Left, last.Left);
        var narrower = Math.Min(box.Right - box.Left, last.Right - last.Left);
        return overlap > 0 && overlap >= narrower * 0.5;
    }

    /// <summary>Alt alta kısa ve noktalamasız satırlar ("MAP", "HELP", "SOCIAL CLUB") menüdür, konuşma değil.</summary>
    internal bool IsMenu => Lines.Count >= 3 &&
        Lines.All(line => WordCount(line.Text) <= 3 && !SubtitleStabilizer.EndsSentence(line.Text));

    private static int WordCount(string text) => text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;

    /// <summary>Satır kutularını <paramref name="area"/> içindeki oranlardan dış çerçevenin oranlarına taşır.</summary>
    public Reading PlacedIn(TextBox area) => new(Lines.Select(line => line with { Box = line.Box?.PlacedIn(area) }));
}

/// <summary>
/// Oyunların ekranda gösterdiği kumanda ipuçlarını tanır: "R2 Swing", "L1 + R1 Spartan Rage", "△ Pick up",
/// "Press ✕ to jump". Konuşma satırları dokunulmadan kalır (Mac'teki ButtonPrompts ile aynı kurallar).
/// </summary>
public static class ButtonPrompts
{
    /// <summary>Her zaman kumanda düğmesi olan simgeler ve adlar (yazı tanıma bazen köşeli parantezle okur).</summary>
    private static readonly HashSet<string> Buttons = new(StringComparer.OrdinalIgnoreCase)
    {
        "R1", "R2", "R3", "L1", "L2", "L3", "OPTIONS", "TOUCHPAD",
        "✕", "×", "⨯", "✖", "○", "◯", "●", "□", "▢", "◻", "■", "△", "▲", "⨂",
    };

    /// <summary>Simge yazı tanımada harfe dönüşebilir; yalnız ipucu kalıbında düğme sayılır.</summary>
    private static readonly HashSet<string> Lookalikes = new(StringComparer.Ordinal) { "X", "O" };

    /// <summary>
    /// Düğme adının yanlış okunmuş hali: "R1" → "RI" / "Rl", "L2" → "LZ". Yalnız satır başında ve cümle gibi bitmeyen
    /// kısa satırda düğme sayılır ("RI (Hold) Pull", "LI Spider Barrage"); "Li, come here." konuşmadır.
    /// </summary>
    private static readonly HashSet<string> MisreadButtons = new(StringComparer.Ordinal) { "RI", "LI", "Rl", "Ll", "RZ", "LZ" };

    private static readonly HashSet<string> Verbs = new(StringComparer.OrdinalIgnoreCase)
    {
        "press", "hold", "tap", "push", "use", "mash", "release",
    };

    private static readonly char[] Separators = [' ', '\t', '+', '/'];
    private static readonly char[] Brackets = ['(', ')', '[', ']', '{', '}', '<', '>', '「', '」'];

    /// <summary>
    /// Oyun arayüzü satırı: içinde iki ya da daha çok düğme etiketi ("Select(O)", "(S)", "(OFF)") olan çubuk ya da
    /// ondalıklı sayı taşıyan kısa gösterge ("Movement 1.8", "Bonus Action Movement 0.0"). Cümle gibi biten satır
    /// arayüz sayılmaz.
    /// </summary>
    private static bool IsInterfaceBar(string line)
    {
        if (SubtitleStabilizer.EndsSentence(line)) return false;
        var labels = System.Text.RegularExpressions.Regex.Matches(line, @"\((?:[A-Z]{1,3}|[A-Z]{2,4})\)").Count;
        // Tek başına "O" / "X" de düğmedir ("Select) O Actions Sort Tooltips (OFF) O Close").
        var tokens = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (labels >= 2 || labels + tokens.Count(Lookalikes.Contains) >= 3) return true;
        var words = tokens.Count(token => token.Count(char.IsLetter) >= 2);
        return words <= 6 && System.Text.RegularExpressions.Regex.IsMatch(line, @"(?<![\w.])\d+\.\d(?![\w.])");
    }

    public static bool IsPrompt(string line)
    {
        var tokens = line.Split(Separators, StringSplitOptions.RemoveEmptyEntries)
            .Select(token => token.Trim(Brackets))
            .Where(token => token.Length > 0)
            .ToList();
        if (tokens.Count == 0) return false;
        if (IsInterfaceBar(line)) return true;
        // Tuş simgesi noktalama okunmuş etkileşim yazısı (":Read message", ":Pillage remains"): simge, ardından cümle gibi
        // bitmeyen kısa bir eylem.
        var trimmedLine = line.TrimStart();
        if (trimmedLine.Length > 1 && trimmedLine[0] is ':' or ';' or '•' or '©' or '®' && char.IsUpper(trimmedLine.TrimStart(':', ';', '•', '©', '®', ' ')[0]) &&
            tokens.Count <= 5 && !SubtitleStabilizer.EndsSentence(line))
            return true;
        var first = tokens[0];
        var words = tokens.Count(token => !Buttons.Contains(token) && token.Any(char.IsLetter));

        // "R2 Swing", "△ Pick up", "L1 R1 Spartan Rage"
        if (Buttons.Contains(first)) return words <= 5;
        if (MisreadButtons.Contains(first) && tokens.Count >= 2 && words <= 6 && !SubtitleStabilizer.EndsSentence(line)) return true;
        // "PHOTO MODE L1 + R1": düğme sonda, önünde kısa ve noktalamasız bir eylem adı.
        if (Buttons.Contains(tokens[^1]) && words <= 4 && !SubtitleStabilizer.EndsSentence(line)) return true;
        // Ekranın altındaki ipucu çubuğu: "X Pick up Select(O) Actions Sort Tooltips (OFF) O Close". Düğmeyle başlar,
        // içinde en az bir düğme daha vardır, cümle gibi bitmez ve sözcüklerinin çoğu büyük harfle başlar.
        if (Lookalikes.Contains(first) && tokens.Count is >= 4 and <= 16 && !SubtitleStabilizer.EndsSentence(line) &&
            tokens.Skip(1).Any(token => Lookalikes.Contains(token) || Buttons.Contains(token)) &&
            tokens.Count(token => char.IsUpper(token[0])) * 3 >= tokens.Count * 2)
            return true;
        // "X Interact", "O Back": ardından kısa, büyük harfle başlayan, noktalamasız bir eylem gelir.
        if (Lookalikes.Contains(first) && tokens.Count is >= 2 and <= 4 && char.IsUpper(tokens[1][0]) &&
            !SubtitleStabilizer.EndsSentence(line))
            return true;
        // "Press ✕ to jump", "Hold R2 to aim"; düğme simgesi harf olmayan bir işarete dönüşebilir ("PRESS @ TO CONTINUE").
        if (Verbs.Contains(first) && tokens.Count is >= 2 and <= 10)
            return Buttons.Contains(tokens[1]) || Lookalikes.Contains(tokens[1]) || MisreadButtons.Contains(tokens[1]) ||
                   (tokens[1].Length <= 2 && !tokens[1].Any(char.IsLetterOrDigit)) ||
                   // "PRESS e TO CONTINUE": düğme simgesi tek harf okunmuş, ardından "to" geliyor.
                   (tokens.Count >= 4 && tokens[1].Length <= 2 && string.Equals(tokens[2], "to", StringComparison.OrdinalIgnoreCase));
        return false;
    }
}

