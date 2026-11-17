// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class GarbageAndFragmentTests
{
    private static readonly HashSet<string> Words = new(StringComparer.OrdinalIgnoreCase)
    {
        "the", "bridge", "was", "built", "long", "before", "any", "of", "us", "were", "born", "I", "do", "not", "care",
        "if", "they", "call", "me", "a", "fool", "there", "used", "to", "be", "many", "and", "we", "also", "crossed", "river",
    };

    private static readonly Misspelling Spelling = new(Words.Contains);

    [Theory]
    [InlineData("The bridge was built long before any of us were born.", false)]
    // Tek tük bozuk sözcüğü olan uzun cümle çevrilir.
    [InlineData("I do not carif they call me a fool.", false)]
    // Sözcüklerinin çoğu gerçek olmayan okuma çevrilmez.
    [InlineData("There Ogedto egey brilor f ug.", true)]
    [InlineData("woat we hed, Awe bandd togethersl", true)]
    [InlineData("OK", false)]
    public void HeavilyMisspelledReadingIsGarbage(string text, bool garbage) => Assert.Equal(garbage, Spelling.IsGarbage(text));

    [Theory]
    // Önceki satır cümlesini bitirmiş: küçük harfle başlayan satır başı okunamamış parçadır.
    [InlineData("and we also crossed the river.", "The bridge was built long before.", true)]
    [InlineData("born.", "There used to be many of us!", true)]
    [InlineData("of us were born.", null, true)]
    // Önceki satır açık kalmış: devamdır.
    [InlineData("and we also crossed the river.", "The bridge was built long before,", false)]
    [InlineData("who were born there.", "There used to be many of us...", false)]
    [InlineData("before any of us", "The bridge was built long", false)]
    // Büyük harfle ya da konuşmacı adıyla başlayan satır parça değildir.
    [InlineData("The bridge was built.", "I do not care.", false)]
    [InlineData("Elena: and we crossed.", "I do not care.", false)]
    public void LowercaseStartAfterAFinishedSentenceIsAFragment(string text, string? previous, bool fragment) =>
        Assert.Equal(fragment, Misspelling.IsOrphanFragment(text, previous));

    [Fact]
    public async Task GarbageIsNotTranslated()
    {
        var sender = new FakeSender();
        var pipeline = new SubtitlePipeline(
            new FakeReader("Xqzt vrrb klmn pqrs.", "Xqzt vrrb klmn pqrs.", "Xqzt vrrb klmn pqrs.", "Hold the gate.", "Hold the gate."),
            new FakeTranslator(), sender) { IsGarbage = text => text.StartsWith("Xqzt", StringComparison.Ordinal) };
        var log = new List<string>();
        pipeline.Log = log.Add;
        for (var i = 0; i < 5; i++)
        {
            await pipeline.ProcessAsync(Frame.Blank(64, 64), new CropRegion());
            await pipeline.WaitForTranslationsAsync();
        }
        Assert.Equal(["TR: Hold the gate."], sender.Sent);
        Assert.Contains(log, line => line.StartsWith("çöp: \"Xqzt vrrb klmn pqrs.\"", StringComparison.Ordinal));
    }
}

public class ContinuationMisreadTests
{
    private sealed class Recorder : ITextTranslator
    {
        public List<string> Seen { get; } = [];
        public Task<string> TranslateAsync(string text, CancellationToken cancellationToken = default)
        {
            Seen.Add(text);
            return Task.FromResult("tr:" + text);
        }
    }

    [Fact]
    public async Task MisreadPiecesAreNotChained()
    {
        long time = 0;
        var recorder = new Recorder();
        var translator = new ContinuationTranslator(recorder, () => time, text => text.Contains("zz", StringComparison.Ordinal));
        foreach (var text in new[] { "ehzz of hopzz and even", "eazz of hopefzz nd", "and then we walked home" })
        {
            await translator.TranslateAsync(text);
            time += 1500;
        }
        Assert.Equal(["ehzz of hopzz and even", "eazz of hopefzz nd", "and then we walked home"], recorder.Seen);
    }
}
