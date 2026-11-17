// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class ReadingConsensusTests
{
    private static readonly HashSet<string> Words = new(StringComparer.OrdinalIgnoreCase)
    {
        "stop", "the", "gate", "is", "open", "so", "do", "we", "hold", "this", "place", "or", "let", "them", "pass",
        "keep", "your", "head", "down", "and", "stay", "close", "to", "me", "slop", "wall",
    };

    private static string Merge(string best, params string[] others) => ReadingConsensus.Merge(best, [best, .. others], Words.Contains);

    /// Her okumada başka bir sözcük bozuk; her sözcüğün doğrusu okumalardan birinde var.
    [Fact]
    public void BrokenWordsAreFilledFromOtherReadings()
    {
        Assert.Equal("Stop! The gate is open, so do we hold this place?",
            Merge("Stop! The gafe is open, so do we hold this place?", "Stop! The gate is opem, so do we hold this place?"));
        Assert.Equal("Keep your head down\nand stay close to me.",
            Merge("Keep your heod down\nand stay clcse to me.", "Keep your head down\nand stay close to rne."));
    }

    [Fact]
    public void RealWordsNamesNumbersAndPunctuationAreNeverReplaced()
    {
        // "Slop" gerçek bir sözcük: öteki okuma "Stop" dese de dokunulmaz (hangisinin doğru olduğu bilinemez).
        Assert.Equal("Slop! The gate is open.", Merge("Slop! The gate is open.", "Stop! The gate is open."));
        Assert.Equal("Markos: hold the gate, 12 of them!", Merge("Markos: hold the gate, 12 of them!", "Marlos: hold the gate, 72 of them!"));
    }

    [Fact]
    public void ReadingsWithADifferentShapeAreIgnored()
    {
        // Sözcük sayısı farklı: hizası belirsiz.
        Assert.Equal("Hold the gafe open", Merge("Hold the gafe open", "Hold the gate"));
        // Satır sayısı farklı.
        Assert.Equal("Hold the gafe", Merge("Hold the gafe", "Hold the gate\nand stay"));
        // Aynı yerde bambaşka bir sözcük: aynı sözcüğün okuması değildir.
        Assert.Equal("Hold the gafe", Merge("Hold the gafe", "Hold the place"));
    }

    [Fact]
    public void WithoutAWordCheckOrOtherReadingsNothingChanges()
    {
        Assert.Equal("Hold the gafe", ReadingConsensus.Merge("Hold the gafe", ["Hold the gafe", "Hold the gate"], null));
        Assert.Equal("Hold the gafe", ReadingConsensus.Merge("Hold the gafe", ["Hold the gafe"], Words.Contains));
    }

    [Fact]
    public async Task PipelineMergesTheReadingsOfAHeldLine()
    {
        var sender = new FakeSender();
        var translator = new FakeTranslator();
        long clock = 0;
        var frames = new[] { "Hold the gafe open now", "Hold the gafe open now", "Hold the gate opem now", "Hold the gate opem now", "Hold the gafe open now", "Hold the gafe open now", "Hold the gafe open now", "Hold the gafe open now" };
        var before = SubtitlePipeline.ExtraWordCheck;
        SubtitlePipeline.ExtraWordCheck = word => !word.Contains("gafe", StringComparison.Ordinal) && !word.Contains("opem", StringComparison.Ordinal);
        try
        {
            var pipeline = new SubtitlePipeline(new FakeReader(frames), translator, sender, clock: () => clock)
                { PackLookup = _ => null, LooksMisread = text => text.Contains("gafe") || text.Contains("opem"), PackWait = 500, CleanWait = 0 };
            for (var i = 0; i < frames.Length; i++)
            {
                await pipeline.ProcessAsync(Frame.Blank(64, 64), new CropRegion());
                await pipeline.WaitForTranslationsAsync();
                clock += 100;
            }
            Assert.Contains("Hold the gate open now", translator.Requested);
        }
        finally
        {
            SubtitlePipeline.ExtraWordCheck = before;
        }
    }
}
