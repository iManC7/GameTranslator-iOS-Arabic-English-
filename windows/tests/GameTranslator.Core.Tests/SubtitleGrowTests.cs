// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class SubtitleGrowTests
{
    /// <summary>Okunan alan: ekranın %66–%99'u, yatayda %8–%92.</summary>
    private static readonly TextBox Area = new(0.08, 0.66, 0.92, 0.99);
    private static readonly (double Top, double Bottom) Band = (0.74, 0.89);

    /// <summary>Karede ortası (<paramref name="x"/>, <paramref name="y"/>) olan satır; kutu okunan alana göre verilir.</summary>
    private static TextLine Line(string text, double y, double x = 0.5, double width = 0.4)
    {
        double Across(double value) => (value - Area.Left) / (Area.Right - Area.Left);
        double Down(double value) => (value - Area.Top) / (Area.Bottom - Area.Top);
        return new TextLine(text, new TextBox(Across(x - (width / 2)), Down(y - 0.0125), Across(x + (width / 2)), Down(y + 0.0125)));
    }

    [Fact]
    public void LinesBelowTheBandThatContinueTheSubtitleAreKept()
    {
        var reading = new Reading([
            Line("Elena: You have been chasing this dream for years,", 0.82),
            Line("and I have stood by you through all of it, but", 0.86),
            Line("can you not see what it is doing to us?", 0.90),
            Line("To move quietly, stay low.", 0.97, width: 0.3)]);
        var grown = SubtitleFinder.Grow(reading, Area, Band);
        Assert.Equal(3, grown.Lines.Count);
        Assert.EndsWith("doing to us?", grown.Lines[^1].Text);
    }

    [Fact]
    public void SpeakerNameAboveTheBandIsKept()
    {
        var reading = new Reading([Line("ELENA", 0.725, width: 0.06), Line("We leave at dawn.", 0.76, width: 0.2)]);
        Assert.Equal("ELENA\nWe leave at dawn.", SubtitleFinder.Grow(reading, Area, Band).Text);
    }

    [Fact]
    public void TextAwayFromTheBandIsDropped()
    {
        var reading = new Reading([
            Line("Objective: reach the tower", 0.70, x: 0.2, width: 0.2),
            Line("Tomas: Keep your head down.", 0.82),
            Line("Press and hold to aim.", 0.96, x: 0.5, width: 0.25)]);
        Assert.Equal("Tomas: Keep your head down.", SubtitleFinder.Grow(reading, Area, Band).Text);
    }

    /// Şeritle aynı yükseklikteki köşe yazısı (sağ alttaki tuş ipuçları) altyazı değildir.
    [Fact]
    public void CornerTextAtTheBandHeightIsDropped()
    {
        var reading = new Reading([
            Line("Geralt: Ground's black, saturated with blood.", 0.82),
            Line("Witcher Senses Hold", 0.80, x: 0.86, width: 0.1),
            Line("Call Horse Press Twice!", 0.84, x: 0.86, width: 0.1)]);
        Assert.Equal("Geralt: Ground's black, saturated with blood.", SubtitleFinder.Grow(reading, Area, Band).Text);
        Assert.Equal("", SubtitleFinder.Grow(new Reading([Line("Call Horse Press Twice!", 0.84, x: 0.86, width: 0.1)]), Area, Band).Text);
    }

    [Fact]
    public void NothingInTheBandMeansNoSubtitle()
    {
        var reading = new Reading([Line("Press and hold to aim.", 0.96, width: 0.25)]);
        Assert.Equal("", SubtitleFinder.Grow(reading, Area, Band).Text);
        Assert.Equal("", SubtitleFinder.Grow(Reading.Empty, Area, Band).Text);
    }

    [Fact]
    public async Task PipelineAppliesTheLineFilter()
    {
        var sender = new FakeSender();
        var reading = new Reading([Line("Tomas: Keep your head down.", 0.82), Line("Press and hold to aim.", 0.96, width: 0.25)]);
        var pipeline = new SubtitlePipeline(new LinesReader(reading), new FakeTranslator(), sender)
            { LineFilter = (read, area) => SubtitleFinder.Grow(read, area, Band) };
        for (var i = 0; i < 3; i++)
        {
            await pipeline.ProcessAsync(Frame.Blank(64, 64), new CropRegion(Area.Top, Area.Bottom, Area.Left, Area.Right));
            await pipeline.WaitForTranslationsAsync();
        }
        Assert.Equal(["TR: Tomas: Keep your head down."], sender.Sent);
    }
}
