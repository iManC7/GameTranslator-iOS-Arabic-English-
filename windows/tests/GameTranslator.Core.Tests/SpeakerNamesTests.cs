// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Core;
using Xunit;

namespace GameTranslator.Core.Tests;

public class SpeakerNamesTests
{
    private static SpeakerNames Knowing(string name, int times)
    {
        var names = new SpeakerNames();
        for (var i = 0; i < times; i++) names.Canonical(name);
        return names;
    }

    [Theory]
    [InlineData("Mimir", "Minnir")]
    [InlineData("Mimir", "Mimnir")]
    [InlineData("Mimir", "Mimire")]
    [InlineData("Kratos", "Kracos")]
    [InlineData("Lae'zel", "Lael-zel")]
    [InlineData("Flint Marko", "Flint Marka")]
    public void MisreadNameBecomesTheNameSeenOften(string known, string misread) =>
        Assert.Equal(known, Knowing(known, 5).Canonical(misread));

    [Fact]
    public void UnknownNamesStayAsRead()
    {
        var names = Knowing("Mimir", 5);
        Assert.Equal("Kratos", names.Canonical("Kratos"));
        Assert.Equal("Freya", names.Canonical("Freya"));
        // Kısa adlar birbirine çok benzer ("Sam", "Dan"); düzeltilmez.
        Assert.Equal("Sam", Knowing("Dan", 5).Canonical("Sam"));
        // Sözcük sayısı farklıysa başka addır.
        Assert.Equal("Mimir Smith", names.Canonical("Mimir Smith"));
    }

    [Fact]
    public void NameIsNotCorrectedBeforeTheOtherIsSeenOftenEnough()
    {
        var names = Knowing("Mimir", SpeakerNames.KnownAfter - 1);
        Assert.Equal("Minnir", names.Canonical("Minnir"));
    }

    /// Birbirine benzeyen iki gerçek ad, ikincisi de yeterince görülünce ayrı kalır.
    [Fact]
    public void TwoRealSimilarNamesBothSurvive()
    {
        var names = Knowing("Maria", 6);
        for (var i = 0; i < 2; i++) names.Canonical("Marie");
        Assert.Equal("Marie", names.Canonical("Marie"));
        Assert.Equal("Maria", names.Canonical("Maria"));
    }

    /// Yazı tanıma adı hep aynı biçimde bozabiliyor; sık görülen bozuk ad da doğrusu çok daha sıksa düzelir.
    [Fact]
    public void OftenMisreadNameIsStillCorrected()
    {
        var names = new SpeakerNames();
        for (var i = 0; i < 20; i++)
        {
            names.Canonical("Mimir");
            if (i >= 4 && i % 5 == 4) Assert.Equal("Mimir", names.Canonical("Minnir"));
        }
    }

    private static Reading Lines(params string[] lines) => new(lines.Select(line => new TextLine(line, null)));

    /// Windows'un okuyucusu adı hep aynı biçimde bozsa da ("Alou"), güçlü okuyucunun okuduğu ad ("Aloy") kullanılır.
    [Fact]
    public void NameReadByTheStrongReaderWinsOverTheCommonMisreading()
    {
        var names = Knowing("Alou", 10);
        Assert.True(names.NeedsCheck("Alou: Let's go."));
        names.Confirm(Lines("Aloy: Let's go."));
        names.Confirm(Lines("Aloy: We're clear.", "Varl: Good."));
        Assert.False(names.NeedsCheck("Alou: Let's go."));
        Assert.Equal("Aloy", names.Canonical("Alou"));
        Assert.Equal("Aloy", names.Canonical("Alog"));
        // Doğrulanmamış başka ad kendisi kalır ve denetlenmesi istenir; adsız satır istenmez.
        Assert.Equal("Erend", names.Canonical("Erend"));
        Assert.True(names.NeedsCheck("Erend: Hey."));
        Assert.False(names.NeedsCheck("We're clear."));
    }

    /// İki gerçek ad ikisi de doğrulanmışsa birbirine çevrilmez.
    [Fact]
    public void TwoConfirmedSimilarNamesStayApart()
    {
        var names = new SpeakerNames();
        for (var i = 0; i < 2; i++) names.Confirm(Lines("Maria: Go.", "Marie: Stay."));
        Assert.Equal("Marie", names.Canonical("Marie"));
        Assert.Equal("Maria", names.Canonical("Maria"));
    }
}
