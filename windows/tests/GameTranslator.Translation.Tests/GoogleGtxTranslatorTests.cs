// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Translation.Tests;

public class GoogleGtxTranslatorTests
{
    [Theory]
    [InlineData("MJ: According to witnesses, he was running\ndown Broadway, yelling nonsense.",
        "MJ: According to witnesses, he was running down Broadway, yelling nonsense.")]
    [InlineData("You'll whip him into shape in no \r\n time.", "You'll whip him into shape in no time.")]
    [InlineData("One\ntwo\nthree", "One two three")]
    [InlineData("Single line.", "Single line.")]
    // Konuşmacı işaretiyle başlayan satır ayrı konuşmadır.
    [InlineData("Where are you going?\n- Home.", "Where are you going?\n- Home.")]
    [InlineData("Wait for me\nplease.\n>> No.", "Wait for me please.\n>> No.")]
    // Yarım cümlenin ortasındaki tire konuşmacı işareti değildir.
    [InlineData("There is a\n- bakery up the street!", "There is a bakery up the street!")]
    public void WrappedLinesBecomeOneSentence(string text, string expected) =>
        Assert.Equal(expected, GoogleGtxTranslator.JoinWrappedLines(text));
}
