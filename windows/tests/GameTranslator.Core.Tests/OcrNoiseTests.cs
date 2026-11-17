// SPDX-License-Identifier: AGPL-3.0-only

using GameTranslator.Core;

namespace GameTranslator.Core.Tests;

public class OcrNoiseTests
{
    /// Süslü yazıda bir sözcük her karede başka çöpe dönüşüyordu.
    [Theory]
    [InlineData("Across the deep waters, Pbo ou$3e went, hoping a boat would carry him home.",
                "Across the deep waters, Pbo went, hoping a boat would carry him home.")]
    [InlineData("Across the deep waters2aljd O went, Hoping a boat.", "Across the deep waters O went, Hoping a boat.")]
    [InlineData("He left 3e, at dawn.", "He left, at dawn.")]
    public void GarbledWordsAreRemoved(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));

    /// Konuşmacı adının yanındaki simge harf sanılıyordu (Spider-Man 2).
    [Theory]
    [InlineData("Spider-Man •g: You'll whip him into shape in no", "Spider-Man: You'll whip him into shape in no")]
    [InlineData("Spider-Man •u: We got a sandy situation,", "Spider-Man: We got a sandy situation,")]
    [InlineData("Spider-Man O: No comment.", "Spider-Man: No comment.")]
    [InlineData("Spider-Man \": So", "Spider-Man: So")]
    [InlineData("Norman Osborn +: We're ready.", "Norman Osborn: We're ready.")]
    [InlineData("Kraven s•: Only one way to find out...", "Kraven: Only one way to find out...")]
    [InlineData("Kraven s': special coming up!", "Kraven: special coming up!")]
    [InlineData("MJ: Good luck.", "MJ: Good luck.")]
    [InlineData("Norman Osborn: It will work.", "Norman Osborn: It will work.")]
    [InlineData("Guard 2: Halt!", "Guard 2: Halt!")]
    [InlineData("He said O: nothing", "He said O: nothing")]
    public void SpeakerIconIsRemoved(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));

    /// Simge her karede başka okunuyor; adı iki kez düzgün görülen konuşmacıda temizlenir.
    [Fact]
    public void KnownSpeakerLosesIconJunkAndGetsItsColon()
    {
        OcrNoise.ForgetSpeakers();
        // Ad henüz tanınmıyor: dokunulmaz.
        Assert.Equal("Spider-Man so: Look out!", OcrNoise.Clean("Spider-Man so: Look out!"));
        OcrNoise.Clean("Spider-Man: Yeah.");
        OcrNoise.Clean("Spider-Man: How?");
        Assert.Equal("Spider-Man: Look out!", OcrNoise.Clean("Spider-Man so: Look out!"));
        Assert.Equal("Spider-Man: I'll keep the water flowing", OcrNoise.Clean("Spider-Man v: I'll keep the water flowing"));
        Assert.Equal("Spider-Man: He water.", OcrNoise.Clean("Spider-Man S'. He water."));
        Assert.Equal("Spider-Man: Woo! He felt that alright...", OcrNoise.Clean("Spider-Man '2': Woo! He felt that alright..."));
        Assert.Equal("Spider-Man: BOOM!", OcrNoise.Clean("Spider-Man BOOM!"));
        Assert.Equal("Spider-Man: Somebody order some water?", OcrNoise.Clean("Spider-Man Somebody order some water?"));
        Assert.Equal("Spider-Man: No. Stop.", OcrNoise.Clean("Spider-Man No. Stop."));
        Assert.Equal("Spider-Man is here.", OcrNoise.Clean("Spider-Man is here."));
        Assert.Equal("Sandman so: Leave me alone!", OcrNoise.Clean("Sandman so: Leave me alone!"));
        // Simge "S'" ikinci ad sanılmasın; iki basamaklı sayı da simge çöpüdür.
        Assert.Equal("Spider-Man: Keep it moving, Miles.", OcrNoise.Clean("Spider-Man S': Keep it moving, Miles."));
        Assert.Equal("Spider-Man: I'd get into any college I wanted.", OcrNoise.Clean("Spider-Man 04: I'd get into any college I wanted."));
        // Adın kendisi bozuk okunmuş ya da simge ada yapışmış.
        Assert.Equal("Spider-Man: What happened?", OcrNoise.Clean("pider-Man What happened?"));
        Assert.Equal("Spider-Man: Wish I could just write about this", OcrNoise.Clean("Spider-Mame•: Wish I could just write about this"));
        Assert.Equal("Spider-Man: I'd get into any college I wanted...", OcrNoise.Clean("Spider-Mande I'd get into any college I wanted..."));
        Assert.Equal("Spider-Man: STAY INSIDE!", OcrNoise.Clean("Spider-Mam: STAY INSIDE!"));
        Assert.Equal("Spider-Man: You're only making it worse", OcrNoise.Clean("ider-Man V: You're only making it worse"));
        Assert.Equal("Spider-Man: everywhere.", OcrNoise.Clean("Spider-Man •e; everywhere."));
        Assert.Equal("Spider-Man: Marko... it's gonna be okay.", OcrNoise.Clean("Spider-Man \" Marko... it's gonna be okay."));
        Assert.Equal("Spider-Man: Come for us?", OcrNoise.Clean("Spider-Man s i: Come for us?"));
        // Benzemeyen ya da konuşma gibi sürmeyen satıra dokunulmaz.
        Assert.Equal("Spiderrtvlanis OThat water tank's our only shot.", OcrNoise.Clean("Spiderrtvlanis OThat water tank's our only shot."));
        Assert.Equal("Spider-Men are everywhere now.", OcrNoise.Clean("Spider-Men are everywhere now."));
        OcrNoise.ForgetSpeakers();
    }

    /// Cümle sonuna yapışan çöp ve alt tırnak olarak okunan üç nokta.
    [Theory]
    [InlineData("Brainstorm later, Miles. Focus.ie", "Brainstorm later, Miles. Focus.")]
    [InlineData("Actually it's his now.l.", "Actually it's his now.")]
    [InlineData("I know you're angry at me„.", "I know you're angry at me...")]
    [InlineData("MJ wasnt kidding.„ we gotta help", "MJ wasnt kidding... we gotta help")]
    [InlineData("Meet me at 5 p.m", "Meet me at 5 p.m")]
    [InlineData("Is that so?", "Is that so?")]
    [InlineData("Wait...", "Wait...")]
    public void LineEndJunkIsRemoved(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));

    [Theory]
    [InlineData("Turn on the PS5 now.")]
    [InlineData("Hold R2-D2 still.")]
    [InlineData("It costs $500.")]
    [InlineData("Meet me at 3:00pm.")]
    [InlineData("The 2nd gate is 100m away.")]
    [InlineData("Run at 60fps, 4K.")]
    [InlineData("Score x2!")]
    [InlineData("Year 1984.")]
    [InlineData("I can't — wait…")]
    [InlineData("\"Kratos!\" she said.")]
    [InlineData("Mk2 rifle, 9.5kg.")]
    [InlineData("L1 + R1 Spartan Rage")]
    public void UsualTokensAreKept(string line) => Assert.Equal(line, OcrNoise.Clean(line));

    /// <summary>Mafia'da görülen "?!" ve kutu kenarı artıkları; Mac'teki OcrNoiseTests ile aynı örnekler.</summary>
    [Theory]
    [InlineData("?! Where do you think you're going?", "Where do you think you're going?")]
    [InlineData("Where do you think you're going ?!", "Where do you think you're going?!")]
    [InlineData("Get in the car, Enzo. ?!", "Get in the car, Enzo.")]
    [InlineData("Wait, ?! Don Salieri wants you.", "Wait, Don Salieri wants you.")]
    [InlineData(". Get in the car.", "Get in the car.")]
    [InlineData("| Get in the car, Enzo.", "Get in the car, Enzo.")]
    [InlineData("Get in the car, Enzo. |", "Get in the car, Enzo.")]
    [InlineData("Leave it. l", "Leave it.")]
    public void StrayPunctuationAndBoxEdgesAreRemoved(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));

    [Theory]
    [InlineData("l don't know, Don Salieri.", "I don't know, Don Salieri.")]
    [InlineData("| don't know.", "I don't know.")]
    [InlineData("l'm telling you, l saw him.", "I'm telling you, I saw him.")]
    [InlineData("|'ll be right back.", "I'll be right back.")]
    [InlineData("You and l've been here before.", "You and I've been here before.")]
    public void MisreadPronounBecomesI(string line, string expected) => Assert.Equal(expected, OcrNoise.Clean(line));

    [Theory]
    [InlineData("What?! The door opened by itself!")]
    [InlineData("- Where? - Home.")]
    [InlineData("Wait... what?")]
    [InlineData("I... I don't know.")]
    [InlineData("\"Run!\" he said.")]
    [InlineData("So, you're Enzo?")]
    [InlineData("... and then he left.")]
    [InlineData("Wait ... what?")]
    [InlineData("I said no!")]
    [InlineData("Leave it, I said.")]
    [InlineData("Press L to aim.")]
    public void RealPunctuationIsKept(string line) => Assert.Equal(line, OcrNoise.Clean(line));

    [Fact]
    public void ReadingDropsLinesThatWereOnlyNoise()
    {
        var reading = new Reading([new TextLine("We go now."), new TextLine("ou$3e 2aljd")]).WithoutOcrNoise();
        Assert.Equal("We go now.", reading.Text);
    }
}

