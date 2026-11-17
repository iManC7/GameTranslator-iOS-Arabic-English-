// SPDX-License-Identifier: AGPL-3.0-only

using System.Text;
using System.Text.RegularExpressions;

namespace GameTranslator.Core;

/// <summary>
/// PS5'te o an çalışan oyun: keşif yanıtındaki <c>running-app-titleid</c> ve <c>running-app-name</c>. Ortak havuza giden
/// satıra eklenir; yeni bir oyun (ör. GTA 6) çıkınca o oyunun satırları ayrı toplanıp hızla paket yapılır. Yalnız oyunun
/// kimliği ve adı gider. Mac'teki GameTranslatorCore/RunningGame.swift ile aynı kurallar (sunucu da aynısını doğrular).
/// </summary>
public sealed partial record RunningGame(string TitleId, string? Name)
{
    public const int MaxName = 120;

    [GeneratedRegex(@"^[A-Z]{4}\d{5}(_\d{2})?$")]
    private static partial Regex TitleIdPattern();

    /// <summary>Kimlik PS5 biçiminde değilse null.</summary>
    public static RunningGame? Create(string? titleId, string? name)
    {
        var id = titleId?.Trim().ToUpperInvariant();
        if (id is null || !TitleIdPattern().IsMatch(id)) return null;
        return new RunningGame(id, NormalizedName(name));
    }

    /// <summary>Denetim karakterleri ve fazla boşluk atılır, en çok 120 karakter; boşsa null.</summary>
    internal static string? NormalizedName(string? value)
    {
        if (value is null) return null;
        var builder = new StringBuilder(value.Length);
        foreach (var rune in value.EnumerateRunes())
        {
            var category = Rune.GetUnicodeCategory(rune);
            builder.Append(category is System.Globalization.UnicodeCategory.Control or System.Globalization.UnicodeCategory.Format
                ? " " : rune.ToString());
        }
        var words = string.Join(' ', builder.ToString().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
        var trimmed = (words.Length > MaxName ? words[..MaxName] : words).Trim();
        return trimmed.Length == 0 ? null : trimmed;
    }
}
