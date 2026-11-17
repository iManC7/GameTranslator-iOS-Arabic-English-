// SPDX-License-Identifier: AGPL-3.0-only

namespace GameTranslator.Core.Tests;

/// Elle yazılan PS5/TV adresi (CouchSubs 4c1f6ec, #50).
public class ManualAddressTests
{
    [Theory]
    [InlineData("192.168.1.5", "192.168.1.5")]
    [InlineData("  192.168.1.5 \n", "192.168.1.5")]
    [InlineData("192.168.1.5:3000", "192.168.1.5")]
    [InlineData("http://192.168.1.5", "192.168.1.5")]
    [InlineData("ws://192.168.1.5:3000/", "192.168.1.5")]
    [InlineData("192.168.1.5/", "192.168.1.5")]
    [InlineData("192,168,1,5", "192.168.1.5")]
    [InlineData("192.168.001.005", "192.168.1.5")]
    [InlineData("LGwebOSTV.local", "lgwebostv.local")]
    public void CleansWhatUsersType(string input, string expected) => Assert.Equal(expected, ManualAddress.Normalize(input));

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("192.168.1")]
    [InlineData("192.168.1.256")]
    [InlineData("192.168.1.5.6")]
    [InlineData("192.168.1. 5")]
    [InlineData("192..1.5")]
    [InlineData("lg tv")]
    [InlineData("fe80::1")]
    [InlineData("192.168.1.5:")]
    [InlineData("192.168.1.5:abc")]
    [InlineData("http://")]
    [InlineData("%")]
    [InlineData("-tv.local")]
    [InlineData("192.168.1.5\t6")]
    public void RejectsWhatIsNotAnAddress(string input) => Assert.Null(ManualAddress.Normalize(input));

    /// Temizlenmiş her adresle TV bağlantı adresleri kurulabilir.
    [Theory]
    [InlineData("192.168.1.5:3000")]
    [InlineData(" 10.0.0.2 ")]
    [InlineData("http://172.16.0.9/")]
    [InlineData("lgwebostv.local")]
    public void NormalizedAddressesMakeValidEndpoints(string input)
    {
        var host = ManualAddress.Normalize(input);
        Assert.NotNull(host);
        Assert.True(Uri.TryCreate($"wss://{host}:3001", UriKind.Absolute, out _));
        Assert.True(Uri.TryCreate($"ws://{host}:8002/api/v2/channels/samsung.remote.control", UriKind.Absolute, out _));
    }
}
