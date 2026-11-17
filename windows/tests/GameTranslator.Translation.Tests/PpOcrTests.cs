// SPDX-License-Identifier: AGPL-3.0-only

using System.Text.Json;
using GameTranslator.Core;

namespace GameTranslator.Translation.Tests;

/// <summary>PP-OCR okuyucunun modelden bağımsız adımları.</summary>
public class PpOcrTests
{
    /// <summary>Verilen dikdörtgenleri yazı (olasılık 0,9) sayan harita.</summary>
    private static float[] Map(int mapWidth, int height, params (int Left, int Top, int Right, int Bottom)[] texts)
    {
        var map = new float[mapWidth * height];
        foreach (var (left, top, right, bottom) in texts)
            for (var y = top; y < bottom; y++)
                for (var x = left; x < right; x++)
                    map[(y * mapWidth) + x] = 0.9f;
        return map;
    }

    [Fact]
    public void KernelGrowsIntoALineBoxWithRoomAroundTheText()
    {
        // 12 piksel yüksekliğinde çekirdek: dikey pay 11 (yuvarlanmış 10,8), yatay pay 17 (yuvarlanmış 16,8).
        var boxes = PpOcr.FindLines(Map(416, 190, (300, 90, 380, 102)), 416, 400, 190);
        var box = Assert.Single(boxes);
        Assert.Equal(new PpOcr.Box(283, 79, 397, 113), box);
    }

    [Fact]
    public void BoxIsClampedToTheImage()
    {
        // Üstte, solda ve sağda pay görüntünün dışına taşar; altta sığar (16 + 11).
        var box = Assert.Single(PpOcr.FindLines(Map(416, 40, (2, 4, 398, 16)), 416, 400, 40));
        Assert.Equal(new PpOcr.Box(0, 0, 400, 27), box);
    }

    [Fact]
    public void LinesComeTopToBottomAndThinOrNarrowSpecksAreIgnored()
    {
        var map = Map(416, 190,
            (100, 120, 300, 132),   // alt satır
            (120, 60, 280, 72),     // üst satır
            (50, 20, 60, 32),       // dar leke (16 pikselden dar)
            (100, 160, 300, 163));  // ince çizgi (5 satırdan az)
        var boxes = PpOcr.FindLines(map, 416, 400, 190);
        Assert.Equal(2, boxes.Count);
        Assert.True(boxes[0].Top < boxes[1].Top);
        Assert.InRange(boxes[0].Left, 100, 120);
    }

    /// Aynı hizadaki iki ayrı yazı (solda gösterge, ortada altyazı) tek satır sayılmaz.
    [Fact]
    public void TextsOnTheSameRowFarApartAreSeparateBoxes()
    {
        var map = Map(832, 60, (20, 20, 120, 32), (400, 20, 700, 32));
        var boxes = PpOcr.FindLines(map, 832, 800, 60);
        Assert.Equal(2, boxes.Count);
        Assert.True(boxes[0].Right < boxes[1].Left);
        // Sözcük arası kadar boşluk satırı bölmez.
        Assert.Single(PpOcr.FindLines(Map(832, 60, (300, 20, 400, 32), (420, 20, 560, 32)), 832, 800, 60));
    }

    [Fact]
    public void EmptyMapHasNoLines() => Assert.Empty(PpOcr.FindLines(new float[416 * 100], 416, 400, 100));

    [Fact]
    public void DecodeCollapsesRepeatsAndDropsBlanks()
    {
        var alphabet = PpOcr.Alphabet("a\nb\nc");
        Assert.Equal(["", "a", "b", "c", " "], alphabet);
        // Adımlar: a a boş a b boş boşluk c c → "aab c"
        int[] best = [1, 1, 0, 1, 2, 0, 4, 3, 3];
        var logits = new float[best.Length * alphabet.Count];
        for (var step = 0; step < best.Length; step++) logits[(step * alphabet.Count) + best[step]] = 5f;
        Assert.Equal("aab c", PpOcr.Decode(logits, best.Length, alphabet.Count, alphabet));
        Assert.Equal("", PpOcr.Decode(new float[2 * alphabet.Count], 2, alphabet.Count, alphabet));
    }

