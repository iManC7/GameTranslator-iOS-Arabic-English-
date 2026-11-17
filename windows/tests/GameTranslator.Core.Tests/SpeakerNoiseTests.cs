// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

/// <summary>Konuşmacı adının çevresindeki okuma artıkları ve cümle sonundaki kısa çöpler.</summary>
public class SpeakerNoiseTests
{
    [Fact]
    public void JunkAroundAKnownSpeakerNameIsRemoved()
    {
        OcrNoise.ForgetSpeakers();
        OcrNoise.Clean("ANNA: Let us go.");
        OcrNoise.Clean("ANNA: Stay close.");
        Assert.Equal("ANNA: Careful!", OcrNoise.Clean("'ANNA: Careful!"));
        Assert.Equal("ANNA: Got another one!", OcrNoise.Clean("--—ANNA: Got another one!"));
        Assert.Equal("ANNA: Look, maybe you should come back?", OcrNoise.Clean("j ANNA: Look, maybe you should come back?"));
        // Başına tek harf yapışmış ad.
        Assert.Equal("ANNA: Is this why the zone is closed?", OcrNoise.Clean("IANNA: Is this why the zone is closed?"));
        Assert.Equal("ANNA: What do we do now?!", OcrNoise.Clean("JANNA: What do we do now?!"));
        // Önünde gerçek bir sözcük varsa dokunulmaz.
        Assert.Equal("No ANNA: wait.", OcrNoise.Clean("No ANNA: wait."));
        OcrNoise.ForgetSpeakers();
    }

    [Theory]
    [InlineData("I am not imagining things, right?! i 'o/", "I am not imagining things, right?!")]
    [InlineData("They are chasing that train, too! t)", "They are chasing that train, too!")]
    [InlineData("Are you all right? 'NV", "Are you all right?")]
    // Cümleden sonra gelen gerçek sözcükler kalır.
    [InlineData("Really? No", "Really? No")]
    [InlineData("Wait... what?", "Wait... what?")]
    [InlineData("It is over. Go!", "It is over. Go!")]
    public void ShortJunkAfterTheSentenceEndIsRemoved(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));
}

public class BareRereadTests
{
    /// <summary>Kaynağa benzemeyen bir çeviri verir.</summary>
    private sealed class Turkish : ITextTranslator
    {
        public Task<string> TranslateAsync(string text, CancellationToken cancellationToken = default) =>
            Task.FromResult(text.StartsWith("ANNA:", StringComparison.Ordinal) ? "ANNA: Hemen yukarı çık!" : text.Contains("Come") ? "Hemen yukarı gelin!" : "Burada bekle.");
    }

    /// Ad kareden kareye görünüp kaybolurken araya başka okumalar girse de adsız hâli yeniden çevrilmez.
    [Fact]
    public async Task BareRereadAfterOtherReadingsIsStillTheSameLine()
    {
        var sender = new FakeSender();
        var pipeline = new SubtitlePipeline(
            new FakeReader("ANNA: Come up now!", "ANNA: Come up now!", "Wait here.", "Wait here.", "Wait here.", "Come up now!", "Come up now!", "Come up now!"),
            new Turkish(), sender);
        var log = new List<string>();
        pipeline.Log = log.Add;
        pipeline.PackLookup = _ => null;
        pipeline.CleanWait = 0;
        pipeline.PackWait = 0;
        for (var i = 0; i < 8; i++)
        {
            await pipeline.ProcessAsync(Frame.Blank(64, 64), new CropRegion());
            await pipeline.WaitForTranslationsAsync();
        }
        Assert.True(!sender.Sent.Contains("Hemen yukarı gelin!"), $"gönderilen: [{string.Join(" | ", sender.Sent)}]\n{string.Join("\n", log)}");
        Assert.Contains("ANNA: Hemen yukarı çık!", sender.Sent);
        Assert.Contains(log, line => line.Contains("az önce konuşmacı adıyla çevrildi", StringComparison.Ordinal));
    }
}
