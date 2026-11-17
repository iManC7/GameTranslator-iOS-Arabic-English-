// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Shell;
using Xunit;

namespace GameTranslator.Shell.Tests;

public class FragmentTests
{
    [Theory]
    [InlineData(",to me.", true)]
    [InlineData("pin Ito me.", true)]
    [InlineData("Yeah?", true)]
    [InlineData("Sit?", true)]
    [InlineData("who are gonna need help when they come", false)]
    [InlineData("V: Yeah?", false)]
    [InlineData("Get the car.", false)]
    [InlineData("Yeah?\nYours ain't to me.", false)]
    public void ShortMidSentencePiecesAreFragments(string text, bool fragment) =>
        Assert.Equal(fragment, AppController.LooksLikeFragment(text));

    [Theory]
    [InlineData("IETTET", true)]
    [InlineData("HIITIIE", true)]
    [InlineData("NO!", false)]
    [InlineData("RUN", false)]
    [InlineData("STOP!", false)]
    [InlineData("Mimir: Well?", false)]
    [InlineData("GOOD LUCK", false)]
    public void UppercaseNonWordLineIsJunk(string text, bool junk) =>
        Assert.Equal(junk, AppController.IsCapsJunk(text, word => word is "no" or "run" or "stop" or "good" or "luck"));

    /// Altyazı yeri öğrenilmeden ekranın kenarındaki yazı (görev yazısı) alınmaz; ortalı altyazı kalır.
    [Fact]
    public void OffCenterLinesAreDroppedBeforeTheBandIsKnown()
    {
        var area = new GameTranslator.Core.TextBox(0.08, 0.55, 0.92, 0.98);
        var reading = new GameTranslator.Core.Reading([
            new GameTranslator.Core.TextLine("Activate the statues", new GameTranslator.Core.TextBox(0.0, 0.1, 0.15, 0.15)),
            new GameTranslator.Core.TextLine("Scott Coleman: Protego!", new GameTranslator.Core.TextBox(0.35, 0.8, 0.65, 0.85)),
        ]);
        Assert.Equal("Scott Coleman: Protego!", AppController.WithoutOffCenterLines(reading, area).Text);
    }
}
