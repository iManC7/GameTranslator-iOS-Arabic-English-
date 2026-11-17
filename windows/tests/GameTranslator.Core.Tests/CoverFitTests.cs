// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class CoverFitTests
{
    private static readonly TextBox Source = new(0.35, 0.80, 0.65, 0.84);

    [Fact]
    public void ShortTranslationKeepsTheSourceBox()
    {
        var box = CoverFit.Box(Source, "Evet.", 46);
        Assert.Equal(Source.Left, box.Left, 3);
        Assert.Equal(Source.Right, box.Right, 3);
        Assert.True(box.Top <= Source.Top && box.Bottom >= Source.Bottom);
    }

    [Fact]
    public void LongerTranslationWidensTheBoxAroundTheScreenCenter()
    {
        var box = CoverFit.Box(Source, "Bu cümle İngilizcesinden belirgin biçimde daha uzun bir çeviridir.", 46);
        Assert.True(box.Left < Source.Left && box.Right > Source.Right);
        Assert.Equal(0.5, (box.Left + box.Right) / 2, 2);
        Assert.InRange(box.Right - box.Left, 0.5, 0.95);
    }

    [Fact]
    public void TranslationThatWrapsGrowsTheBoxVertically()
    {
        var text = string.Join(' ', Enumerable.Repeat("çok uzun bir cümle", 9));
        var box = CoverFit.Box(Source, text, 46);
        Assert.True(box.Bottom - box.Top > (Source.Bottom - Source.Top) * 2);
        Assert.Equal((Source.Top + Source.Bottom) / 2, (box.Top + box.Bottom) / 2, 2);
        Assert.InRange(box.Left, 0, 0.06);
    }

    [Fact]
    public void BoxNeverShrinksOrLeavesTheScreen()
    {
        var corner = new TextBox(0.02, 0.93, 0.98, 0.99);
        var box = CoverFit.Box(corner, string.Join(' ', Enumerable.Repeat("uzun", 80)), 60);
        Assert.InRange(box.Top, 0, corner.Top);
        Assert.InRange(box.Bottom, corner.Bottom, 1);
        Assert.InRange(box.Left, 0, corner.Left);
        Assert.Equal(Source, CoverFit.Box(Source, "  ", 46));
    }
}
