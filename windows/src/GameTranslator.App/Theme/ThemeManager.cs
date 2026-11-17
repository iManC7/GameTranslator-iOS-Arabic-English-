// SPDX-License-Identifier: AGPL-3.0-only

using System.Windows;
using System.Windows.Media;
using GameTranslator.Core;
using Microsoft.Win32;

namespace GameTranslator.App.Theme;

/// <summary>
/// design/tokens.json'daki değerleri uygulama kaynaklarına çevirir. Renkler Windows'un uygulama
/// temasını (açık/koyu) izler; XAML bunları DynamicResource ile kullanır, tema değişince anında güncellenir.
/// </summary>
public static class ThemeManager
{
    private static readonly DesignTokens Tokens = DesignTokens.Shared;

    public static void Apply(ResourceDictionary resources, bool? forceDark = null)
    {
        // GameTranslator bir oyun uygulamasıdır; her zaman modern ve şık Koyu Temayı (Dark Theme) kullanır.
        var dark = forceDark ?? true;
        foreach (var (name, pair) in Tokens.Color)
        {
            var color = ToColor(pair.For(dark));
            resources[$"{name}Color"] = color;
            var brush = new SolidColorBrush(color);
            brush.Freeze();
            resources[$"{name}Brush"] = brush;
        }
        foreach (var (name, font) in Tokens.Font)
        {
            resources[$"{name}FontSize"] = font.Size;
            resources[$"{name}FontWeight"] = font.Weight switch
            {
                "bold" => FontWeights.Bold,
                "semibold" => FontWeights.SemiBold,
                "medium" => FontWeights.Medium,
                _ => FontWeights.Normal,
            };
        }
        foreach (var (name, value) in Tokens.Space)
        {
            resources[$"space.{name}"] = value;
            resources[$"pad.{name}"] = new Thickness(value);
        }
        foreach (var (name, value) in Tokens.Radius) resources[$"radius.{name}"] = new CornerRadius(value);
        foreach (var (name, value) in Tokens.Size) resources[$"size.{name}"] = value;
        ApplyGlass(resources);
    }

    /// <summary>
    /// Mobil uygulamayla aynı görünüm (koyu, cam yüzeyli): iOS'un koyu sistem renkleri, yarı saydam kartlar, büyük
    /// köşe yarıçapları ve koyu lacivert geçişli zemin. tokens.json'daki adların üstüne yazar; XAML değişmeden yeni
    /// görünümü alır. Ek kaynaklar: windowBrush (zemin geçişi), cardBrush, wellBrush, hairlineBrush, glowBrush.
    /// </summary>
    private static void ApplyGlass(ResourceDictionary resources)
    {
        void Solid(string name, Color color)
        {
            resources[$"{name}Color"] = color;
            var brush = new SolidColorBrush(color);
            brush.Freeze();
            resources[$"{name}Brush"] = brush;
        }

        Solid("background", Color.FromRgb(0x07, 0x0A, 0x12));
        Solid("surface", Color.FromArgb(0x14, 0xFF, 0xFF, 0xFF));       // cam yüzey
        Solid("card", Color.FromArgb(0x12, 0xFF, 0xFF, 0xFF));
        Solid("cardStrong", Color.FromArgb(0x24, 0xFF, 0xFF, 0xFF));    // seçili bölme, basılı düğme
        Solid("well", Color.FromArgb(0x59, 0x00, 0x00, 0x00));          // içe gömük alan (önizleme, liste)
        Solid("border", Color.FromArgb(0x26, 0xFF, 0xFF, 0xFF));
        Solid("hairline", Color.FromArgb(0x1A, 0xFF, 0xFF, 0xFF));
        Solid("textPrimary", Color.FromRgb(0xFF, 0xFF, 0xFF));
        Solid("textSecondary", Color.FromArgb(0x99, 0xEB, 0xEB, 0xF5));
        Solid("textTertiary", Color.FromArgb(0x4D, 0xEB, 0xEB, 0xF5));
        Solid("accent", Color.FromRgb(0x0A, 0x84, 0xFF));
        Solid("onAccent", Color.FromRgb(0xFF, 0xFF, 0xFF));
        Solid("accentText", Color.FromRgb(0x40, 0x9C, 0xFF));
        Solid("accentSoft", Color.FromArgb(0x33, 0x0A, 0x84, 0xFF));
        Solid("success", Color.FromRgb(0x30, 0xD1, 0x58));
        Solid("successSoft", Color.FromArgb(0x2E, 0x30, 0xD1, 0x58));
        Solid("warning", Color.FromRgb(0xFF, 0x9F, 0x0A));
        Solid("danger", Color.FromRgb(0xFF, 0x45, 0x3A));
        Solid("dangerSoft", Color.FromArgb(0x2E, 0xFF, 0x45, 0x3A));
        Solid("onDanger", Color.FromRgb(0xFF, 0xFF, 0xFF));
        Solid("idle", Color.FromArgb(0x66, 0xEB, 0xEB, 0xF5));

        // Zemin: üst solda mavi, sağda mor bir parıltı, altta siyaha yakın lacivert (mobildeki GlassBackground).
        var window = new LinearGradientBrush { StartPoint = new Point(0, 0), EndPoint = new Point(1, 1) };
        window.GradientStops.Add(new GradientStop(Color.FromRgb(0x0B, 0x25, 0x4A), 0));
        window.GradientStops.Add(new GradientStop(Color.FromRgb(0x0A, 0x10, 0x22), 0.42));
        window.GradientStops.Add(new GradientStop(Color.FromRgb(0x1A, 0x10, 0x2C), 0.78));
        window.GradientStops.Add(new GradientStop(Color.FromRgb(0x07, 0x0A, 0x12), 1));
        window.Freeze();
        resources["windowBrush"] = window;

        var glow = new RadialGradientBrush { GradientOrigin = new Point(0.5, 0.5), Center = new Point(0.5, 0.5), RadiusX = 0.5, RadiusY = 0.5 };
        glow.GradientStops.Add(new GradientStop(Color.FromArgb(0x66, 0x0A, 0x84, 0xFF), 0));
        glow.GradientStops.Add(new GradientStop(Color.FromArgb(0x00, 0x0A, 0x84, 0xFF), 1));
        glow.Freeze();
        resources["glowBrush"] = glow;

        resources["radius.control"] = new CornerRadius(12);
        resources["radius.card"] = new CornerRadius(20);
        resources["radius.pill"] = new CornerRadius(999);
    }

    /// <summary>Tema değişince kaynakları yeniler.</summary>
    public static void Follow(ResourceDictionary resources)
    {
        SystemEvents.UserPreferenceChanged += (_, e) =>
        {
            if (e.Category == UserPreferenceCategory.General)
                Application.Current.Dispatcher.Invoke(() => Apply(resources, true));
        };
    }

    public static bool IsDarkTheme()
    {
        return true;
    }

    private static Color ToColor(string hex)
    {
        var (r, g, b) = DesignTokens.Rgb(hex) ?? (0, 0, 0);
        return Color.FromRgb((byte)Math.Round(r * 255), (byte)Math.Round(g * 255), (byte)Math.Round(b * 255));
    }
}
