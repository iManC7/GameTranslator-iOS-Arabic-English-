// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Translation;

/// <summary>
/// PP-OCR ile altyazı şeridi okumanın modelden bağımsız adımları: görüntüyü yeniden boyutlandırma, satır bulma
/// modelinin olasılık haritasından satır kutuları çıkarma ve tanıma modelinin çıktısını metne çevirme.
/// Sabitler ve adımlar, 100 yapay altyazı görüntüsünde ölçülen başvuru sürümüyle (Python) aynıdır.
/// </summary>
internal static class PpOcr
{
    /// <summary>Olasılık haritasında bu değerin üstü yazıdır.</summary>
    public const float TextThreshold = 0.3f;
    /// <summary>Bir satır bandı sayılması için bir piksel satırında en az bu kadar yazı pikseli olmalı.</summary>
    public const int MinRowPixels = 8;
    /// <summary>Çekirdek en az bu kadar piksel satırı yüksekliğinde ve bu kadar piksel genişliğinde olmalı.</summary>
    public const int MinKernelHeight = 5;
    public const int MinKernelWidth = 16;
    /// <summary>
    /// Satır bulma modeli yazının tamamını değil ortasındaki çekirdeği (yüksekliğin yaklaşık yarısı) işaretler. Tanıma
    /// modeli yazının çevresinde boşluk ister: pay yokken sözcük aralarını hiç okumuyor. Dikey pay çekirdeğin 0,9 katı,
    /// yatay pay 1,4 katıdır. Yapay görüntülerde 1,5 katı dikey pay en iyisiydi (hata %2,6; 0,9'da %4,8), ama altı
    /// oyunun gerçek karelerinde fazla pay yazıyı küçültüp okumayı bozuyor: 0,9 ile doğru okunan sözcük küçük yazılı
    /// oyunda yarı yarıya artıyor (475 → 738), diğerlerinde aynı ya da daha iyi. 0,6'da harflerin ucu kesiliyor.
    /// </summary>
    public const double GrowVertical = 0.9;
    public const double GrowHorizontal = 1.4;
    /// <summary>Aynı bantta bu kadar çekirdek yüksekliğinden geniş boşluk iki ayrı yazıyı ayırır (gösterge ile altyazı).</summary>
    public const double SplitGapHeights = 4;
    /// <summary>Tanıma modelinin girdi yüksekliği.</summary>
    public const int LineHeight = 48;
    public const int MinLineWidth = 16;
    public const int MaxLineWidth = 2400;

    public readonly record struct Box(int Left, int Top, int Right, int Bottom)
    {
        public int Width => Right - Left;
        public int Height => Bottom - Top;
    }

    /// <summary>
    /// Olasılık haritasından satır kutuları, yukarıdan aşağı ve soldan sağa. Harita <paramref name="mapWidth"/>
    /// genişliğinde saklanır (32'nin katına dolgulu); yalnız <paramref name="width"/> × <paramref name="height"/>
    /// kısmı görüntüdür.
    /// </summary>
    public static List<Box> FindLines(ReadOnlySpan<float> map, int mapWidth, int width, int height)
    {
        var rowCounts = new int[height];
        for (var y = 0; y < height; y++)
        {
            var row = map.Slice(y * mapWidth, width);
            var count = 0;
            foreach (var value in row)
                if (value > TextThreshold) count++;
            rowCounts[y] = count;
        }

        var boxes = new List<Box>();
        var start = -1;
        for (var y = 0; y <= height; y++)
        {
            var filled = y < height && rowCounts[y] >= MinRowPixels;
            if (filled && start < 0)
            {
                start = y;
            }
            else if (!filled && start >= 0)
            {
                if (y - start >= MinKernelHeight) AddBand(map, mapWidth, width, height, start, y, boxes);
                start = -1;
            }
        }
        return boxes;
    }

    /// <summary>Bir satır bandındaki yazı parçalarını (aralarında geniş boşluk varsa ayrı ayrı) kutulara çevirir.</summary>
    private static void AddBand(ReadOnlySpan<float> map, int mapWidth, int width, int height, int top, int bottom, List<Box> boxes)
    {
        var kernel = bottom - top;
        var used = new bool[width];
        for (var y = top; y < bottom; y++)
        {
            var row = map.Slice(y * mapWidth, width);
            for (var x = 0; x < width; x++)
                if (row[x] > TextThreshold) used[x] = true;
        }
        var maxGap = (int)Math.Round(kernel * SplitGapHeights);
        var growY = (int)Math.Round(kernel * GrowVertical);
        var growX = (int)Math.Round(kernel * GrowHorizontal);
        int first = -1, last = -1;
        for (var x = 0; x <= width; x++)
        {
            var on = x < width && used[x];
            if (on)
            {
                if (first < 0) first = x;
                last = x;
                continue;
            }
            // Parça biter: görüntünün sonu ya da geniş bir boşluk.
            if (first >= 0 && (x == width || x - last > maxGap))
            {
                if (last - first >= MinKernelWidth)
                    boxes.Add(new Box(Math.Max(0, first - growX), Math.Max(0, top - growY),
                        Math.Min(width, last + 1 + growX), Math.Min(height, bottom + growY)));
                first = -1;
            }
        }
    }

