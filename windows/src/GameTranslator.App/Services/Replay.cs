// SPDX-License-Identifier: AGPL-3.0-only

using System.Diagnostics;
using System.IO;
using System.Windows;
using GameTranslator.Core;
using GameTranslator.RemotePlay;
using GameTranslator.Shell;

namespace GameTranslator.App.Services;

/// <summary>
/// Geliştirme aracı: <c>GameTranslator.exe --replay video.mp4 --ffmpeg ffmpeg.exe --log günlük.log [--ss 60] [--t 300]</c>
/// bir oynanış videosunu PS5 akışı yerine kaynak olarak oynatır. Uygulamanın gerçek okuma hattı (otomatik altyazı
/// şeridi, okuyucular, temizlik, çeviri) pencere açılmadan çalışır; olanlar verilen altyazı günlüğüne yazılır. Okuma
/// hattı gerçek saatle çalıştığı için video gerçek hızında oynatılır. Kullanıcının ayarlarına, eşleştirme anahtarlarına
/// ve TV'sine dokunulmaz (ayarlar ve depo yalnız bellektedir).
/// </summary>
public static class Replay
{
    public sealed record Options(string Video, string Ffmpeg, string Log, double Start, double Length)
    {
        public static Options? Parse(string[] args)
        {
            if (args.Length == 0 || args[0] != "--replay" || args.Length < 2) return null;
            string Value(string name, string fallback)
            {
                var at = Array.IndexOf(args, name);
                return at >= 0 && at + 1 < args.Length ? args[at + 1] : fallback;
            }
            var number = System.Globalization.CultureInfo.InvariantCulture;
            return new Options(args[1], Value("--ffmpeg", "ffmpeg"), Value("--log", Path.ChangeExtension(args[1], ".log")),
                double.Parse(Value("--ss", "0"), number), double.Parse(Value("--t", "0"), number));
        }
    }

    public static void Run(Application app, Options options)
    {
        app.ShutdownMode = ShutdownMode.OnExplicitShutdown;
        SubtitleLog.Enable(options.Log);
        SubtitleLog.Write($"replay: {Path.GetFileName(options.Video)} başlangıç={options.Start:0} sn süre={options.Length:0} sn");
        var session = new VideoStreamSession(options);
        LiveServices.ReplayStream = () => session;
        var controller = new AppController(new LiveServices(), new MemoryStore(), new MemorySettings(), new NoSleepGuard(),
            Localizer.Current, action => app.Dispatcher.BeginInvoke(action));
        session.Ended += () => app.Dispatcher.BeginInvoke(async () =>
        {
            // Bekleyen satırların çevirisi gelsin.
            await Task.Delay(4000);
            controller.Stop();
            SubtitleLog.Write("replay: bitti");
            SubtitleLog.Flush();
            app.Shutdown();
        });
        _ = StartAsync(controller);
    }

    private static async Task StartAsync(AppController controller)
    {
        await controller.StartAsync();
        // TV görünümünü bilgisayarda çizecek araç bu adrese bağlanır (8787 kurulu uygulamadaysa başka bir port olur).
        SubtitleLog.Write($"replay: sunucu http://127.0.0.1:{controller.ServerPort}");
    }

    private sealed class MemoryStore : IAppStore
    {
        private readonly Dictionary<string, object?> values = [];
        public void Save<T>(string key, T value) => values[key] = value;
        public T? Load<T>(string key) => values.TryGetValue(key, out var value) && value is T typed ? typed : default;
        public void Remove(string key) => values.Remove(key);
    }

    private sealed class MemorySettings : ISettingsStore
    {
        // Altyazı görünümü (yerleşim, boy, zemin) kullanıcınınkiyle aynı olsun diye ayar dosyasından okunur; dosyaya
        // hiçbir şey yazılmaz.
        private UserSettings settings = new() { VideoSource = VideoSourceType.DesktopScreen, AutoRegion = true, Style = new FileSettingsStore().Load().Style };
        public UserSettings Load() => settings;
        public void Save(UserSettings value) => settings = value;
    }

    private sealed class NoSleepGuard : ISleepGuard
    {
        public void Begin() { }
        public void End() { }
    }

    /// <summary>Videoyu ffmpeg ile gerçek hızında çözüp kareleri (1920x1080, saniyede 15) akış gibi verir.</summary>
    private sealed class VideoStreamSession(Options options) : IStreamSession
    {
        private const int Width = 1920, Height = 1080, Fps = 15;
        public event Action<Frame>? FrameReceived;
        public event Action<SessionState>? StateChanged;
#pragma warning disable CS0067
        public event Action<RegisteredConsole>? ConsoleMoved;
#pragma warning restore CS0067
        public event Action? Ended;
        private Process? process;

        public void Start()
        {
            StateChanged?.Invoke(SessionState.Connecting);
            var number = System.Globalization.CultureInfo.InvariantCulture;
            var info = new ProcessStartInfo(options.Ffmpeg)
            {
                RedirectStandardOutput = true,
                RedirectStandardError = false,
                UseShellExecute = false,
                CreateNoWindow = true,
            };
            foreach (var argument in new[] { "-v", "error", "-nostdin", "-re", "-ss", options.Start.ToString(number) })
                info.ArgumentList.Add(argument);
            if (options.Length > 0)
            {
                info.ArgumentList.Add("-t");
                info.ArgumentList.Add(options.Length.ToString(number));
            }
            foreach (var argument in new[]
                     {
                         "-i", options.Video, "-an", "-vf",
                         $"fps={Fps},scale={Width}:{Height}:force_original_aspect_ratio=decrease,pad={Width}:{Height}:(ow-iw)/2:(oh-ih)/2",
                         "-f", "rawvideo", "-pix_fmt", "bgra", "-",
                     })
                info.ArgumentList.Add(argument);
            process = Process.Start(info)!;
            new Thread(ReadLoop) { IsBackground = true, Name = "replay" }.Start();
        }

        private void ReadLoop()
        {
            try
            {
                var stream = process!.StandardOutput.BaseStream;
                var size = Width * Height * 4;
                var count = 0;
                while (true)
                {
                    var pixels = new byte[size];
                    var read = 0;
                    while (read < size)
                    {
                        var got = stream.Read(pixels, read, size - read);
                        if (got <= 0) break;
                        read += got;
                    }
                    if (read < size) break;
                    if (count == 0) StateChanged?.Invoke(SessionState.Streaming);
                    // Günlükteki saatle videonun saniyesi eşlensin diye on saniyede bir işaret.
                    if (count % (Fps * 10) == 0) SubtitleLog.Write($"replay: t={options.Start + ((double)count / Fps):0}");
                    count++;
                    FrameReceived?.Invoke(new Frame(pixels, Width, Height, Width * 4));
                }
            }
            catch (Exception error) when (error is IOException or ObjectDisposedException or InvalidOperationException)
            {
                // ffmpeg kapandı.
            }
            Ended?.Invoke();
        }

        public void Stop()
        {
            try { if (process is { HasExited: false }) process.Kill(); } catch (InvalidOperationException) { }
        }

        public void ReconnectNow() { }

        public void Dispose() => process?.Dispose();
    }
}
