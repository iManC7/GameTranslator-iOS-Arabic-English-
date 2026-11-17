// SPDX-License-Identifier: AGPL-3.0-only

using System.Text;

namespace GameTranslator.Core.Tests;

/// <summary>Kullanıcının oyunu elle seçmesi: yalnız o oyunun paketi aranır.</summary>
public class PinnedPackTests
{
    private static (string, byte[]) Pack(string id, params (string English, string Turkish)[] lines)
    {
        var entries = string.Join(",", lines.Select(l => $"\"{PackKey.Key(l.English)}\":\"{l.Turkish}\""));
        return ($"{id}.json", Encoding.UTF8.GetBytes($"{{\"format\":1,\"id\":\"{id}\",\"title\":\"{id}\",\"entries\":{{{entries}}}}}"));
    }

    private static GamePackLibrary Library() => new(() =>
    [
        Pack("mafia", ("Come on.", "Hadi."), ("Take him away.", "Götürün onu.")),
        Pack("rdr2", ("Come on.", "Gel hadi."), ("Get down!", "Yere yat!")),
    ], null);

    [Fact]
    public void PinnedGameUsesOnlyItsOwnPack()
    {
        var library = Library();
        // Otomatik: aynı satırda sonraki paket kazanır, bütün paketler aranır.
        Assert.Equal("Gel hadi.", library.Find("Come on."));
        Assert.Equal("Yere yat!", library.Find("Get down!"));

        library.Pinned = "mafia";
        Assert.Equal("Hadi.", library.Find("Come on."));
        Assert.Equal("Götürün onu.", library.Find("Take him away."));
        Assert.Null(library.Find("Get down!"));
        Assert.Equal("mafia", library.SearchScope);

        library.Pinned = null;
        Assert.Equal("Yere yat!", library.Find("Get down!"));
    }

    [Fact]
    public void UnknownPinnedGameFallsBackToAllPacks()
    {
        var library = Library();
        library.Pinned = "silinen-oyun";
        Assert.Equal("Yere yat!", library.Find("Get down!"));
    }

    [Theory]
    [InlineData("HSS: GAETANO: Worries are for tomorrow.", "GAETANO: Worries are for tomorrow.")]
    [InlineData("GAETANO: Worries are for tomorrow.", "GAETANO: Worries are for tomorrow.")]
    [InlineData("Note: the door is open.", "Note: the door is open.")]
    public void LeadingJunkLabelIsDropped(string read, string expected) =>
        Assert.Equal(expected, SpeakerNames.WithoutLeadingJunkLabel(read));
}