    /// <summary>
    /// Tanıma modelinin çıktısını (zaman adımı × sınıf) metne çevirir: her adımın en olası sınıfı alınır, yinelenenler
    /// ve boşluk sınıfı (0) atılır. <paramref name="alphabet"/>: sınıf sırasına göre karakterler (0: boş).
    /// </summary>
    public static string Decode(ReadOnlySpan<float> logits, int steps, int classes, IReadOnlyList<string> alphabet)
    {
        var text = new System.Text.StringBuilder();
        var previous = 0;
        for (var step = 0; step < steps; step++)
        {
            var row = logits.Slice(step * classes, classes);
            var best = 0;
            var bestValue = row[0];
            for (var index = 1; index < classes; index++)
            {
                if (row[index] <= bestValue) continue;
                bestValue = row[index];
                best = index;
            }
            if (best != 0 && best != previous && best < alphabet.Count) text.Append(alphabet[best]);
            previous = best;
        }
        return text.ToString().Trim();
    }

    /// <summary>Modelin sözlüğünden sınıf tablosu: 0 boş sınıf, sonra sözlük, en sonda boşluk karakteri.</summary>
    public static List<string> Alphabet(string characters)
    {
        var alphabet = new List<string> { "" };
        alphabet.AddRange(characters.Split('\n'));
        alphabet.Add(" ");
        return alphabet;
    }

    /// <summary>Tanıma için satırın yeni genişliği: yükseklik <see cref="LineHeight"/> olacak biçimde oran korunur.</summary>
    public static int LineWidth(int width, int height) =>
        Math.Clamp((int)Math.Round((double)LineHeight * width / Math.Max(1, height)), MinLineWidth, MaxLineWidth);

    /// <summary>
    /// RGB görüntüyü (piksel başına 3 bayt) çift doğrusal süzgeçle yeniden boyutlandırır; küçültürken süzgeç genişler
    /// (kenar yumuşatma). Başvuru sürümünün kullandığı kitaplıkla aynı yöntem: önce yatay, sonra dikey geçiş.
    /// </summary>
    public static byte[] Resize(byte[] rgb, int width, int height, int newWidth, int newHeight)
    {
        var horizontal = width == newWidth ? rgb : ResizeAxis(rgb, width, height, newWidth, horizontal: true);
        return height == newHeight ? horizontal : ResizeAxis(horizontal, newWidth, height, newHeight, horizontal: false);
    }

    private static byte[] ResizeAxis(byte[] source, int width, int height, int target, bool horizontal)
    {
        var length = horizontal ? width : height;
        var scale = (double)length / target;
        var filterScale = Math.Max(scale, 1.0);
        var support = filterScale; // çift doğrusal süzgecin yarıçapı 1
        var outWidth = horizontal ? target : width;
        var outHeight = horizontal ? height : target;
        var result = new byte[outWidth * outHeight * 3];
        var weights = new double[(int)Math.Ceiling(support) * 2 + 2];
        for (var index = 0; index < target; index++)
        {
            var center = (index + 0.5) * scale;
            var min = Math.Max(0, (int)(center - support + 0.5));
            var max = Math.Min(length, (int)(center + support + 0.5));
            double total = 0;
            for (var k = min; k < max; k++)
            {
                var distance = Math.Abs((k - center + 0.5) / filterScale);
                var weight = distance < 1 ? 1 - distance : 0;
                weights[k - min] = weight;
                total += weight;
            }
            if (total <= 0) { weights[0] = 1; total = 1; max = Math.Min(length, min + 1); }
            var lines = horizontal ? height : width;
            for (var line = 0; line < lines; line++)
            {
                double r = 0, g = 0, b = 0;
                for (var k = min; k < max; k++)
                {
                    var at = horizontal ? ((line * width) + k) * 3 : ((k * width) + line) * 3;
                    var weight = weights[k - min];
                    r += source[at] * weight;
                    g += source[at + 1] * weight;
                    b += source[at + 2] * weight;
                }
                var to = horizontal ? ((line * outWidth) + index) * 3 : ((index * outWidth) + line) * 3;
                result[to] = ToByte(r / total);
                result[to + 1] = ToByte(g / total);
                result[to + 2] = ToByte(b / total);
            }
        }
        return result;
    }

    private static byte ToByte(double value) => (byte)Math.Clamp((int)(value + 0.5), 0, 255);

    /// <summary>RGB baytları modelin beklediği düzene çevirir: kanal × yükseklik × genişlik, (değer / 255 − 0,5) / 0,5.</summary>
    public static void Normalize(byte[] rgb, int width, int height, float[] target, int targetWidth, int targetHeight)
    {
        var plane = targetWidth * targetHeight;
        // Dolgu siyahtır (0 → −1).
        Array.Fill(target, -1f, 0, plane * 3);
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var from = ((y * width) + x) * 3;
                var to = (y * targetWidth) + x;
                target[to] = (rgb[from] / 255f - 0.5f) / 0.5f;
                target[plane + to] = (rgb[from + 1] / 255f - 0.5f) / 0.5f;
                target[(2 * plane) + to] = (rgb[from + 2] / 255f - 0.5f) / 0.5f;
            }
        }
    }
}
