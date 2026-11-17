// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class SpeakerMergeTests
{
    private static Reading Read(params string[] lines) =>
        new(lines.Select((text, row) => new TextLine(text, new TextBox(0.3, 0.1 * row, 0.7, (0.1 * row) + 0.05))));

    [Fact]
    public void ColoredSpeakerNameIsTakenFromTheOtherReading()
    {
        var merged = SpeakerMerge.WithSpeakerFrom(Read("I know, I know!"), Read("Ganke: I know, I now!"));
        Assert.Equal("Ganke: I know, I know!", merged.Text);

        var twoLines = SpeakerMerge.WithSpeakerFrom(
            Read("I got it, you're gonna be safe.", "Just hold on."), Read("Spider-Man: Igot it, you're gonna be safe.", "Just hold on."));
        Assert.Equal("Spider-Man: I got it, you're gonna be safe.\nJust hold on.", twoLines.Text);
    }

    [Fact]
    public void ReadingIsLeftAloneWhenItHasANameOrTheOtherSaysSomethingElse()
    {
        Assert.Equal("Ganke: wait!", SpeakerMerge.WithSpeakerFrom(Read("Ganke: wait!"), Read("Ggnke: ait!")).Text);
        Assert.Equal("Almost there...", SpeakerMerge.WithSpeakerFrom(Read("Almost there..."), Read("Sandman: Leave me alone!")).Text);
        Assert.Equal("Thank you.", SpeakerMerge.WithSpeakerFrom(Read("Thank you."), Read("Thank you.")).Text);
        Assert.Equal("", SpeakerMerge.WithSpeakerFrom(Reading.Empty, Read("Ganke: wait!")).Text);
    }
}

public class MisspellingTests
{
    private static readonly HashSet<string> Words = new(StringComparer.OrdinalIgnoreCase)
    {
        "I've", "got", "you", "hold", "on", "it", "you're", "gonna", "be", "safe", "try", "a", "workaround", "what's",
        "happening", "to", "the", "requests", "can't", "don't", "stop", "us", "we", "more", "of", "that", "are", "coming", "in", "need", "your", "help", "wait",
    };

    private static readonly Misspelling Spelling = new(Words.Contains);

    [Theory]
    [InlineData("I've got you! Hold on!", false)]
    [InlineData("IVe got ou! Hold on!", true)]
    [InlineData("Kirkitrustimlikeobrother.", true)]
    [InlineData("Wait, Kephallonia.", false)]
    [InlineData("Igot it, you're gonna be safe.", true)]
    [InlineData("I'm gonnatry workaroun.", true)]
    [InlineData("What sh ppening to the equ Sts that are coming in?", true)]
    // Özel adlar ve kısaltmalar yanlış sayılmaz.
    [InlineData("Kraven: I need your help.", false)]
    [InlineData("Ganke: wait!", false)]
    [InlineData("MJ: Hold on!", false)]
    [InlineData("...", false)]
    // Kesme işareti okunmayan kısaltmalar her karede aynı okunur; beklemek düzeltmez.
    [InlineData("You cant stop us, we dont need help!", false)]
    [InlineData("More of em coming, cmon!", false)]
    public void FlagsWordsThatAreNotWords(string text, bool misread) => Assert.Equal(misread, Spelling.LooksMisread(text));

    [Fact]
    public void CleanReadingScoresHigherThanAGarbledOne()
    {
        Assert.True(Spelling.Score("I've got you! Hold on!") > Spelling.Score("IVe got ou! Hold on!"));
        Assert.True(Spelling.Score("I'm gonna try a workaround.") > Spelling.Score("I'm gonnatry workaroun."));
    }
}

public class PackGateSpeakerTests
{
    [Fact]
    public void SpeakerNameDoesNotMakeAShortLineLong()
    {
        long time = 0;
        var gate = new PackGate(() => time);
        var hit = new PackMatch("çeviri", []);
        foreach (var line in new[] { "Spider-Man: what got into you?", "Spider-Man: There they are.", "Trapped Civilian: I am now.", "Spider-Man: What's the plan?" })
        {
            Assert.Null(gate.Filter(line, hit));
            time += 10_000;
        }
        Assert.False(gate.IsOpen);
    }
}
