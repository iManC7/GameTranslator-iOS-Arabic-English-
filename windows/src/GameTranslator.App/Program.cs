// SPDX-License-Identifier: AGPL-3.0-only

using Velopack;

namespace GameTranslator.App;

public static class Program
{
    /// <summary>
    /// Velopack kurulum, güncelleme ve kaldırma sırasında uygulamayı kısa süreli çağırır; bu kancalar WPF başlamadan
    /// işlenip çıkılır. Normal açılışta hiçbir şey yapmadan döner.
    /// </summary>
    [STAThread]
    public static void Main(string[] args)
    {
        try { VelopackApp.Build().Run(); } catch { }

        // Eğer arka planda takılı kalmış eski bir kopya varsa port 8787'yi ve TV bağlantısını kilitlemesin diye sonlandır
        // (Geliştirme araçları (--replay, --repair) kurulu uygulamanın yanında çalışır; ona dokunmaz.)
        if (args is not (["--replay", ..] or ["--repair", ..] or ["--render-screens", ..])) try
        {
            var current = System.Diagnostics.Process.GetCurrentProcess();
            foreach (var p in System.Diagnostics.Process.GetProcessesByName("GameTranslator"))
            {
                if (p.Id != current.Id)
                {
                    try { p.Kill(); } catch { }
                }
            }
        }
        catch { }

        var app = new App();
        app.InitializeComponent();
        app.Run();
    }
}
