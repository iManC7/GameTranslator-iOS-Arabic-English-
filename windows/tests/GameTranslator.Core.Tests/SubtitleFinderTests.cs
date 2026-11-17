// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class SubtitleFinderTests
{
    /// <summary>Ortası (<paramref name="x"/>, <paramref name="y"/>) olan, genişliği metne göre, yüksekliği %2,5 olan satır.</summary>
    private static TextLine Line(string text, double y, double x = 0.5)
    {
        var half = Math.Min(0.45, text.Length * 0.006);
        return new TextLine(text, new TextBox(x - half, y - 0.0125, x + half, y + 0.0125));
    }

    private static SubtitleFinder.Verdict Verdict(SubtitleFinder finder, long now, params TextLine[] lines) =>
        finder.Classify(new Reading(lines), now)[^1].Verdict;

    /// <summary>Konuşmacısız dört altyazıyla (<paramref name="y"/> yüksekliğinde) şeridi öğrenmiş bulucu; son kare 9. saniyededir.</summary>
    private static SubtitleFinder Learned(double y = 0.88)
    {
        var finder = new SubtitleFinder();
        finder.Classify(new Reading([Line("Where are you going?", y)]), 0);
        finder.Classify(new Reading([Line("We need to move, now.", y)]), 3000);
        finder.Classify(new Reading([Line("Stay close to me.", y)]), 6000);
        finder.Classify(new Reading([Line("Do not look back.", y)]), 9000);
        Assert.NotNull(finder.Band);
        return finder;
    }

    [Fact]
    public void LearnsTheBandFromTheFirstSubtitles()
    {
        var finder = new SubtitleFinder();
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 0, Line("Where are you going?", 0.88)));
        finder.Classify(new Reading([Line("We need to move, now.", 0.88)]), 3000);
        finder.Classify(new Reading([Line("Stay close to me.", 0.885)]), 6000);
        Assert.Null(finder.Band);
        finder.Classify(new Reading([Line("Do not look back.", 0.88)]), 9000);
        var band = Assert.NotNull(finder.Band);
        Assert.InRange(band.Top, 0.78, 0.86);
        Assert.InRange(band.Bottom, 0.90, 0.98);
    }

    /// Konuşmacısı belli iki satır şeridi kurmaya yeter: diyalogda konuşmacı olur, ipucunda olmaz.
    [Fact]
    public void SpeakerLinesTeachTheBandQuickly()
    {
        var inline = new SubtitleFinder();
        inline.Classify(new Reading([Line("Elena: Where are you going?", 0.88)]), 0);
        Assert.Null(inline.Band);
        inline.Classify(new Reading([Line("Tomas: Away from here.", 0.88)]), 2000);
        Assert.NotNull(inline.Band);

        // Ad sözün üstünde ayrı satırda, büyük harfle.
        var above = new SubtitleFinder();
        above.Classify(new Reading([Line("ELENA", 0.79), Line("I can tell from the look on your face", 0.82), Line("that you were paid.", 0.85)]), 0);
        var band = Assert.NotNull(above.Band);
        Assert.InRange(0.79, band.Top, band.Bottom);
        Assert.InRange(0.85, band.Top, band.Bottom);
    }

    /// Dövüşte ekranın ortasında çıkan beceri adları ve ipuçları şeridi yanlış yere çekiyordu.
    [Fact]
    public void ShortCombatTextDoesNotTeachTheBand()
    {
        var finder = new SubtitleFinder();
        finder.Classify(new Reading([Line("Shield Charge", 0.75)]), 0);
        finder.Classify(new Reading([Line("Glide up", 0.75)]), 1000);
        finder.Classify(new Reading([Line("Wings ready now", 0.75)]), 2000);
        finder.Classify(new Reading([Line("Hold to pull", 0.75)]), 3000);
        Assert.Null(finder.Band);
        Assert.Equal(SubtitleFinder.Verdict.NotSentence, Verdict(finder, 4000, Line("Shield Charge", 0.75)));
    }

    /// Yükleme ekranındaki ipuçları şeridi diyalogdan önce kapmış olsa bile ilk konuşmacılı satırlar geri alır.
    [Fact]
    public void LoadingScreenTipsDoNotKeepTheBandFromDialogue()
    {
        var finder = new SubtitleFinder();
        finder.Classify(new Reading([Line("Mercenaries are among the strongest fighters in the land.", 0.45)]), 0);
        finder.Classify(new Reading([Line("Hone your skills and climb their ranks.", 0.48)]), 0);
        finder.Classify(new Reading([Line("You can cancel a parry early by dodging.", 0.45)]), 4000);
        finder.Classify(new Reading([Line("Upgrade your ship to survive naval battles.", 0.45)]), 8000);
        var tips = Assert.NotNull(finder.Band);
        Assert.InRange(0.45, tips.Top, tips.Bottom);

        finder.Classify(new Reading([Line("ELENA", 0.79), Line("These bows will make me rich.", 0.82)]), 12000);
        finder.Classify(new Reading([Line("TOMAS", 0.79), Line("They are that good, are they?", 0.82)]), 15000);
        var dialogue = Assert.NotNull(finder.Band);
        Assert.InRange(0.82, dialogue.Top, dialogue.Bottom);
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 18000, Line("War is coming, you know.", 0.82)));
    }

    /// Diyalogla kurulmuş şeridi, araya giren ipuçları ve bildirimler yerinden etmez.
    [Fact]
    public void TipsDoNotMoveABandBuiltFromDialogue()
    {
        var finder = new SubtitleFinder();
        finder.Classify(new Reading([Line("Elena: Where are you going?", 0.88)]), 0);
        finder.Classify(new Reading([Line("Tomas: Away from here.", 0.88)]), 2000);
        for (var i = 0; i < 8; i++)
            finder.Classify(new Reading([Line($"Tip number {i}: you can do many different things here.", 0.45)]), 4000 + (i * 2000));
        var band = Assert.NotNull(finder.Band);
        Assert.InRange(0.88, band.Top, band.Bottom);
        Assert.Equal(SubtitleFinder.Verdict.OutsideBand, Verdict(finder, 21000, Line("One more piece of advice for you.", 0.45)));
    }

    [Fact]
    public void TwoLineSubtitleStaysInsideTheBand()
    {
        var finder = Learned();
        var findings = finder.Classify(new Reading([
            Line("Elena: According to the guards, he was running", 0.865),
            Line("down the harbor road, shouting nonsense.", 0.895)]), 12000);
        Assert.All(findings, finding => Assert.Equal(SubtitleFinder.Verdict.Subtitle, finding.Verdict));
    }

    [Fact]
    public void TutorialTipOutsideTheBandIsNotASubtitle()
    {
        var finder = Learned();
        Assert.Equal(SubtitleFinder.Verdict.OutsideBand,
            Verdict(finder, 12000, Line("You can sneak up on enemies to take them down quietly.", 0.45)));
        Assert.Equal(SubtitleFinder.Verdict.OutsideBand,
            Verdict(finder, 12500, Line("Are you sure you want to skip this scene?", 0.38)));
    }

    [Fact]
    public void ButtonPromptsCornerTextAndTitlesAreNotSubtitles()
    {
        var finder = Learned();
        Assert.Equal(SubtitleFinder.Verdict.Prompt, Verdict(finder, 12000, Line("R2 Swing", 0.88)));
        Assert.Equal(SubtitleFinder.Verdict.OffCenter, Verdict(finder, 12000, Line("Find the water tank on the roof.", 0.88, x: 0.15)));
        Assert.Equal(SubtitleFinder.Verdict.NotSentence, Verdict(finder, 12000, Line("RESET ALL TO DEFAULT", 0.88)));
        Assert.Equal(SubtitleFinder.Verdict.NotSentence, Verdict(finder, 12000, Line("Back", 0.88)));
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 12000, Line("Run!", 0.88)));
    }

    [Fact]
    public void TextThatStaysPutIsInterface()
    {
        var finder = Learned();
        var objective = Line("Reach the water tank before the others do.", 0.88);
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 10000, objective));
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 13000, objective));
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 16000, objective));
        Assert.Equal(SubtitleFinder.Verdict.Static, Verdict(finder, 10000 + SubtitleFinder.StaticAfterMs, objective));
        // Kaybolup sonra yeniden gelen aynı satır yeniden altyazıdır.
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, 40000, objective));
    }

    [Fact]
    public void MenuColumnIsNotASubtitle()
    {
        var finder = new SubtitleFinder();
        var findings = finder.Classify(new Reading([
            Line("Map", 0.40), Line("Settings", 0.44), Line("Photo Mode", 0.48), Line("Quit", 0.52)]), 0);
        Assert.All(findings, finding => Assert.Equal(SubtitleFinder.Verdict.Menu, finding.Verdict));
    }

    /// Altyazı başka yere taşınınca (başka oyun, başka sahne) oradaki satırlar ağır basar ve şerit oraya geçer.
    [Fact]
    public void RelearnsWhenSubtitlesMoveElsewhere()
    {
        var finder = Learned(0.88);
        var lines = new[]
        {
            "This game shows them at the top.", "Second line up here as well.", "And a third one to be sure.", "A fourth line follows it.",
            "Then a fifth line appears.", "A sixth one comes after that.", "The seventh line is here now.", "Now this is the subtitle band.",
        };
        var time = 12000L;
        foreach (var text in lines)
        {
            finder.Classify(new Reading([Line(text, 0.10)]), time);
            time += 3000;
        }
        Assert.Equal(SubtitleFinder.Verdict.Subtitle, Verdict(finder, time, Line("Everything is read up here.", 0.10)));
        Assert.Equal(SubtitleFinder.Verdict.OutsideBand, Verdict(finder, time + 500, Line("The old place is not, anymore.", 0.88)));
    }

    /// Kanıt eskiyince (uzun yükleme, menü) yeni yerde az sayıda satır şeridi kurmaya yeter.
    [Fact]
    public void OldEvidenceExpires()
    {
        var finder = Learned(0.88);
        var later = 9000 + SubtitleFinder.EvidenceMs + 1000;
        finder.Classify(new Reading([Line("Elena: It has been a long time.", 0.30)]), later);
        finder.Classify(new Reading([Line("Tomas: Too long, I would say.", 0.30)]), later + 3000);
        var band = Assert.NotNull(finder.Band);
        Assert.InRange(0.30, band.Top, band.Bottom);
    }

    [Fact]
    public void SubtitlesReturnsOnlyTheSubtitleLines()
    {
        var finder = Learned();
        var reading = finder.Subtitles(new Reading([
            Line("Objective updated: find the smuggler.", 0.20, x: 0.2),
            Line("R2 Swing", 0.70),
            Line("Elena: Only way is up.", 0.88)]), 12000);
        Assert.Equal("Elena: Only way is up.", reading.Text);
    }
}
