// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class StableCoverTests
{
    private static TextBox Box(double left, double top, double right, double bottom) => new(left, top, right, bottom);

    /// Aynı altyazının yeni okuması zemini daraltmaz.
    [Fact]
    public void SameSubtitleDoesNotShrink()
    {
        long time = 0;
        var cover = new StableCover(() => time);
        var wide = Box(0.26, 0.72, 0.74, 0.77);
        Assert.Equal(wide, cover.Next(wide));
        time += 600;
        Assert.Equal(wide, cover.Next(Box(0.35, 0.72, 0.65, 0.77)));
    }

    /// FF7: uzun cümleden hemen sonra gelen kısa yeni satır ("Hahaha...") kendi boyunda örtülür, ekran genişliğinde şerit olmaz.
    [Fact]
    public void ShortNewLineGetsItsOwnCover()
    {
        long time = 0;
        var cover = new StableCover(() => time);
        cover.Next(Box(0.15, 0.80, 0.85, 0.86), newLine: true);
        time += 1500;
        var shortLine = Box(0.44, 0.80, 0.56, 0.86);
        Assert.Equal(shortLine, cover.Next(shortLine, newLine: true));
    }

    /// İki satırlı sahnede zemin üst ve alt satırı birlikte örter (zıplamaz).
    [Fact]
    public void AdjacentLinesShareOneCover()
    {
        long time = 0;
        var cover = new StableCover(() => time);
        cover.Next(Box(0.38, 0.66, 0.62, 0.70));
        time += 1500;
        Assert.Equal(Box(0.38, 0.66, 0.63, 0.75), cover.Next(Box(0.39, 0.71, 0.63, 0.75)));
    }

    /// Bir süre altyazı gelmezse ya da altyazı başka yere geçerse zemin yeni kutuya göre kurulur.
    [Fact]
    public void CoverStartsOverAfterAPauseOrElsewhere()
    {
        long time = 0;
        var cover = new StableCover(() => time);
        cover.Next(Box(0.2, 0.72, 0.8, 0.77));
        time += StableCover.HoldMs + 1;
        Assert.Equal(Box(0.4, 0.72, 0.6, 0.77), cover.Next(Box(0.4, 0.72, 0.6, 0.77)));
        time += 500;
        Assert.Equal(Box(0.4, 0.10, 0.6, 0.15), cover.Next(Box(0.4, 0.10, 0.6, 0.15)));
    }

    /// Zemin sınırsız uzamaz: alt alta gelen satırlarda en çok iki satırlık örtü olur.
    [Fact]
    public void CoverDoesNotGrowWithoutLimit()
    {
        long time = 0;
        var cover = new StableCover(() => time);
        foreach (var top in new[] { 0.60, 0.64, 0.68, 0.72, 0.76 })
        {
            var result = cover.Next(Box(0.4, top, 0.6, top + 0.04));
            Assert.True(result.Bottom - result.Top <= 0.09, $"{result}");
            Assert.True(result.Top <= top && result.Bottom >= top + 0.04);
            time += 500;
        }
        // Ekranı kaplayan iki satırlık kutu da kendinden büyük birleşmez.
        Assert.Equal(Box(0.4, 0.80, 0.6, 0.98), cover.Next(Box(0.4, 0.80, 0.6, 0.98)));
    }

    /// Çok yüksek kutu (şerit öğrenilmeden okunan geniş alan) alttan en çok ekranın %20'si kadar örtülür.
    [Fact]
    public void TallBoxIsCutFromTheBottom()
    {
        var cover = new StableCover(() => 0);
        Assert.Equal(Box(0.36, 0.74, 0.64, 0.94), cover.Next(Box(0.36, 0.55, 0.64, 0.94)));
    }
}
