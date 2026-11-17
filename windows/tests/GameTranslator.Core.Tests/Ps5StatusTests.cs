// SPDX-License-Identifier: AGPL-3.0-only

using System.Text;

namespace GameTranslator.Core.Tests;

public class Ps5StatusTests
{
    [Fact]
    public void RunningGameIsReadFromTheDiscoveryReply()
    {
        var info = Ps5Status.Parse("HTTP/1.1 200 Ok\nhost-id:ABC\nhost-type:PS5\nhost-name:PS5-471\nhost-request-port:997\n" +
                                   "running-app-titleid:PPSA01234_00\nrunning-app-name:Mafia: The Old Country\n");
        Assert.NotNull(info);
        Assert.True(info!.Awake);
        Assert.Equal("PS5-471", info.HostName);
        Assert.Equal(new RunningGame("PPSA01234_00", "Mafia: The Old Country"), info.Game);
    }

    [Fact]
    public void RestingOrHomeScreenHasNoGame()
    {
        var resting = Ps5Status.Parse("HTTP/1.1 620 Server Standby\nhost-name:PS5-471\n");
        Assert.False(resting!.Awake);
        Assert.Null(resting.Game);
        Assert.Null(Ps5Status.Parse("SRCH * HTTP/1.1\n"));
    }

    private static (string, byte[]) Pack(string id, string title) =>
        ($"{id}.json", Encoding.UTF8.GetBytes($"{{\"format\":1,\"id\":\"{id}\",\"title\":\"{title}\",\"entries\":{{\"{PackKey.Key("Come on.")}\":\"Hadi.\"}}}}"));

    /// PS5'in bildirdiği ad paketin başlığıyla eşleşir; uyan paket elle seçilmiş gibi kullanılır.
    [Fact]
    public void RunningGameNameFindsItsPack()
    {
        var library = new GamePackLibrary(() =>
        [
            Pack("mafia-the-old-country", "Mafia: The Old Country"),
            Pack("gta-v", "Grand Theft Auto V"),
            Pack("death-stranding-2", "Death Stranding 2: On the Beach"),
        ], null);
        Assert.Equal("mafia-the-old-country", library.FindByGameName("Mafia: The Old Country"));
        Assert.Equal("gta-v", library.FindByGameName("Grand Theft Auto V"));
        Assert.Equal("death-stranding-2", library.FindByGameName("DEATH STRANDING 2: ON THE BEACH"));
        Assert.Null(library.FindByGameName("FINAL FANTASY VII REMAKE INTERGRADE"));
        library.Detected = "gta-v";
        Assert.Equal("Grand Theft Auto V", library.ScopeTitle);
    }
}
