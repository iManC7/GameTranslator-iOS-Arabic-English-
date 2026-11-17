// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class OcrConfusionsTests
{
    private static readonly HashSet<string> Words = new(StringComparer.OrdinalIgnoreCase)
    {
        "crouch", "to", "make", "your", "steps", "quiet", "knives", "do", "not", "vanish", "they", "are", "used", "for",
        "attack", "and", "defense", "the", "noise", "of", "moving", "after", "alter", "tor", "lake", "take", "it", "is",
        "modern", "moment", "are", "you", "ok", "hold", "on", "weapon", "from", "form",
        "time", "running", "out", "my", "love", "there", "much", "we", "won't", "find", "him", "this", "way", "let's",
        "that", "trail", "blood", "use", "words", "brother", "no", "truth", "hurts", "huh", "a", "i", "here", "where",
        "heywood", "as", "her", "hey", "wood", "oh", "help", "brother", "try", "contraption", "just", "next", "pod", "did", "something", "when", "sealed", "me", "in", "learned", "come", "had", "apples", "fi", "et", "oy", "money", "lot", "paying", "field", "bello", "win", "bellowing", "hence", "ray", "field", "mine", "should", "known", "stay", "trash", "sea", "woman", "little", "faith", "jackie",
    };

    private static string Repair(string line) => OcrConfusions.Repair(line, Words.Contains);

    [Theory]
    [InlineData("Crouch Io make your steps quiet.", "Crouch to make your steps quiet.")]
    [InlineData("Knives do nol vanish.", "Knives do not vanish.")]
    [InlineData("They are used lor attack and defense.", "They are used for attack and defense.")]
    [InlineData("The noise 01 moving", "The noise of moving")]
    [InlineData("Take it aller the attack.", "Take it after the attack.")]
    [InlineData("Are you 0K?", "Are you OK?")]
    [InlineData("A rnodern weapon", "A modern weapon")]
    [InlineData("Io make it quiet", "To make it quiet")]
    public void ConfusedLettersAreRepaired(string line, string expected) => Assert.Equal(expected, Repair(line));

    /// Yuvarlak yazı tiplerinde "m" "nn" / "n" / "na" / "no", "t" "c", "l" "i" okunuyor.
    [Theory]
    [InlineData("Tinne is running out, ny love.", "Time is running out, my love.")]
    [InlineData("And there is nauch co do.", "And there is much to do.")]
    [InlineData("Wc won't find hinn chis way.", "We won't find him this way.")]
    [InlineData("Let's find chat trail of blood.", "Let's find that trail of blood.")]
    [InlineData("Time is running out, noy iove.", "Time is running out, my love.")]
    public void RoundFontConfusionsAreRepaired(string line, string expected) => Assert.Equal(expected, Repair(line));

    /// Sözcük arası boşlukları okunmamış parça gerçek sözcüklere bölünür.
    [Theory]
    [InlineData("Andthereismuchtodo.", "And there is much to do.")]
    [InlineData("Let'sfindthattrailofblood...", "Let's find that trail of blood...")]
    [InlineData("Useyourwords,brother.", "Use your words, brother.")]
    [InlineData("No.It hurts.", "No. It hurts.")]
    [InlineData("Shadowheart:Trythatcontraptionjustnexttothepod-theydidsomethingtoitwhen", "Shadowheart: Try that contraption just next to the pod - they did something to it when")]
    public void GluedWordsAreSplit(string line, string expected) => Assert.Equal(expected, Repair(line));

    /// Ünlem "l" okunmuş: ardından yeni cümle geliyorsa "!" olur; sözcük ortasındaki gerçek "l"e dokunulmaz.
    [Theory]
    [InlineData("Ohl Time is running out.", "Oh! Time is running out.")]
    [InlineData("Brotherl Brother!", "Brother! Brother!")]
    [InlineData("Help him, brotherl", "Help him, brother!")]
    [InlineData("Ohl no.", "Ohl no.")]
    [InlineData("1 learned a long time ago.", "I learned a long time ago.")]
    [InlineData("Stoy where you are!", "Stay where you are!")]
    [InlineData("paying you a lot of Ilioney", "paying you a lot of money")]
    [InlineData("You're o woman of little faith.", "You're a woman of little faith.")]
    [InlineData("Street trosh in the seo.", "Street trash in the sea.")]
    [InlineData("Conne on.", "Come on.")]
    [InlineData("We had 1 apples.", "We had 1 apples.")]
    public void ExclamationReadAsLIsRepaired(string line, string expected) => Assert.Equal(expected, Repair(line));

    /// Cümle ortasında büyük harfle başlayan parça addır; bilinen sözcüklere bölünebilse de bölünmez. Kısa parçalara
    /// bölünen anlamsız parça da bölünmez.
    [Theory]
    [InlineData("You live in Heywood, huh?")]
    [InlineData("They are Asherhere.")]
    [InlineData("U.S. Army")]
    [InlineData("Jackiefiet the car.")]
    [InlineData("Hence my bellowin'.")]
    [InlineData("Jackie: Rayfield's mine.")]
    [InlineData("You shoulda known.")]
    public void NamesAndShortPieceSplitsAreLeftAlone(string line) => Assert.Equal(line, Repair(line));

    [Theory]
    // Gerçek sözcüğe dokunulmaz, yanlış okunmuş olsa bile ("lake" aslında "take" olabilir; bilinemez).
    [InlineData("Io lake the weapon")]
    [InlineData("They alter the form.")]
    // Özel adlar ve bilinmeyen sözcükler.
    [InlineData("Artyom, hold on!")]
    [InlineData("Kephallonia is not Zorvald.")]
    // Aday yoksa ya da birden çok eşit aday varsa değişmez.
    [InlineData("They are xqlz.")]
    public void RealWordsNamesAndUnknownsAreLeftAlone(string line)
    {
        var expected = line.StartsWith("Io ", StringComparison.Ordinal) ? "To" + line[2..] : line;
        Assert.Equal(expected, Repair(line));
    }

    [Fact]
    public void WithoutAWordCheckNothingChanges() => Assert.Equal("Knives do nol vanish.", OcrConfusions.Repair("Knives do nol vanish.", null));
}
