// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Altyazı şeridine düşen arayüz yazılarını davranışından tanır: konuşma satırı bir kez söylenir, arayüz yazısı
/// (envanter çubuğu "Pick up Select Actions Sort Close", savaş günlüğü, gösterge) kısa sürede aynen yinelenir ve cümle
/// gibi bitmez. Aynı satır <see cref="Times"/> kez çevrildiyse bir süre okumalardan çıkarılır. Cümle sonu işaretiyle
/// biten ya da "Ad:" ile başlayan satırlar yinelense de konuşmadır ("Behind you!"). Birden çok iş parçacığından
/// çağrılabilir.
/// </summary>
public sealed class RepeatedText(Func<long>? clock = null)
{
    /// <summary>Bu kadar yinelenen satır arayüzdür.</summary>
    public const int Times = 3;
    /// <summary>Yinelemeler bu süre içinde olmalı.</summary>
    public const int WindowMs = 5 * 60 * 1000;
    /// <summary>Arayüz sayılan satır bu kadar süre okunmaz.</summary>
    public const int BlockMs = 10 * 60 * 1000;

    private readonly Func<long> now = clock ?? (() => Environment.TickCount64);
    private readonly object gate = new();
    private readonly Dictionary<string, List<long>> shown = [];
    private readonly Dictionary<string, long> blockedUntil = [];

    /// <summary>Çevrilip gösterilen kaynak metni kaydeder; yeni engellenen satır varsa onu döner (günlük için).</summary>
    public string? Note(string source)
    {
        string? blocked = null;
        var at = now();
        lock (gate)
        {
            foreach (var line in source.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                if (LooksSpoken(line)) continue;
                var key = TextMatch.Normalize(line);
                if (key.Length < 4) continue;
                if (!shown.TryGetValue(key, out var times)) shown[key] = times = [];
                times.RemoveAll(time => at - time > WindowMs);
                times.Add(at);
                if (times.Count < Times) continue;
                blockedUntil[key] = at + BlockMs;
                shown.Remove(key);
                blocked ??= line;
            }
            if (shown.Count > 200) shown.Clear();
        }
        return blocked;
    }

    /// <summary>Arayüz sayılan satırlar çıkarılmış okuma.</summary>
    public Reading Without(Reading reading)
    {
        var at = now();
        lock (gate)
        {
            if (blockedUntil.Count == 0) return reading;
            foreach (var key in blockedUntil.Where(pair => pair.Value <= at).Select(pair => pair.Key).ToList()) blockedUntil.Remove(key);
            if (blockedUntil.Count == 0 || !reading.Lines.Any(line => blockedUntil.ContainsKey(TextMatch.Normalize(line.Text)))) return reading;
            return new Reading(reading.Lines.Where(line => !blockedUntil.ContainsKey(TextMatch.Normalize(line.Text))));
        }
    }

    /// <summary>Konuşma gibi mi: cümle sonu işaretiyle biter ya da "Ad: söz" biçimindedir.</summary>
    private static bool LooksSpoken(string line)
    {
        // Tümü büyük harfli satır (reklam panosu "GET YOURS: TODAY!", jenerik) ünlemle bitse de konuşma sayılmaz.
        var letters = line.Where(char.IsLetter).ToList();
        if (letters.Count >= 4 && letters.All(char.IsUpper)) return false;
        if (SubtitleStabilizer.EndsSentence(line)) return true;
        var colon = line.IndexOf(": ", StringComparison.Ordinal);
        return colon is >= 2 and <= 30 && char.IsUpper(line[0]);
    }
}
