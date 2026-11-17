// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Örtme yerleşiminde TV'deki koyu zeminin satırdan satıra zıplamasını önler. Zemin her satırda o satırın İngilizce
/// kutusuna göre yeniden konuyordu: iki satırlı sahnede bir alttaki bir üstteki satıra gidiyor, açıkta kalan İngilizce
/// görünüyordu; aynı altyazı ekrandayken gelen yeni okumayla daralıyordu. Kısa süre içinde (<see cref="HoldMs"/>)
/// aynı yere gelen satırın zemini öncekiyle birleştirilir: büyüyebilir, küçülmez. Bir süre altyazı gelmezse ya da
/// altyazı ekranın başka bir yerine geçerse (ör. sinematikten oynanışa) zemin baştan, yeni kutuya göre kurulur.
/// Kutular ekrana oranladır. Birden çok iş parçacığından çağrılabilir.
/// </summary>
public sealed class StableCover(Func<long>? clock = null)
{
    /// <summary>Son altyazıdan bu kadar sonra gelen satırın zemini baştan kurulur.</summary>
    public const int HoldMs = 4000;
    /// <summary>
    /// Birleşen zemin yeni kutunun yüksekliğinin bu katını ya da ekranın %20'sini geçerse birleştirilmez: alt alta iki
    /// konuşma tek örtüde kalır, üç dört satır üst üste binip ekranı kaplayan kara blok olmaz.
    /// </summary>
    private const double MaxGrowth = 2.6;
    private const double MaxHeight = 0.2;
    /// <summary>Yeni kutu önceki zeminin genişliğinin bu katından darsa birleştirilmez.</summary>
    public const double NarrowerThan = 0.7;

    private readonly Func<long> now = clock ?? (() => Environment.TickCount64);
    private readonly object gate = new();
    private TextBox? last;
    private long lastAt;

    /// <param name="newLine">
    /// Kutu yeni bir satırın (öncekinin düzelmiş okuması değil). Yeni satır belirgin şekilde darsa kendi boyunda örtülür;
    /// aynı satırın eksik okunan hâli ise zemini daraltmaz (İngilizce kenardan görünmesin).
    /// </param>
    public TextBox Next(TextBox box, bool newLine = false)
    {
        lock (gate)
        {
            var at = now();
            // Altyazı şeridi henüz öğrenilmeden okunan geniş alanın kutusu ekranın yarısını kaplayabiliyor; altyazı
            // bloğun altındadır, zemin en çok MaxHeight kadar alttan alınır.
            if (box.Bottom - box.Top > MaxHeight) box = box with { Top = box.Bottom - MaxHeight };
            var result = box;
            // Belirgin şekilde daha dar kutu aynı satırın yeniden okuması değil, daha kısa yeni bir satırdır: kendi boyunda
            // örtülür. FF7'de uzun cümleden sonra gelen "Hahaha..." ekran genişliğinde kara şerit alıyordu.
            var narrower = newLine && last is { } wide && box.Right - box.Left < (wide.Right - wide.Left) * NarrowerThan;
            if (last is { } previous && !narrower && at - lastAt <= HoldMs && Near(previous, box))
            {
                var union = previous.Union(box);
                var height = union.Bottom - union.Top;
                if (height <= Math.Max(box.Bottom - box.Top, 0.02) * MaxGrowth && height <= MaxHeight) result = union;
            }
            last = result;
            lastAt = at;
            return result;
        }
    }

    /// <summary>Kutular dikeyde üst üste biniyor ya da aralarında bir kutu yüksekliğinden az boşluk var.</summary>
    private static bool Near(TextBox a, TextBox b)
    {
        var gap = Math.Max(a.Top, b.Top) - Math.Min(a.Bottom, b.Bottom);
        return gap <= Math.Max(a.Bottom - a.Top, b.Bottom - b.Top);
    }
}
