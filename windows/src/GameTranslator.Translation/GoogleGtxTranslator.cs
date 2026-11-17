// SPDX-License-Identifier: AGPL-3.0-only

using System.Collections.Concurrent;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using GameTranslator.Core;

namespace GameTranslator.Translation;

/// <summary>
/// Ücretsiz ve sıfır kurulum gerektiren Google GTX Çeviri Motoru.
/// Hızlı bellek içi önbellekleme, çoklu yedek sunucu ve hız sınırlama korumasıyla kesintisiz Türkçe çeviri sağlar.
/// </summary>
public sealed class GoogleGtxTranslator : ITextTranslator
{
    private static readonly HttpClient SharedClient = new()
    {
        Timeout = TimeSpan.FromSeconds(4)
    };

    private static readonly ConcurrentDictionary<string, string> Cache = new(StringComparer.OrdinalIgnoreCase);
    private static readonly Regex PrefixRegex = new(@"^(?<prefix>(?:[-–—]+|>{1,3})\s*)", RegexOptions.Compiled);

    private readonly string _source;
    private readonly string _target;

    public GoogleGtxTranslator(string source = "en", string target = "tr")
    {
        _source = string.IsNullOrWhiteSpace(source) ? "en" : source.ToLowerInvariant();
        _target = string.IsNullOrWhiteSpace(target) ? "tr" : target.ToLowerInvariant();
    }

    public async Task<string> TranslateAsync(string text, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;
        var trimmed = text.Trim();

        // Konuşmacı işareti (>> veya -) varsa ayrıştır
        string prefix = "";
        var match = PrefixRegex.Match(trimmed);
        if (match.Success)
        {
            prefix = match.Groups["prefix"].Value;
            trimmed = trimmed[prefix.Length..].Trim();
            if (trimmed.Length == 0) return prefix;
        }

        trimmed = JoinWrappedLines(trimmed);

        // 1. Önbellek kontrolü (anında yanıt, 0 ağ gecikmesi)
        var cacheKey = $"{_source}->{_target}:{trimmed}";
        if (Cache.TryGetValue(cacheKey, out var cached))
        {
            return prefix + cached;
        }

        // 2. Çoklu Google uç noktalarını dene
        var endpoints = new[]
        {
            $"https://translate.googleapis.com/translate_a/single?client=gtx&sl={_source}&tl={_target}&dt=t&q={Uri.EscapeDataString(trimmed)}",
            $"https://translate.googleapis.com/translate_a/single?client=dict-chrome-ex&sl={_source}&tl={_target}&dt=t&q={Uri.EscapeDataString(trimmed)}",
            $"https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl={_source}&tl={_target}&q={Uri.EscapeDataString(trimmed)}"
        };

        foreach (var url in endpoints)
        {
            try
            {
                using var req = new HttpRequestMessage(HttpMethod.Get, url);
                req.Headers.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");

                using var resp = await SharedClient.SendAsync(req, cancellationToken);
                if (!resp.IsSuccessStatusCode) continue;

                var json = await resp.Content.ReadAsStringAsync(cancellationToken);
                var translated = ParseTranslationJson(json);

                if (!string.IsNullOrWhiteSpace(translated))
                {
                    Cache[cacheKey] = translated;
                    if (Cache.Count > 1000) Cache.Clear(); // Bellek sızıntısını önle
                    return prefix + translated;
                }
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch
            {
                // Bir sonraki yedek uç noktaya geç
            }
        }

        // Çeviri başarısız olduysa İngilizce metni Türkçe gibi gösterme, hata fırlatarak hattın yeniden denemesini sağla
        throw new TranslatorException(TranslatorStatus.EngineFailed);
    }

    /// <summary>
    /// Ekranda iki satıra sarılmış tek cümleyi ("...he was running\ndown Broadway...") tek satır yapar. Google satır
    /// sonunu cümle sonu sayıp her satırı ayrı çeviriyordu ("in no\ntime." → "...sokacaksınız\nzaman."). Sonraki satır
    /// konuşmacı işaretiyle (- ya da >>) başlıyorsa ayrı konuşmadır; satır sonu korunur.
    /// </summary>
    internal static string JoinWrappedLines(string text)
    {
        var lines = text.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (lines.Length < 2) return text;
        var joined = new StringBuilder(lines[0]);
        var previous = lines[0];
        foreach (var line in lines.Skip(1))
        {
            // Tire yalnız önceki satır cümleyi bitirdiyse konuşmacı işaretidir; yarım cümlenin ortasında okunan tire
            // yazı tanıma artığıdır ("There's a\n- locksmith up the street!") ve atılır.
            var finished = previous.TrimEnd('"', '\'', '”', '’', ' ') is { Length: > 0 } end && ".!?…".Contains(end[^1]);
            if (PrefixRegex.IsMatch(line) && finished) joined.Append('\n').Append(line);
            else joined.Append(' ').Append(PrefixRegex.Replace(line, ""));
            previous = line;
        }
        return joined.ToString();
    }

    private static string? ParseTranslationJson(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind == JsonValueKind.Array && doc.RootElement.GetArrayLength() > 0)
            {
                var first = doc.RootElement[0];
                if (first.ValueKind == JsonValueKind.Array)
                {
                    var sb = new StringBuilder();
                    foreach (var s in first.EnumerateArray())
                    {
                        if (s.ValueKind == JsonValueKind.Array && s.GetArrayLength() > 0)
                        {
                            var part = s[0].GetString();
                            if (!string.IsNullOrEmpty(part)) sb.Append(part);
                        }
                    }
                    var result = sb.ToString().Trim();
                    if (!string.IsNullOrEmpty(result)) return System.Net.WebUtility.HtmlDecode(result);
                }
                else if (first.ValueKind == JsonValueKind.String)
                {
                    var result = first.GetString()?.Trim();
                    if (!string.IsNullOrEmpty(result)) return System.Net.WebUtility.HtmlDecode(result);
                }
            }
        }
        catch { }

        return null;
    }
}
