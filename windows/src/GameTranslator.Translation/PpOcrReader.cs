// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Core;
using Microsoft.ML.OnnxRuntime;

namespace GameTranslator.Translation;

/// <summary>
/// PP-OCRv4 (PaddleOCR'ın açık modeli, Apache-2.0; RapidOCR'ın ONNX dönüşümü) ile altyazı şeridi okuyucu.
/// Windows'un yazı tanıması düz zeminde kusursuz ve çok hızlıdır ama hareketli, parlak ya da karışık zeminde ve yazı
/// belirirken harflerin üçte birini yanlış okur; bu okuyucu aynı koşullarda çok daha az hata yapar (yapay altyazı
/// görüntülerinde ortalama karakter hatası %34,6'ya karşı %2,6), karşılığında şerit başına onlarca milisaniye ister.
/// Şerit modelin kendi boyunda işlenir (genel kullanımdaki gibi büyütülmez), satırlar yatay kabul edilir.
/// Paylaşılan değişken durumu yoktur; birden çok iş parçacığından aynı anda çağrılabilir.
/// </summary>
public sealed class PpOcrReader : ITextReader, IDisposable
{
    public const string DetectorFile = "ch_PP-OCRv4_det_infer.onnx";
    public const string RecognizerFile = "ch_PP-OCRv4_rec_infer.onnx";
    /// <summary>
    /// İngilizce için ikinci tanıma modeli (PP-OCRv3). Gerçek oyun karelerinde sözcük aralarını çok daha iyi korur
    /// (küçük ve hareketli zeminli altyazıda genel modelin iki katı gerçek sözcük); temiz satırlarda ikisi denktir ve
    /// hataları farklı yerlerdedir, bu yüzden satır ikisiyle de okunup iyi olan seçilir.
    /// </summary>
    public const string EnglishRecognizerFile = "en_PP-OCRv3_rec_infer.onnx";

    // Depo belirli bir sürüme sabitlenir; dosyalar boyut ve SHA-256 ile doğrulanır.
    private const string Revision = "1cfba2e90fc938db55889873735088de210cc173";
    private static readonly string BaseUrl = $"https://huggingface.co/SWHL/RapidOCR/resolve/{Revision}/PP-OCRv4/";
    private static readonly string OlderUrl = $"https://huggingface.co/SWHL/RapidOCR/resolve/{Revision}/PP-OCRv3/";

    /// <summary>İndirilecek model dosyaları (toplam ~15 MB).</summary>
    public static IReadOnlyList<ModelFile> Files { get; } =
    [
        new(DetectorFile, new Uri(BaseUrl + DetectorFile), 4_745_517,
            "d2a7720d45a54257208b1e13e36a8479894cb74155a5efe29462512d42f49da9"),
        new(RecognizerFile, new Uri(BaseUrl + RecognizerFile), 10_857_958,
            "48fc40f24f6d2a207a2b1091d3437eb3cc3eb6b676dc3ef9c37384005483683b"),
    ];

    /// <summary>İngilizce için ek tanıma modeli (~9 MB); yoksa okuyucu yalnız genel modelle çalışır.</summary>
    public static ModelFile EnglishFile { get; } = new(EnglishRecognizerFile, new Uri(OlderUrl + EnglishRecognizerFile), 8_967_018,
        "ef7abd8bd3629ae57ea2c28b425c1bd258a871b93fd2fe7c433946ade9b5d9ea");

    /// <summary>İki okumadan hangisi iyi (yüksek: daha çok gerçek sözcük); verilmezse <see cref="OcrNoise.Score"/>.</summary>
    public Func<string, int>? Score { get; set; }

    private readonly InferenceSession detector;
    private readonly InferenceSession recognizer;
    private readonly InferenceSession? english;
    private readonly string englishInput = "";
    private readonly string[] englishOutputs = [];
    private readonly List<string> englishAlphabet = [];
    private readonly string detectorInput;
    private readonly string recognizerInput;
    private readonly string[] detectorOutputs;
    private readonly string[] recognizerOutputs;
    private readonly List<string> alphabet;
    private readonly RunOptions runOptions = new();

    /// <param name="language">Oyunun dili; "en" ise ve dosyası varsa İngilizce tanıma modeli de yüklenir.</param>
    public PpOcrReader(string modelDirectory, string language = "")
    {
        using var options = new SessionOptions
        {
            GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL,
            ExecutionMode = ExecutionMode.ORT_SEQUENTIAL,
            // Okuma her karede yapılır; oyunun görüntü çözmesine yer kalsın diye çekirdeklerin en çok yarısı, en çok dört.
            IntraOpNumThreads = Math.Clamp(Environment.ProcessorCount / 2, 1, 4),
            InterOpNumThreads = 1,
        };
        detector = new InferenceSession(Path.Combine(modelDirectory, DetectorFile), options);
        try
        {
            recognizer = new InferenceSession(Path.Combine(modelDirectory, RecognizerFile), options);
        }
        catch
        {
            detector.Dispose();
            throw;
        }
        detectorInput = detector.InputNames[0];
        recognizerInput = recognizer.InputNames[0];
        detectorOutputs = [detector.OutputNames[0]];
        recognizerOutputs = [recognizer.OutputNames[0]];
        // Sözlük modelin içindedir.
        alphabet = PpOcr.Alphabet(recognizer.ModelMetadata.CustomMetadataMap["character"]);
        if (!HasEnglish(modelDirectory, language)) return;
        try
        {
            english = new InferenceSession(Path.Combine(modelDirectory, EnglishRecognizerFile), options);
            englishInput = english.InputNames[0];
            englishOutputs = [english.OutputNames[0]];
            englishAlphabet = PpOcr.Alphabet(english.ModelMetadata.CustomMetadataMap["character"]);
        }
        catch (Exception error) when (error is OnnxRuntimeException or KeyNotFoundException or IOException)
        {
            // Ek model açılamazsa genel modelle devam edilir.
            english?.Dispose();
            english = null;
        }
    }