    [Theory]
    [InlineData(627, 27, 1115)]
    [InlineData(48, 48, 48)]
    [InlineData(4, 48, 16)]
    [InlineData(100000, 10, 2400)]
    public void LineWidthKeepsTheAspectRatioWithinLimits(int width, int height, int expected) =>
        Assert.Equal(expected, PpOcr.LineWidth(width, height));

    [Fact]
    public void ResizeKeepsFlatColorsAndAveragesWhenShrinking()
    {
        // Düz renk her boyutta aynı kalır.
        var flat = Enumerable.Repeat((byte)120, 8 * 6 * 3).ToArray();
        Assert.All(PpOcr.Resize(flat, 8, 6, 20, 15), value => Assert.Equal(120, value));
        Assert.All(PpOcr.Resize(flat, 8, 6, 3, 2), value => Assert.Equal(120, value));
        // Sol yarısı siyah, sağ yarısı beyaz dört piksel iki piksele inince uçlar korunur.
        byte[] row = [0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255];
        var half = PpOcr.Resize(row, 4, 1, 2, 1);
        Assert.Equal(6, half.Length);
        Assert.InRange(half[0], 0, 40);
        Assert.InRange(half[3], 215, 255);
        // Aynı boyut: değişmez.
        Assert.Equal(row, PpOcr.Resize(row, 4, 1, 4, 1));
    }

    [Fact]
    public void NormalizeMapsBytesToMinusOneToOneAndPadsWithBlack()
    {
        byte[] rgb = [255, 0, 128];
        var target = new float[3 * 2 * 2];
        PpOcr.Normalize(rgb, 1, 1, target, 2, 2);
        Assert.Equal(1f, target[0], 3);       // kırmızı düzlem, (0,0)
        Assert.Equal(-1f, target[4], 3);      // yeşil düzlem
        Assert.InRange(target[8], 0f, 0.01f); // mavi düzlem: 128 → ~0
        Assert.Equal(-1f, target[1], 3);      // dolgu
        Assert.Equal(-1f, target[3], 3);
    }

    [Fact]
    public void ModelFilesArePinnedWithSizeAndHash()
    {
        Assert.Equal(2, PpOcrReader.Files.Count);
        Assert.Equal(PpOcrReader.EnglishRecognizerFile, PpOcrReader.EnglishFile.Name);
        Assert.All(PpOcrReader.Files.Append(PpOcrReader.EnglishFile), file =>
        {
            Assert.Equal(64, file.Sha256.Length);
            Assert.True(file.Size > 1_000_000);
            Assert.StartsWith("https://huggingface.co/SWHL/RapidOCR/resolve/", file.Url.AbsoluteUri);
            Assert.DoesNotContain("/main/", file.Url.AbsoluteUri);
        });
    }

    /// İngilizce tanıma modeli yalnız oyun dili İngilizceyken ve dosyası varken kullanılır.
    [Fact]
    public void EnglishModelIsOnlyForEnglishAndOnlyWhenPresent()
    {
        var empty = Path.Combine(Path.GetTempPath(), "gt-ppocr-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(empty);
        try
        {
            Assert.False(PpOcrReader.HasEnglish(empty, "en"));
            Assert.False(PpOcrReader.HasEnglish(empty, "ja"));
        }
        finally
        {
            Directory.Delete(empty, recursive: true);
        }
    }
}

/// <summary>
/// Okuyucunun başvuru sürümüyle (Python) aynı sonucu verdiğini doğrular: 100 yapay altyazı görüntüsü, her biri için
/// başvurunun bulduğu satır kutuları ve okuduğu metin. Görüntüler ve model depoya girmez; yoksa test atlanır
/// (GAMETRANSLATOR_PPOCR_MODELS ve GAMETRANSLATOR_PPOCR_REFERENCE ile yer değiştirilir).
/// </summary>
public class PpOcrReferenceTests(Xunit.Abstractions.ITestOutputHelper output)
{
    private static string Cache(string variable, string folder) =>
        Environment.GetEnvironmentVariable(variable) is { Length: > 0 } fromEnv
            ? fromEnv
            : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "gametranslator-test-models", folder);

    internal static string Models => Cache("GAMETRANSLATOR_PPOCR_MODELS", "ppocr");
    internal static string Reference => Cache("GAMETRANSLATOR_PPOCR_REFERENCE", "ppocr-reference");

