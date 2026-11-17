// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Örtme yerleşiminde TV, İngilizce altyazının kutusunu koyu bir zeminle örter ve çeviriyi ekranın yatay ortasına,
/// kutunun dikey ortasına yazar. Çeviri İngilizcesinden uzunsa kutunun dışına taşar. Burada kutu, çevirinin kaplayacağı
/// yer tahmin edilerek büyütülür: zemin hem İngilizceyi örter hem çeviriyi içine alır, tek parça görünür.
/// Tahmin TV uygulamasının ölçülerine dayanır (1920×1080 tasarım, satır aralığı 1,3, yazı alanı ekranın %92'si).
/// </summary>
public static class CoverFit
{
    private const double ScreenWidth = 1920;
    private const double ScreenHeight = 1080;
    /// <summary>Yazı alanının genişliği (TV'de soldan ve sağdan %4 boşluk).</summary>
    private const double MaxWidth = 0.92;
    /// <summary>
    /// Ortalama harf genişliğinin yazı boyuna oranı (kalın, Latin harfli yazı; boşluklar dahil). TV görünümünün
    /// bilgisayarda canlandırılmasıyla ölçüldü: Türkçe çeviride ~0,63 (0,54 alınınca uzun satır zeminden taşıyordu).
    /// </summary>
    private const double CharWidth = 0.63;
    private const double LineHeight = 1.3;

    public static TextBox Box(TextBox source, string text, int fontSize)
    {
        var size = Math.Clamp(fontSize, 16, 120);
        var rows = text.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (rows.Length == 0) return source;
        double widest = 0;
        var lines = 0;
        foreach (var row in rows)
        {
            var width = row.Length * size * CharWidth / ScreenWidth;
            // Satır alana sığmazsa TV aşağı sarar.
            var wrapped = Math.Max(1, (int)Math.Ceiling(width / MaxWidth));
            lines += wrapped;
            widest = Math.Max(widest, wrapped > 1 ? MaxWidth : width);
        }
        var height = lines * size * LineHeight / ScreenHeight;
        var middle = (source.Top + source.Bottom) / 2;
        // Çeviri ekranın yatay ortasına yazılır; kutu İngilizcenin de çevirinin de tamamını kapsar.
        return new TextBox(
            Math.Clamp(Math.Min(source.Left, 0.5 - (widest / 2)), 0, 1),
            Math.Clamp(Math.Min(source.Top, middle - (height / 2)), 0, 1),
            Math.Clamp(Math.Max(source.Right, 0.5 + (widest / 2)), 0, 1),
            Math.Clamp(Math.Max(source.Bottom, middle + (height / 2)), 0, 1));
    }
}
