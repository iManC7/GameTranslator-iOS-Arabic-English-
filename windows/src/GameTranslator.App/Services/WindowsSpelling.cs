// SPDX-License-Identifier: AGPL-3.0-only

using System.Collections.Concurrent;
using System.Runtime.InteropServices;

namespace GameTranslator.App.Services;

/// <summary>
/// Windows'un yazım denetimi (ISpellChecker, Windows 8+): bir sözcük oyun dilinde gerçek mi. Dilin yazım sözlüğü
/// yüklü değilse <see cref="Create"/> null döner ve denetim yapılmaz. Sonuçlar bellekte tutulur (aynı sözcükler
/// sürekli sorulur). COM nesnesi iş parçacığı havuzunda oluşturulur ve bir kilitle kullanılır.
/// </summary>
public sealed class WindowsSpelling
{
    private readonly ISpellChecker checker;
    private readonly object gate = new();
    private readonly ConcurrentDictionary<string, bool> known = new(StringComparer.Ordinal);

    private WindowsSpelling(ISpellChecker checker) => this.checker = checker;

    public static WindowsSpelling? Create(string language)
    {
        try
        {
            return Task.Run(() =>
            {
                var factory = (ISpellCheckerFactory)new SpellCheckerFactoryClass();
                foreach (var tag in new[] { language, language == "en" ? "en-US" : language, language == "en" ? "en-GB" : language }.Distinct())
                    if (factory.IsSupported(tag)) return new WindowsSpelling(factory.CreateSpellChecker(tag)) { english = language.StartsWith("en", StringComparison.OrdinalIgnoreCase) };
                return null;
            }).GetAwaiter().GetResult();
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Yaygın İngilizce sözcükler (SCOWL/ESDB 60 boyutu, küçük harf; Assets\english-words.txt.gz). Windows'un sözlüğü
    /// çok geniş: yazı tanımanın uydurduğu "nauch", "reis", "todo", "fi" gibi okumaları da kabul ediyor; o zaman bozuk
    /// okuma fark edilmiyor ve onarılmıyordu. Oyun dili İngilizceyse sözcük her iki sözlükte de olmalı. Liste
    /// yüklenemezse yalnız Windows'a sorulur.
    /// </summary>
    private static readonly Lazy<HashSet<string>?> English = new(LoadEnglish);

    private static HashSet<string>? LoadEnglish()
    {
        try
        {
            using var stream = typeof(WindowsSpelling).Assembly.GetManifestResourceStream("GameTranslator.App.Assets.english-words.txt.gz");
            if (stream is null) return null;
            using var unzip = new System.IO.Compression.GZipStream(stream, System.IO.Compression.CompressionMode.Decompress);
            using var reader = new System.IO.StreamReader(unzip);
            var words = new HashSet<string>(StringComparer.Ordinal);
            while (reader.ReadLine() is { } line) if (line.Length > 0) words.Add(line);
            return words;
        }
        catch
        {
            return null;
        }
    }

    private bool english;

    /// <summary>Sözcük yaygın İngilizce sözcük listesinde mi ("'s", sonu düşmüş "-ing" ve tireli parçalar dahil).</summary>
    internal static bool InEnglishList(HashSet<string> words, string word)
    {
        var lower = word.ToLowerInvariant().Replace('’', '\'');
        if (words.Contains(lower)) return true;
        if (lower.EndsWith("'s", StringComparison.Ordinal) && words.Contains(lower[..^2])) return true;
        if (lower.EndsWith("s'", StringComparison.Ordinal) && words.Contains(lower[..^1])) return true;
        if (lower.EndsWith("in'", StringComparison.Ordinal) && words.Contains(lower[..^1] + "g")) return true;
        if (lower.EndsWith("in", StringComparison.Ordinal) && lower.Length > 4 && words.Contains(lower + "g")) return true;
        if (lower.Contains('-')) return lower.Split('-').All(part => part.Length == 0 || words.Contains(part));
        return false;
    }

    public bool IsWord(string word)
    {
        if (known.TryGetValue(word, out var cached)) return cached;
        bool result;
        try
        {
            lock (gate)
            {
                var errors = checker.Check(word);
                result = errors.Next(out var error) != 0 || error is null;
            }
            if (result && english && English.Value is { } list) result = InEnglishList(list, word);
        }
        catch
        {
            // Denetim çalışmazsa sözcük doğru sayılır; satır her zamanki gibi çevrilir.
            result = true;
        }
        if (known.Count > 20000) known.Clear();
        known[word] = result;
        return result;
    }

    [ComImport, Guid("8E018A9D-2415-4677-BF08-794EA61F94BB"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface ISpellCheckerFactory
    {
        [return: MarshalAs(UnmanagedType.Interface)] object SupportedLanguages();
        [return: MarshalAs(UnmanagedType.Bool)] bool IsSupported([MarshalAs(UnmanagedType.LPWStr)] string languageTag);
        [return: MarshalAs(UnmanagedType.Interface)] ISpellChecker CreateSpellChecker([MarshalAs(UnmanagedType.LPWStr)] string languageTag);
    }

    [ComImport, Guid("B6FD0B71-E2BC-4653-8D05-F197E412770B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface ISpellChecker
    {
        [return: MarshalAs(UnmanagedType.LPWStr)] string LanguageTag();
        [return: MarshalAs(UnmanagedType.Interface)] IEnumSpellingError Check([MarshalAs(UnmanagedType.LPWStr)] string text);
    }

    [ComImport, Guid("803E3BD4-2828-4410-8290-418D1D73C762"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IEnumSpellingError
    {
        [PreserveSig] int Next([MarshalAs(UnmanagedType.Interface)] out object? value);
    }

    [ComImport, Guid("7AB36653-1796-484B-BDFA-E74F1DB7C1DC")]
    private class SpellCheckerFactoryClass;
}
