# SPDX-License-Identifier: AGPL-3.0-only
"""Uygulama simgesinden Android simgelerini, açılış ekranı görselini ve Flutter logosunu üretir.

Kullanım: python tool/make_icons.py   (mobile/ klasöründen; Pillow gerekir)
Kaynak: mac/GameTranslator/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOBILE = os.path.dirname(HERE)
SOURCE = os.path.join(MOBILE, "..", "mac", "GameTranslator", "Resources", "Assets.xcassets", "AppIcon.appiconset",
                      "icon_512x512@2x.png")
RES = os.path.join(MOBILE, "android", "app", "src", "main", "res")
# Uyarlanabilir simgenin zemini: simgenin kenar rengine yakın koyu ton.
BACKGROUND = (7, 10, 18, 255)

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def save(image, *parts):
    path = os.path.join(*parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)
    return path


def centered(icon, canvas, scale, background=(0, 0, 0, 0)):
    """Simgeyi kare tuvalin ortasına, tuvalin [scale] oranında yerleştirir."""
    size = round(canvas * scale)
    layer = Image.new("RGBA", (canvas, canvas), background)
    resized = icon.resize((size, size), Image.LANCZOS)
    layer.alpha_composite(resized, ((canvas - size) // 2, (canvas - size) // 2))
    return layer


def main():
    icon = Image.open(SOURCE).convert("RGBA")
    for name, factor in DENSITIES.items():
        # Eski tip simge (48dp) ve uyarlanabilir simgenin ön katmanı (108dp; maske ortadaki ~72dp'yi gösterir).
        save(centered(icon, round(48 * factor), 1.0), RES, f"mipmap-{name}", "ic_launcher.png")
        save(centered(icon, round(108 * factor), 0.80, BACKGROUND), RES, f"mipmap-{name}", "ic_launcher_foreground.png")
        # Açılış ekranı: Android 12+ simgeyi daire içinde gösterir (288dp tuvalin ortasındaki 192dp görünür).
        save(centered(icon, round(288 * factor), 0.62), RES, f"drawable-{name}", "splash_icon.png")
        # Android 11 ve öncesi: ortada duran logo.
        save(centered(icon, round(160 * factor), 1.0), RES, f"drawable-{name}", "splash_logo.png")
    save(centered(icon, 512, 1.0), MOBILE, "assets", "logo.png")
    print("ok")


if __name__ == "__main__":
    sys.exit(main())
