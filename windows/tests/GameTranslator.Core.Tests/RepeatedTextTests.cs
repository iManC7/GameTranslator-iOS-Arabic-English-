// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Core;
using Xunit;

namespace GameTranslator.Core.Tests;

public class RepeatedTextTests
{
    private static Reading Read(params string[] lines) => new(lines.Select(line => new TextLine(line, null)));

    [Fact]
    public void LineShownThreeTimesWithoutSentenceEndIsInterface()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        const string bar = "Pick up Select Actions Sort Tooltips Close";
        Assert.Null(repeats.Note(bar));
        time += 8000;
        Assert.Null(repeats.Note(bar));
        Assert.Equal(bar, repeats.Without(Read(bar)).Text);
        time += 8000;
        Assert.Equal(bar, repeats.Note(bar));
        Assert.Equal("", repeats.Without(Read(bar)).Text);
        // Aynı okumadaki konuşma satırı kalır.
        Assert.Equal("We must go to the helm.", repeats.Without(Read(bar, "We must go to the helm.")).Text);
    }

    /// Tümü büyük harfli reklam ya da pano yazısı ünlemle bitse de yinelenince engellenir.
    [Fact]
    public void UppercaseBillboardIsBlockedWhenRepeated()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        for (var i = 0; i < RepeatedText.Times; i++)
        {
            repeats.Note("GET YOURS: TODAY!");
            time += 3000;
        }
        Assert.Equal("", repeats.Without(Read("GET YOURS: TODAY!")).Text);
    }

    [Fact]
    public void SpokenLinesMayRepeat()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        foreach (var line in new[] { "Behind you!", "Mimir: Behind you", "Hold the line." })
        {
            for (var i = 0; i < 6; i++)
            {
                Assert.Null(repeats.Note(line));
                time += 3000;
            }
            Assert.Equal(line, repeats.Without(Read(line)).Text);
        }
    }

    [Fact]
    public void RepeatsFarApartDoNotCount()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        for (var i = 0; i < 6; i++)
        {
            Assert.Null(repeats.Note("Bonus Action Movement"));
            time += RepeatedText.WindowMs;
        }
    }

    [Fact]
    public void BlockEndsAfterAWhile()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        for (var i = 0; i < RepeatedText.Times; i++) repeats.Note("Bonus Action Movement");
        Assert.Equal("", repeats.Without(Read("Bonus Action Movement")).Text);
        time += RepeatedText.BlockMs + 1;
        Assert.Equal("Bonus Action Movement", repeats.Without(Read("Bonus Action Movement")).Text);
    }

    [Fact]
    public void OnlyTheRepeatedLineOfATwoLineSourceIsBlocked()
    {
        long time = 0;
        var repeats = new RepeatedText(() => time);
        for (var i = 0; i < RepeatedText.Times; i++)
        {
            repeats.Note($"Talus used Main Hand\nLine number {i} is new.");
            time += 4000;
        }
        Assert.Equal("Line number 9 is new.", repeats.Without(Read("Talus used Main Hand", "Line number 9 is new.")).Text);
    }
}
