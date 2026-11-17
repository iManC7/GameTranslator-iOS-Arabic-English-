// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Paket çevirisini yalnız oynanan oyunun paketi varken kullandırır. Paketler bütün oyunlarda aranır; başka oyunun
/// paketindeki kısa ve genel satırlar ("Yeah,", "Nope...", "Miles?") paketi olmayan oyunda da eşleşip o oyunun
/// çevirisini basıyordu ("Miles?" → "mil"). Kısa süre içinde birkaç uzun satır eşleşmedikçe oyunun paketi yok sayılır
/// ve eşleşmeler kullanılmaz; satır çeviri motoruna gider. Uzun eşleşmeler kesilirse (başka oyuna geçildi) kapı
/// yeniden kapanır. Aynı satır için birden çok kez çağrılabilir (sayım farklı satırlar üzerindendir).
/// </summary>
public sealed class PackGate(Func<long>? clock = null)
{
    /// <summary>Bu kadar sözcükten kısa satır genel sayılır; oyunu tanıtmaz.</summary>
    public const int LongLineWords = 5;
    /// <summary>Kapının açılması için <see cref="WindowMs"/> içinde eşleşmesi gereken farklı uzun satır sayısı.</summary>
    public const int LinesToOpen = 3;
    public const int WindowMs = 5 * 60 * 1000;
    /// <summary>Son uzun eşleşmeden bu kadar sonra kapı kapanır.</summary>
    public const int CloseAfterMs = 15 * 60 * 1000;

    private readonly Func<long> now = clock ?? (() => Environment.TickCount64);
    private readonly object gate = new();
    private readonly List<(string Line, long At)> recent = [];
    private long lastLong = long.MinValue;
    private bool open;

    /// <summary>Oynanan oyunun paketi var sayılıyor mu.</summary>
    public bool IsOpen { get { lock (gate) return open && now() - lastLong <= CloseAfterMs; } }

    /// <summary><paramref name="match"/> kullanılacaksa kendisi, oyunun paketi henüz belli değilse null.</summary>
    public PackMatch? Filter(string source, PackMatch? match)
    {
        if (match is null) return null;
        lock (gate)
        {
            var at = now();
            if (open && at - lastLong > CloseAfterMs)
            {
                open = false;
                recent.Clear();
            }
            // Konuşmacı adı sayılmaz: "Spider-Man: what got into you?" dört sözcüklük genel bir cümledir.
            var colon = source.IndexOf(':');
            var spoken = colon is > 1 and <= 30 && !source[..colon].Contains('\n') ? source[(colon + 1)..] : source;
            var line = TextMatch.Normalize(spoken);
            if (line.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length >= LongLineWords)
            {
                lastLong = at;
                recent.RemoveAll(entry => at - entry.At > WindowMs || entry.Line == line);
                recent.Add((line, at));
                if (recent.Count >= LinesToOpen) open = true;
            }
            return open ? match : null;
        }
    }
}
