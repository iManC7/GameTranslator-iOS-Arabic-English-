// SPDX-License-Identifier: AGPL-3.0-only
// CouchSubs (Copyright (C) 2026 Sinan Yorulmaz) core/Sources/CouchSubsCore/ManualAddress.swift'ın C# karşılığı (4c1f6ec).

namespace GameTranslator.Core;

/// <summary>
/// Elle yazılan PS5 ya da TV adresi. Kullanıcılar "192.168.1.5:3000", "http://192.168.1.5", sonda boşluk ya da (Türkçe
/// sayı klavyesinde nokta olmadığı için) "192,168,1,5" yazıyordu; böyle bir adresle kurulan bağlantı adresi geçersiz
/// çıkıp bağlantıyı kurmadan bitiyordu. Adres burada temizlenir; temizlendikten sonra da adres olmayan giriş reddedilir.
/// </summary>
public static class ManualAddress
{
    /// <summary>
    /// Baştaki/sondaki boşluk, "http://" gibi önek, ":3000" gibi port ve "/..." yolu atılır, virgüller noktaya döner.
    /// IPv4 (dört 0–255 parça) ya da ağ adı (ör. "lgwebostv.local") kabul edilir; başka her şey null.
    /// </summary>
    public static string? Normalize(string? input)
    {
        var text = (input ?? "").Trim().Replace(',', '.');
        var scheme = text.IndexOf("://", StringComparison.Ordinal);
        if (scheme >= 0) text = text[(scheme + 3)..];
        var end = text.IndexOfAny(['/', '?', '#']);
        if (end >= 0) text = text[..end];
        var parts = text.Split(':');
        // Tek iki nokta port ayırır; daha fazlası IPv6'dır (TV'ler IPv4 adresiyle eşleşir).
        if (parts.Length == 2)
        {
            if (parts[1].Length == 0 || !parts[1].All(char.IsAsciiDigit)) return null;
            text = parts[0];
        }
        else if (parts.Length > 2)
        {
            return null;
        }
        if (text.EndsWith('.')) text = text[..^1];
        if (text.Length == 0) return null;
        if (text.All(c => char.IsAsciiDigit(c) || c == '.')) return Ipv4(text);
        return IsHostName(text) ? text.ToLowerInvariant() : null;
    }

    private static string? Ipv4(string text)
    {
        var octets = text.Split('.');
        if (octets.Length != 4) return null;
        var values = new int[4];
        for (var i = 0; i < 4; i++)
        {
            if (octets[i].Length is < 1 or > 3 || !int.TryParse(octets[i], out var value) || value > 255) return null;
            values[i] = value;
        }
        return string.Join('.', values);
    }

    /// <summary>Harf, rakam ve tireden oluşan, en az bir harf içeren etiketler (RFC 1123).</summary>
    private static bool IsHostName(string text) =>
        text.Length <= 253 && text.Any(char.IsAsciiLetter)
        && text.Split('.').All(label => label.Length is >= 1 and <= 63 && label[0] != '-' && label[^1] != '-'
                                        && label.All(c => char.IsAsciiLetterOrDigit(c) || c == '-'));
}