    private sealed class ReferenceFact : FactAttribute
    {
        public ReferenceFact()
        {
            if (!PpOcrReader.IsInstalled(Models)) Skip = $"PP-OCR models not found in {Models}";
            else if (!File.Exists(Path.Combine(Reference, "beklenen.json"))) Skip = $"PP-OCR reference set not found in {Reference}";
        }
    }

    private sealed record Sample(string Raw, string Truth, string Python, int[][] Boxes);

    private static List<Sample> Load()
    {
        using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(Reference, "beklenen.json")));
        return [.. document.RootElement.EnumerateArray().Select(item => new Sample(
            item.GetProperty("raw").GetString()!, item.GetProperty("truth").GetString()!, item.GetProperty("python").GetString()!,
            [.. item.GetProperty("boxes").EnumerateArray().Select(box => box.EnumerateArray().Select(v => v.GetInt32()).ToArray())]))];
    }

    private static Frame Image(string name)
    {
        var bytes = File.ReadAllBytes(Path.Combine(Reference, name));
        var (width, height) = (BitConverter.ToInt32(bytes, 0), BitConverter.ToInt32(bytes, 4));
        return new Frame(bytes[8..], width, height, width * 4);
    }

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

    [ReferenceFact]
    public void MatchesTheReferenceImplementation()
    {
        var samples = Load();
        using var reader = new PpOcrReader(Models);
        int sameBoxes = 0, sameText = 0;
        double error = 0, referenceError = 0;
        var differences = new List<string>();
        foreach (var sample in samples)
        {
            var image = Image(sample.Raw);
            var reading = reader.ReadLines(image, deep: true);
            var boxes = reading.Lines.Select(line => line.Box!.Value).Select(box => new[]
            {
                (int)Math.Round(box.Left * image.Width), (int)Math.Round(box.Top * image.Height),
                (int)Math.Round(box.Right * image.Width), (int)Math.Round(box.Bottom * image.Height),
            }).ToList();
            if (boxes.Count == sample.Boxes.Length && boxes.Zip(sample.Boxes).All(pair => pair.First.SequenceEqual(pair.Second))) sameBoxes++;
            var text = string.Join(' ', reading.Lines.Select(line => line.Text));
            if (text == sample.Python) sameText++;
            else if (differences.Count < 6) differences.Add($"{sample.Raw}: C# \"{text}\" / Python \"{sample.Python}\"");
            error += (double)Distance(text, sample.Truth) / sample.Truth.Length;
            referenceError += (double)Distance(sample.Python, sample.Truth) / sample.Truth.Length;
        }
        error /= samples.Count;
        referenceError /= samples.Count;
        var report = $"aynı kutu {sameBoxes}/{samples.Count}, aynı metin {sameText}/{samples.Count}, hata C# %{error * 100:0.0} / Python %{referenceError * 100:0.0}\n" +
                     string.Join("\n", differences);
        output.WriteLine(report);
        // Satır bulma adımında yeniden boyutlandırma yoktur: kutular birebir aynı olmalı.
        Assert.True(sameBoxes == samples.Count, report);
        // Tanımada yeniden boyutlandırmanın yuvarlaması birkaç satırda tek karakter oynatabilir.
        Assert.True(sameText >= samples.Count * 9 / 10, report);
        Assert.True(error <= referenceError + 0.01, report);
    }

    [ReferenceFact]
    public void ReadsAStripFastEnoughForLiveSubtitles()
    {
        var samples = Load();
        using var reader = new PpOcrReader(Models);
        reader.ReadLines(Image(samples[0].Raw), deep: true); // ısınma
        var times = new List<double>();
        foreach (var sample in samples.Take(30))
        {
            var image = Image(sample.Raw);
            var watch = System.Diagnostics.Stopwatch.StartNew();
            reader.ReadLines(image, deep: true);
            times.Add(watch.Elapsed.TotalMilliseconds);
        }
        times.Sort();
        var median = times[times.Count / 2];
        output.WriteLine($"şerit başına ortanca {median:0} ms, en az {times[0]:0} ms, en çok {times[^1]:0} ms");
        Assert.True(median < 400, $"ortanca {median:0} ms, en çok {times[^1]:0} ms");
    }
}
