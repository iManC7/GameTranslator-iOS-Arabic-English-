// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core;

/// <summary>
/// Aynı altyazı satırının art arda karelerdeki okumalarını sözcük sözcük birleştirir. Yazı tanımanın hatası kareden
/// kareye değişir: bir karede "Slop! The pack is here", ötekinde "Stop! The pock is here" okunur; hiçbiri tam doğru
/// değildir ama her sözcüğün doğrusu okumalardan birinde vardır. En iyi okuma temel alınır; onun gerçek sözcük
/// olmayan parçaları, aynı yerde gerçek sözcük okuyan başka bir okumadan tamamlanır. Gerçek sözcüğe dokunulmaz ve
/// sözcük sayısı farklı okumalar kullanılmaz (hizası belirsizdir); bu yüzden birleştirme yeni hata üretmez.
/// </summary>
public static class ReadingConsensus
{
    /// <param name="best">Temel alınan okuma (en yüksek puanlı).</param>
    /// <param name="readings">Aynı satırın bütün okumaları (<paramref name="best"/> dahil olabilir).</param>
    /// <param name="isWord">Parça gerçek bir sözcük mü (yazım denetimi); null ise birleştirme yapılmaz.</param>
    public static string Merge(string best, IReadOnlyList<string> readings, Func<string, bool>? isWord)
    {
        if (isWord is null || readings.Count < 2) return best;
        var rows = best.Split('\n');
        var others = readings.Where(reading => reading != best).Select(reading => reading.Split('\n'))
            .Where(candidate => candidate.Length == rows.Length).ToList();
        if (others.Count == 0) return best;
        var changed = false;
        for (var row = 0; row < rows.Length; row++)
        {
            var words = rows[row].Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var aligned = others.Select(candidate => candidate[row].Split(' ', StringSplitOptions.RemoveEmptyEntries))
                .Where(candidate => candidate.Length == words.Length).ToList();
            if (aligned.Count == 0) continue;
            for (var index = 0; index < words.Length; index++)
            {
                if (IsGood(words[index], isWord)) continue;
                // Aynı yerde gerçek sözcük okuyan okumalardan en çok tekrar edeni.
                var better = aligned.Select(candidate => candidate[index]).Where(word => IsGood(word, isWord) && Close(word, words[index]))
                    .GroupBy(word => word).OrderByDescending(group => group.Count()).FirstOrDefault()?.Key;
                if (better is null) continue;
                words[index] = better;
                changed = true;
            }
            rows[row] = string.Join(' ', words);
        }
        return changed ? string.Join('\n', rows) : best;
    }

    /// <summary>Parçanın harf kısmı gerçek bir sözcük mü; harfsiz parçalar (sayı, işaret) ve özel adlar iyi sayılır.</summary>
    private static bool IsGood(string token, Func<string, bool> isWord)
    {
        var start = 0;
        var end = token.Length;
        while (start < end && !char.IsLetter(token[start])) start++;
        while (end > start && !char.IsLetter(token[end - 1])) end--;
        var word = token[start..end];
        if (word.Count(char.IsLetter) < 2) return true;
        var proper = char.IsUpper(word[0]) && word.Skip(1).Where(char.IsLetter).All(char.IsLower);
        var acronym = word.All(c => !char.IsLetter(c) || char.IsUpper(c));
        return acronym || isWord(word) || (proper && !word.Skip(1).Any(c => !char.IsLetter(c) && c != '\'' && c != '’' && c != '-'));
    }

    /// <summary>İki parça aynı sözcüğün okumaları olacak kadar yakın mı (boyları ve harfleri benzer).</summary>
    private static bool Close(string a, string b)
    {
        if (Math.Abs(a.Length - b.Length) > 2) return false;
        var (x, y) = (TextMatch.Normalize(a), TextMatch.Normalize(b));
        return x.Length > 0 && y.Length > 0 && TextMatch.IsSimilar(x, y, 0.5);
    }
}
