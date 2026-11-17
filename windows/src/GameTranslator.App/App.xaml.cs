// SPDX-License-Identifier: AGPL-3.0-only

using System.Runtime.CompilerServices;
using System.Windows;
using GameTranslator.App.Services;
using GameTranslator.App.Theme;
using GameTranslator.Core;
using GameTranslator.Shell;

namespace GameTranslator.App;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        // İndirilen dosyalardaki Windows Smart App Control (0xc0e90002) ve Zone.Identifier engellerini otomatik kaldır
        StartupGuard.UnblockFiles(AppContext.BaseDirectory);

        // Geliştirme aracı: --repair girdi.txt çıktı.txt — her satırı Windows yazım sözlüğüyle onarır (OcrConfusions).
        if (e.Args is ["--repair", var input, var output])
        {
            UseSpelling();
            // "?" ile başlayan satır: sözcüklerin sözlükte olup olmadığı yazılır.
            var check = SubtitlePipeline.ExtraWordCheck;
            System.IO.File.WriteAllLines(output, System.IO.File.ReadAllLines(input).Select(line => line.StartsWith('?')
                ? string.Join(' ', line[1..].Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(word => $"{word}={check?.Invoke(word)}"))
                : OcrConfusions.Repair(line, check)));
            Shutdown();
            return;
        }
        if (Replay.Options.Parse(e.Args) is { } replay)
        {
            UseSpelling();
            Replay.Run(this, replay);
            return;
        }
        var renderFolder = e.Args is ["--render-screens", var folder] ? folder : null;
        // Eksik bir DLL, onu kullanan yöntem derlenirken hata verir. Bu yüzden denetim ve yakalama burada, uygulamanın
        // kendi türlerine dokunan kod ise ayrı yöntemde (Start) durur.
        var missing = StartupGuard.MissingFiles(AppContext.BaseDirectory);
        if (missing.Count > 0)
        {
            StartupGuard.Fail(this, StartupGuard.MissingMessage(missing), null, renderFolder);
            return;
        }
        if (renderFolder is null) StartupGuard.Watch(this);
        try
        {
            Start(renderFolder);
        }
        catch (Exception error)
        {
            StartupGuard.Fail(this, StartupGuard.ErrorMessage(error), error, renderFolder);
        }
    }

    /// <summary>
    /// Okuma hattına yazım denetimini bağlar: gerçek olmayan sözcük içeren okuma "bozuk" sayılıp kısa süre bekletilir
    /// ve aynı satırın okumalarından sözcükleri gerçek olan seçilir. İngilizce yazım sözlüğü yoksa hiçbir şey değişmez.
    /// </summary>
    static void UseSpelling()
    {
        if (WindowsSpelling.Create("en") is not { } spelling) return;
        var misspelling = new Misspelling(spelling.IsWord);
        SubtitlePipeline.ExtraMisreadCheck = misspelling.LooksMisread;
        SubtitlePipeline.ExtraReadingScore = misspelling.Score;
        SubtitlePipeline.ExtraGarbageCheck = misspelling.IsGarbage;
        SubtitlePipeline.ExtraWordCheck = spelling.IsWord;
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    void Start(string? renderFolder)
    {
        if (renderFolder is not null)
        {
            ScreenRenderer.Run(this, renderFolder);
            return;
        }
        RemotePlayDiagnostics.Start();
        SubtitleLog.Enable();
        UseSpelling();
        ThemeManager.Apply(Resources);
        ThemeManager.Follow(Resources);
        var controller = new AppController(new LiveServices(), new DpapiAppStore(), new FileSettingsStore(), new WindowsSleepGuard(),
            Localizer.Current, action => Dispatcher.BeginInvoke(action))
        {
            // Samsung'un sertifika için giriş sayfası varsayılan tarayıcıda açılır.
            OpenInBrowser = url => System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url.AbsoluteUri) { UseShellExecute = true }),
        };
        var window = new ShellWindow(controller);
        MainWindow = window;
        window.Show();
        // Güçlü okuyucunun modelleri kurulumda yok; ilk açılışta arka planda iner.
        LiveServices.DownloadReaderModelsInBackground();
        LiveServices.RefreshPacksInBackground();
    }
}
