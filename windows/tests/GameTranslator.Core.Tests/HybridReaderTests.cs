// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class HybridReaderTests
{
    /// <summary>Sırayla verilen metinleri döndüren, kaç kez çağrıldığını sayan okuyucu.</summary>
    private sealed class Scripted(params string[] texts) : ITextReader
    {
        private int next;
        public int Calls { get; private set; }
        public bool Throws { get; set; }

        public string Read(Frame image)
        {
            Calls++;
            if (Throws) throw new InvalidOperationException("model yok");
            return texts[Math.Min(next++, texts.Length - 1)];
        }
    }

    private static readonly Frame Image = Frame.Blank(64, 64);

    private static HybridReader Hybrid(Scripted fast, Scripted strong, Func<long>? clock = null) =>
        new(fast, strong, clock) { LooksMisread = text => text.Contains("zz", StringComparison.Ordinal) };

    /// Onarımla düzelen hızlı okuma için güçlü okuyucu çalışmaz.
    [Fact]
    public void RepairedFastReadingNeedsNoStrongReader()
    {
        var strong = new Scripted("Hold the gate.");
        var reader = Hybrid(new Scripted("Hold the gzzte."), strong);
        reader.Repair = text => text.Replace("gzzte", "gate");
        Assert.Equal("Hold the gate.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(0, strong.Calls);
    }

    /// Güçlü okuyucu satırı boşluksuz okuduysa (tek "sözcük") hızlı okumanın yerine geçmez.
    [Fact]
    public void GluedStrongReadingDoesNotReplaceTheFastOne()
    {
        var reader = Hybrid(new Scripted("Kirk: I trust 'im lizze a brother."), new Scripted("Kirkitrustimlikeobrother."));
        Assert.Equal("Kirk: I trust 'im lizze a brother.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(0, reader.StrongWins);
    }

    /// Güçlü okuyucunun zemindeki dokudan okuduğu çöp satır ("HIITIIE") okumayı bozmaz; satır çıkarılır.
    [Fact]
    public void JunkLineOfTheStrongReaderIsDropped()
    {
        var reader = new HybridReader(new Scripted("Hold the gzzte."), new Scripted("Hold the gate.\nQQXQQ"))
        {
            LooksMisread = text => text.Contains("zz", StringComparison.Ordinal) || text.Contains("QQ", StringComparison.Ordinal),
            Score = text => text.Contains("QQ", StringComparison.Ordinal) ? -5 : text.Count(char.IsLetter),
        };
        Assert.Equal("Hold the gate.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(1, reader.StrongWins);
    }

    [Fact]
    public void CleanReadingNeverRunsTheStrongReader()
    {
        var (fast, strong) = (new Scripted("Hold the gate."), new Scripted("Hold the gate."));
        var reader = Hybrid(fast, strong);
        for (var i = 0; i < 5; i++) Assert.Equal("Hold the gate.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(0, strong.Calls);
        Assert.Equal(0, reader.StrongRuns);
    }

    [Fact]
    public void MisreadLineIsRescuedByTheStrongReader()
    {
        var log = new List<string>();
        var reader = Hybrid(new Scripted("Hozzd the gzzte."), new Scripted("Hold the gate."));
        reader.Log = log.Add;
        Assert.Equal("Hold the gate.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(1, reader.StrongWins);
        Assert.Contains(log, line => line.StartsWith("güçlü okuyucu (", StringComparison.Ordinal) && line.Contains("): \"Hozzd the gzzte.\" → \"Hold the gate.\"", StringComparison.Ordinal));
    }

    /// Güçlü okuyucu temiz ama satırın küçük bir parçasını okuduysa hızlı okumanın yerine geçmez.
    [Fact]
    public void CleanFragmentDoesNotReplaceAMostlyRightLine()
    {
        var reader = Hybrid(new Scripted("We leave at dawn, so get some rezzt."), new Scripted("the"));
        Assert.Equal("We leave at dawn, so get some rezzt.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(0, reader.StrongWins);
    }

    [Fact]
    public void FastReadingStaysWhenTheStrongOneIsNotBetter()
    {
        // Güçlü okuyucu daha kötü ya da boş okursa hızlı okuma kalır; eşitlikte de.
        Assert.Equal("Hold the gzzte now.", Hybrid(new Scripted("Hold the gzzte now."), new Scripted("H0$d")).ReadLines(Image, true).Text);
        Assert.Equal("Hold the gzzte now.", Hybrid(new Scripted("Hold the gzzte now."), new Scripted("")).ReadLines(Image, true).Text);
        var reader = Hybrid(new Scripted("Hold the gzzte."), new Scripted("Hold the gzzte."));
        Assert.Equal("Hold the gzzte.", reader.ReadLines(Image, true).Text);
        Assert.Equal(0, reader.StrongWins);
        Assert.Equal(1, reader.StrongRuns);
    }

    /// Hızlı okuyucu boş dönünce güçlü okuyucu her karede değil, aralıklı denenir.
    [Fact]
    public void EmptyFramesProbeTheStrongReaderOnlyNowAndThen()
    {
        long time = 0;
        var (fast, strong) = (new Scripted(""), new Scripted(""));
        var reader = Hybrid(fast, strong, () => time);
        for (var i = 0; i < 20; i++)
        {
            Assert.Equal("", reader.ReadLines(Image, deep: true).Text);
            time += 100;
        }
        // 2 saniyede en çok iki deneme (1200 ms'de bir).
        Assert.InRange(strong.Calls, 1, 2);
    }

    /// Ekranda duran aynı bozuk okuma her karede yeniden güçlü okuyucuya gitmez; karar bir süre geçerlidir.
    [Fact]
    public void SameMisreadLineIsNotReadAgainEveryFrame()
    {
        long time = 0;
        var strong = new Scripted("Hold the gate.");
        var reader = Hybrid(new Scripted("Hozzd the gzzte."), strong, () => time);
        for (var i = 0; i < 7; i++)
        {
            Assert.Equal("Hold the gate.", reader.ReadLines(Image, deep: true).Text);
            time += 200;
        }
        Assert.Equal(1, strong.Calls);
        time += HybridReader.RememberMs;
        reader.ReadLines(Image, deep: true);
        Assert.Equal(2, strong.Calls);
    }

    /// Ekranda duran yazının kareden kareye biraz farklı bozuk okunması da aynı yazıdır; uzayan yazı ise yeniden okunur.
    [Fact]
    public void SlightlyDifferentRereadsUseTheSameDecisionButGrowingTextDoesNot()
    {
        long time = 0;
        var strong = new Scripted("Tell her to get used to it now.", "Tell her to get used to it now. With the tremors setting us back.");
        var reader = Hybrid(new Scripted("Tell her to gzzt used to it now.", "Tell her to get uzzed to it now.", "Tell hzzr to get used to it now.",
            "Tell her to get used to it now. With the tremors setting us bzzck."), strong, () => time);
        for (var i = 0; i < 3; i++)
        {
            Assert.Equal("Tell her to get used to it now.", reader.ReadLines(Image, deep: true).Text);
            time += 200;
        }
        Assert.Equal(1, strong.Calls);
        Assert.Equal("Tell her to get used to it now. With the tremors setting us back.", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(2, strong.Calls);
    }

    /// FF7: ad sözün üstünde ayrı (renkli) satırda; hızlı okuyucu onu görmüyor. Güçlü okuyucu ad satırını iki kez görünce
    /// adsız yeni satırlarda ad ondan alınır.
    [Fact]
    public void NameRowSeenOnlyByTheStrongReaderIsAdded()
    {
        long time = 0;
        var strong = new Scripted("Jessie\nHold the gzzte.", "Barret\nGet down now.", "Jessie\nWell, I'm glad that's over with.");
        var reader = Hybrid(new Scripted("Hold the gzzte.", "Get dozzn now.", "Well, I'm glad that's over with."), strong, () => time);
        reader.ReadLines(Image, deep: true);
        time += 2000;
        reader.ReadLines(Image, deep: true);
        time += 2000;
        Assert.Equal("Jessie: Well, I'm glad that's over with.", reader.ReadLines(Image, deep: true).Text);
    }

    /// Söz zaten adla başlıyorsa üstteki satır (düğme yazısı: "Examine") ad sayılmaz.
    [Fact]
    public void PromptAboveALabelledLineIsNotAName()
    {
        Assert.Null(HybridReader.NameRow(Reading.FromText("Examine\nGeralt: Heavily armored.")));
        Assert.Equal(("Jessie", "Well, I'm glad."), HybridReader.NameRow(Reading.FromText("¯Jessie/\nWell, I'm glad.")));
    }

    /// Geniş okunan alanda ad satırının üstünde başka yazı, altında menü yazısı olabilir; ad sözün hemen üstünde aranır.
    [Fact]
    public void NameIsFoundRightAboveTheSpeech()
    {
        var reading = Reading.FromText("exploring.\nTifa\nWe were, but it's not like we hung out much.\nCommands Menu");
        Assert.Equal(("Tifa", "We were, but it's not like we hung out much."),
            HybridReader.NameAbove(reading, "We were, but it's not like we hung out much."));
    }

    /// Güçlü okuma kaybettiyse de aynı yazı için bir süre yeniden sorulmaz (ekranda duran ipucu kutusu).
    [Fact]
    public void LostStrongReadIsNotRepeatedForTheSameText()
    {
        long time = 0;
        var strong = new Scripted("H0$d");
        var reader = Hybrid(new Scripted("Hold the gzzte now."), strong, () => time);
        for (var i = 0; i < 7; i++)
        {
            Assert.Equal("Hold the gzzte now.", reader.ReadLines(Image, deep: true).Text);
            time += 200;
        }
        Assert.Equal(1, strong.Calls);
    }

    /// Boş sahnede güçlü okuyucunun dokudan uydurduğu yazı (tek harf, tek "sözcük", başka yazı sistemi) okuma sayılmaz.
    [Theory]
    [InlineData("MEEEEEI")]
    [InlineData("d")]
    [InlineData("AU\nU&OD")]
    [InlineData("发 / 鱼")]
    [InlineData("好 morning to you all")]
    public void JunkFoundByTheProbeIsNotAReading(string junk)
    {
        var reader = Hybrid(new Scripted(""), new Scripted(junk));
        Assert.Equal("", reader.ReadLines(Image, deep: true).Text);
        Assert.Equal(0, reader.StrongWins);
    }

    [Fact]
    public void TextTheFastReaderCannotSeeIsFoundByTheProbe()
    {
        long time = 0;
        var reader = Hybrid(new Scripted(""), new Scripted("We leave at dawn."), () => time);
        Assert.Equal("We leave at dawn.", reader.ReadLines(Image, deep: true).Text);
        // Aralık dolmadan yeniden denenmez; hızlı okuyucunun boş okuması döner.
        time += 100;
        Assert.Equal("", reader.ReadLines(Image, deep: true).Text);
        time += HybridReader.ProbeEveryMs;
        Assert.Equal("We leave at dawn.", reader.ReadLines(Image, deep: true).Text);
    }

    [Fact]
    public void FailingStrongReaderDoesNotBreakReading()
    {
        var reader = Hybrid(new Scripted("Hold the gzzte."), new Scripted("x") { Throws = true });
        Assert.Equal("Hold the gzzte.", reader.ReadLines(Image, deep: true).Text);
    }
}