public class ReadingChoiceTests
{
    [Fact]
    public void CleanReadingScoresHigherThanGarbled()
    {
        Assert.True(OcrNoise.Score("CESARE: Wait for me!") > OcrNoise.Score("- CESAREiVJütt'h!"));
        Assert.True(OcrNoise.Score("We go to McDonald's now.") > 0);
        Assert.True(OcrNoise.Score("T hats the[lil Should be quiet now.") < OcrNoise.Score("That should be quiet now."));
    }

    /// Geçişte üst üste solan iki altyazının karışık okuması çöp sayılır; olağan cümleler, kısaltmalar ve "Hmm" sayılmaz.
    [Theory]
    [InlineData("Gtt solkolfege.", true)]
    [InlineData("- CESAREiVJütt'h!", true)]
    [InlineData("Wrrk thng.", true)]
    [InlineData("Hold the gate.", false)]
    [InlineData("The FBI and the NPC agents.", false)]
    [InlineData("Hmm, I don't know about that, boy.", false)]
    [InlineData("Go to college.", false)]
    public void GarbledReadingsAreRecognised(string text, bool garbled) => Assert.Equal(garbled, OcrNoise.LooksGarbled(text));

    /// Koyu kenarlı beyaz yazı siyaha, parlak zemin ve kenar beyaza döner.
    [Fact]
    public void WhiteTextOnlyKeepsOutlinedWhiteAndDropsBrightBackground()
    {
        var frame = Frame.Blank(60, 20);
        void Paint(int x0, int x1, byte value)
        {
            for (var y = 0; y < 20; y++)
                for (var x = x0; x < x1; x++)
                {
                    var i = y * frame.Stride + x * 4;
                    frame.Pixels[i] = frame.Pixels[i + 1] = frame.Pixels[i + 2] = value;
                    frame.Pixels[i + 3] = 255;
                }
        }
        Paint(0, 30, 230);   // parlak kum: yakınında koyu yok
        Paint(40, 44, 20);   // yazının koyu kenarı
        Paint(44, 48, 250);  // beyaz harf
        var result = TextImage.WhiteTextOnly(frame, radius: 3);
        byte At(int x) => result.Pixels[10 * result.Stride + x * 4];
        Assert.Equal(255, At(5));   // zemin
        Assert.Equal(0, At(45));    // harf
        Assert.Equal(255, At(41));  // kenar
    }
}

