// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class ShortPhrasesTests
{
    [Theory]
    [InlineData("Well?", "Ee?")]
    [InlineData("See?", "Gördün mü?")]
    [InlineData("Brother?", "Kardeşim?")]
    [InlineData("Hurry! Please!", "Acele et! Lütfen!")]
    [InlineData("Okay.", "Tamam.")]
    [InlineData("Morning!", "Günaydın!")]
    [InlineData("No...", "Hayır...")]
    [InlineData("...Yeah.", "...Evet.")]
    [InlineData("Let's go.", "Hadi gidelim.")]
    [InlineData("Let’s go!", "Hadi gidelim!")]
    public void KnownShortLinesHaveFixedTranslations(string source, string expected) => Assert.Equal(expected, ShortPhrases.Translate(source));

    /// Cümlelerden biri bile tabloda yoksa satır çevirmene gider; uzun satıra hiç bakılmaz.
    [Theory]
    [InlineData("See? We're rich.")]
    [InlineData("Behind you, brother!")]
    [InlineData("Well, I think we should go now and find him.")]
    [InlineData("Faye?")]
    public void OtherLinesAreLeftToTheTranslator(string source) => Assert.Null(ShortPhrases.Translate(source));

    [Theory]
    [InlineData("No...", "HAYIR...", "Hayır...")]
    [InlineData("Where is it?", "NEREDE?", "Nerede?")]
    [InlineData("STOP!", "DUR!", "DUR!")]
    [InlineData("Wait.", "Bekle.", "Bekle.")]
    [InlineData("Is it the NCPD?", "NCPD mi?", "NCPD mi?")]
    public void ShoutingTranslationOfAQuietLineIsLowered(string source, string translation, string expected) =>
        Assert.Equal(expected, ShortPhrases.FixShouting(source, translation));

    [Fact]
    public async Task ContinuationTranslatorUsesThePhrasebookAndKeepsTheSpeaker()
    {
        var engine = new Recording();
        var translator = new ContinuationTranslator(engine) { Phrasebook = ShortPhrases.Translate };
        Assert.Equal("Mimir: Ee?", await translator.TranslateAsync("Mimir: Well?"));
        Assert.Empty(engine.Seen);
        Assert.Equal("tr:We must go.", await translator.TranslateAsync("We must go."));
    }

    private sealed class Recording : ITextTranslator
    {
        public List<string> Seen { get; } = [];

        public Task<string> TranslateAsync(string text, CancellationToken cancellationToken = default)
        {
            Seen.Add(text);
            return Task.FromResult("tr:" + text);
        }
    }
}
