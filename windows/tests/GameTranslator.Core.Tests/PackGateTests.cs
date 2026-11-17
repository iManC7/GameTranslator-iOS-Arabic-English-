// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

public class PackGateTests
{
    private static readonly PackMatch Hit = new("çeviri", []);

    [Fact]
    public void ShortGenericLinesFromAnotherGameAreNotUsed()
    {
        long time = 0;
        var gate = new PackGate(() => time);
        foreach (var line in new[] { "Miles?", "Spider-Man: Yeah,", "Nope...", "Class?!", "Leave me alone!" })
        {
            Assert.Null(gate.Filter(line, Hit));
            time += 20_000;
        }
        Assert.False(gate.IsOpen);
        Assert.Null(gate.Filter("No match at all in any pack here.", null));
    }

    [Fact]
    public void OpensAfterSeveralLongLinesAndThenUsesShortOnesToo()
    {
        long time = 0;
        var gate = new PackGate(() => time);
        Assert.Null(gate.Filter("We need to get out of here, now.", Hit));
        // Aynı satır yeniden sorulunca (hat bir satır için birkaç kez sorar) sayılmaz.
        Assert.Null(gate.Filter("We need to get out of here, now.", Hit));
        time += 5_000;
        Assert.Null(gate.Filter("I told you not to come back.", Hit));
        time += 5_000;
        Assert.Same(Hit, gate.Filter("You should have listened to me, boy.", Hit));
        Assert.True(gate.IsOpen);
        Assert.Same(Hit, gate.Filter("Yeah.", Hit));
    }

    [Fact]
    public void CoincidencesSpreadOverALongTimeDoNotOpenIt()
    {
        long time = 0;
        var gate = new PackGate(() => time);
        foreach (var line in new[] { "What are you doing out here?", "I have no idea what happened.", "We should get back to work." })
        {
            Assert.Null(gate.Filter(line, Hit));
            time += PackGate.WindowMs;
        }
        Assert.False(gate.IsOpen);
    }

    [Fact]
    public void ClosesWhenLongMatchesStop()
    {
        long time = 0;
        var gate = new PackGate(() => time);
        gate.Filter("We need to get out of here, now.", Hit);
        gate.Filter("I told you not to come back.", Hit);
        gate.Filter("You should have listened to me, boy.", Hit);
        Assert.True(gate.IsOpen);
        time += PackGate.CloseAfterMs + 1;
        Assert.False(gate.IsOpen);
        Assert.Null(gate.Filter("Yeah.", Hit));
    }
}