    /// <summary>İngilizce tanıma modeli bu dil için kullanılacak mı (dil İngilizce ve dosya doğru boyutta).</summary>
    public static bool HasEnglish(string modelDirectory, string language) =>
        language.StartsWith("en", StringComparison.OrdinalIgnoreCase) && new ModelStore(modelDirectory, [EnglishFile]).IsInstalled;

    /// <summary>İngilizce tanıma modeli yüklü mü (günlük için).</summary>
    public bool UsesEnglish => english is not null;

    /// <summary>Model dosyaları klasörde ve doğru boyutta mı.</summary>
    public static bool IsInstalled(string modelDirectory) => new ModelStore(modelDirectory, Files).IsInstalled;

    public string Read(Frame image) => ReadLines(image, deep: true).Text;

    public Reading ReadLines(Frame image, bool deep)
    {
        if (image.Width < 32 || image.Height < 16) return Reading.Empty;
        var rgb = ToRgb(image);
        var lines = new List<TextLine>();
        foreach (var box in FindLines(rgb, image.Width, image.Height))
        {
            var text = ReadLine(rgb, image.Width, box);
            if (text.Length == 0) continue;
            lines.Add(new TextLine(text, new TextBox(
                (double)box.Left / image.Width, (double)box.Top / image.Height,
                (double)box.Right / image.Width, (double)box.Bottom / image.Height)));
        }
        return new Reading(lines);
    }

    private List<PpOcr.Box> FindLines(byte[] rgb, int width, int height)
    {
        // Model 32'nin katı boyut ister; görüntü sol üste konur, kalan siyah dolgudur.
        var paddedWidth = (width + 31) / 32 * 32;
        var paddedHeight = (height + 31) / 32 * 32;
        var input = new float[3 * paddedWidth * paddedHeight];
        PpOcr.Normalize(rgb, width, height, input, paddedWidth, paddedHeight);
        using var value = OrtValue.CreateTensorValueFromMemory(input, [1, 3, paddedHeight, paddedWidth]);
        using var outputs = detector.Run(runOptions, [detectorInput], [value], detectorOutputs);
        return PpOcr.FindLines(outputs[0].GetTensorDataAsSpan<float>(), paddedWidth, width, height);
    }

    private string ReadLine(byte[] rgb, int width, PpOcr.Box box)
    {
        var crop = new byte[box.Width * box.Height * 3];
        for (var y = 0; y < box.Height; y++)
            Buffer.BlockCopy(rgb, (((box.Top + y) * width) + box.Left) * 3, crop, y * box.Width * 3, box.Width * 3);
        var lineWidth = PpOcr.LineWidth(box.Width, box.Height);
        var resized = PpOcr.Resize(crop, box.Width, box.Height, lineWidth, PpOcr.LineHeight);
        var input = new float[3 * lineWidth * PpOcr.LineHeight];
        PpOcr.Normalize(resized, lineWidth, PpOcr.LineHeight, input, lineWidth, PpOcr.LineHeight);
        using var value = OrtValue.CreateTensorValueFromMemory(input, [1, 3, PpOcr.LineHeight, lineWidth]);
        var general = Recognize(recognizer, recognizerInput, recognizerOutputs, alphabet, value);
        if (english is null) return general;
        var specific = Recognize(english, englishInput, englishOutputs, englishAlphabet, value);
        if (specific.Length == 0) return general;
        // Eşitlikte İngilizce model: sözcük aralarını ve kesme işaretlerini daha doğru verir.
        var score = Score ?? OcrNoise.Score;
        return score(general) > score(specific) ? general : specific;
    }

    private string Recognize(InferenceSession session, string input, string[] outputNames, List<string> letters, OrtValue value)
    {
        using var outputs = session.Run(runOptions, [input], [value], outputNames);
        var shape = outputs[0].GetTensorTypeAndShape().Shape; // [1, adım, sınıf]
        return PpOcr.Decode(outputs[0].GetTensorDataAsSpan<float>(), (int)shape[1], (int)shape[2], letters);
    }

    /// <summary>BGRA kareyi RGB baytlara çevirir (model RGB sırasıyla eğitildi).</summary>
    private static byte[] ToRgb(Frame image)
    {
        var rgb = new byte[image.Width * image.Height * 3];
        var pixels = image.Pixels;
        for (var y = 0; y < image.Height; y++)
        {
            var from = y * image.Stride;
            var to = y * image.Width * 3;
            for (var x = 0; x < image.Width; x++, from += 4, to += 3)
            {
                rgb[to] = pixels[from + 2];
                rgb[to + 1] = pixels[from + 1];
                rgb[to + 2] = pixels[from];
            }
        }
        return rgb;
    }

    public void Dispose()
    {
        detector.Dispose();
        recognizer.Dispose();
        english?.Dispose();
        runOptions.Dispose();
    }
}
