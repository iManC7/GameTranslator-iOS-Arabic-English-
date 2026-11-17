// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class SpeakerLineTests
{
    private static Reading Read(params string[] lines) =>
        new(lines.Select((text, row) => new TextLine(text, new TextBox(0.3, 0.1 * row, 0.7, (0.1 * row) + 0.05))));

    [Fact]
    public void NameOnItsOwnLineJoinsTheSpeech()
    {
        Assert.Equal("ELENA: We have no choice but to try!", Read("ELENA", "We have no choice but to try!").WithSpeakerLine().Text);
        Assert.Equal("YOUNG TOMAS: I can tell from the look on your face\nthat you were paid.",
            Read("YOUNG TOMAS", "I can tell from the look on your face", "that you were paid.").WithSpeakerLine().Text);
        // Kutu adı da kapsar (TV'de çeviri adın üstünü de örtsün).
        Assert.Equal(0.0, Read("ELENA", "Run!").WithSpeakerLine().Lines[0].Box!.Value.Top);
    }

    /// Baş harfi büyük ad ("Sojiro") yalnız sözün sol üstündeki kendi kutusundaysa ve söz yeni cümleyle başlıyorsa addır.
    [Fact]
    public void TitleCaseNameAboveTheSpeechJoinsIt()
    {
        static Reading Boxed(params (string Text, double Left, double Right)[] lines) =>
            new(lines.Select((line, row) => new TextLine(line.Text, new TextBox(line.Left, 0.1 * row, line.Right, (0.1 * row) + 0.05))));
        Assert.Equal("Sojiro: You'll be alone at night.\nDon't do anything stupid.",
            Boxed(("Sojiro", 0.20, 0.30), ("You'll be alone at night.", 0.22, 0.70), ("Don't do anything stupid.", 0.22, 0.65)).WithSpeakerLine().Text);
        // Ortalı iki satırlık altyazı, ünlem ya da küçük harfle süren cümle ad değildir.
        Assert.Equal("Sojiro\nI know.", Boxed(("Sojiro", 0.45, 0.55), ("I know.", 0.46, 0.54)).WithSpeakerLine().Text);
        Assert.Equal("Yeah\nI know what you did.", Boxed(("Yeah", 0.20, 0.28), ("I know what you did.", 0.21, 0.70)).WithSpeakerLine().Text);
        Assert.Equal("Sojiro\nwill be taking care of me.", Boxed(("Sojiro", 0.20, 0.30), ("will be taking care of me.", 0.21, 0.70)).WithSpeakerLine().Text);
        // İki sözcüklü ad ve sonda okunmuş nokta.
        Assert.Equal("Tifa's Dad: You can still back out.", Boxed(("Tifa's Dad", 0.30, 0.40), ("You can still back out.", 0.31, 0.70)).WithSpeakerLine().Text);
        Assert.Equal("Barret: Our reasons, huh?", Boxed(("Barret.", 0.30, 0.37), ("Our reasons, huh?", 0.31, 0.70)).WithSpeakerLine().Text);
    }

    [Fact]
    public void OrdinaryLinesAreLeftAlone()
    {
        Assert.Equal("Elena: Run!\nNow!", Read("Elena: Run!", "Now!").WithSpeakerLine().Text);
        Assert.Equal("WAIT!\nNot yet.", Read("WAIT!", "Not yet.").WithSpeakerLine().Text);
        Assert.Equal("ELENA", Read("ELENA").WithSpeakerLine().Text);
        Assert.Equal("SORT BY\nCATEGORY", Read("SORT BY", "CATEGORY").WithSpeakerLine().Text);
    }

    [Theory]
    [InlineData("Engraving Challenges", true)]
    [InlineData("Honoring the Dead", true)]
    [InlineData("SORT BY: CATEGORY", true)]
    [InlineData("LEVEL 2", true)]
    [InlineData("ACHAIA", true)]
    [InlineData("19m", true)]
    [InlineData("12 m", true)]
    [InlineData("I am 12.", false)]
    [InlineData("Thank you", false)]
    [InlineData("Hold the gate", false)]
    [InlineData("Run!", false)]
    [InlineData("ELENA: We have no choice but to try!", false)]
    [InlineData("I can tell from the look on your face", false)]
    [InlineData("Yeah", false)]
    public void HeadingsAreRecognized(string text, bool heading) => Assert.Equal(heading, Reading.IsHeading(text));

    [Fact]
    public void ReadingMadeOnlyOfHeadingsIsDropped()
    {
        Assert.Equal("", Read("TIES &", "ACTS (0)").WithoutHeadings().Text);
        Assert.Equal("", Read("Secondary Interact").WithoutHeadings().Text);
        Assert.Equal("ELENA: Run!", Read("ELENA", "Run!").WithSpeakerLine().WithoutHeadings().Text);
        Assert.Equal("Engraving Challenges\nYou have to see this.", Read("Engraving Challenges", "You have to see this.").WithoutHeadings().Text);
    }
}
