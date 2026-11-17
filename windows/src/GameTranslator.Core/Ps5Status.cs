// SPDX-License-Identifier: AGPL-3.0-only

using System.Net;
using System.Net.Sockets;
using System.Text;

namespace GameTranslator.Core;

/// <summary>
/// PS5'e keşif sorusu (UDP 9302, "SRCH"): açık mı ve o an hangi oyun çalışıyor. Yanıt satırlarından
/// <c>running-app-titleid</c> ve <c>running-app-name</c> okunur (chiaki-ng discovery.c ile aynı biçim). Soru PS5'i
/// uyandırmaz; dinlenmedeyse yanıt 620 koduyla gelir ya da hiç gelmez. CouchSubs bu bilgiyi yerel kütüphane üzerinden
/// alıyor (d44bfe2); burada kütüphaneyi yeniden derlemeden doğrudan sorulur.
/// </summary>
public static class Ps5Status
{
    public const int Port = 9302;
    private const string Request = "SRCH * HTTP/1.1\ndevice-discovery-protocol-version:00030010\n";

    /// <param name="Awake">Yanıt kodu 200 (açık); 620 dinlenmede.</param>
    public sealed record Info(bool Awake, string? HostName, RunningGame? Game);

    /// <summary>PS5'in yanıtı; yanıt gelmezse (kapalı, ağda değil) ya da okunamazsa null.</summary>
    public static async Task<Info?> QueryAsync(string host, TimeSpan timeout, CancellationToken cancellationToken = default)
    {
        if (!IPAddress.TryParse(host, out var address)) return null;
        using var udp = new UdpClient(address.AddressFamily);
        var request = Encoding.ASCII.GetBytes(Request);
        using var limit = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        limit.CancelAfter(timeout);
        try
        {
            await udp.SendAsync(request, new IPEndPoint(address, Port), limit.Token).ConfigureAwait(false);
            while (true)
            {
                var reply = await udp.ReceiveAsync(limit.Token).ConfigureAwait(false);
                if (!reply.RemoteEndPoint.Address.Equals(address)) continue;
                return Parse(Encoding.UTF8.GetString(reply.Buffer));
            }
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return null; }
        catch (SocketException) { return null; }
    }

    /// <summary>"HTTP/1.1 200 Ok" ve "anahtar:değer" satırları; ilk satır HTTP değilse null.</summary>
    public static Info? Parse(string text)
    {
        var lines = text.Replace("\r", "").Split('\n');
        if (lines.Length == 0 || !lines[0].StartsWith("HTTP/", StringComparison.Ordinal)) return null;
        var parts = lines[0].Split(' ', 3);
        var awake = parts.Length > 1 && parts[1] == "200";
        var headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var line in lines.Skip(1))
        {
            var colon = line.IndexOf(':');
            if (colon <= 0) continue;
            headers[line[..colon].Trim()] = line[(colon + 1)..].Trim();
        }
        return new Info(awake, headers.GetValueOrDefault("host-name"),
            RunningGame.Create(headers.GetValueOrDefault("running-app-titleid"), headers.GetValueOrDefault("running-app-name")));
    }
}
