#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Feather (AltStore biçimli) kaynağını üretir/günceller.

Bir sürüm IPA'sından CFBundleIdentifier, CFBundleShortVersionString, MinimumOSVersion ve dosya boyutunu okur,
mevcut source.json'a versions[] başına ekler (eski sürümler kalır, aynı sürüm ikinci kez eklenmez).
Kullanım: build_source.py --template feather/source.template.json --ipa X.ipa --tag ios-v1.0.6 \
          --date 2026-11-15T21:20:49Z --repo SimonPetrus/GameTranslator-iOS --existing source.json --out source.json
"""
import argparse, json, os, plistlib, re, sys, zipfile


EXPECTED_BUNDLE = "com.gametranslator.gametranslatorMobile"


def read_ipa(path):
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(names) != 1:
            sys.exit(f"HATA: IPA'da tam bir Payload/*.app/Info.plist olmalı, bulunan: {len(names)} ({path})")
        name = names[0]
        info = plistlib.loads(z.read(name))
    return info, os.path.getsize(path)


def main():
    a = argparse.ArgumentParser()
    for k in ("template", "ipa", "tag", "date", "repo", "out"):
        a.add_argument("--" + k, required=True)
    a.add_argument("--existing", default="")
    a.add_argument("--notes", default="")
    a = a.parse_args()

    info, size = read_ipa(a.ipa)
    bundle = info.get("CFBundleIdentifier")
    version = info.get("CFBundleShortVersionString")
    if bundle != EXPECTED_BUNDLE:
        sys.exit(f"HATA: bundle id {bundle!r}, beklenen {EXPECTED_BUNDLE!r}; kaynak değiştirilmedi")
    if not version:
        sys.exit("HATA: IPA'da CFBundleShortVersionString yok; kaynak değiştirilmedi")
    tag_version = a.tag[len("ios-v"):] if a.tag.startswith("ios-v") else a.tag
    if tag_version != version:
        sys.exit(f"HATA: etiket sürümü {tag_version!r}, IPA sürümü {version!r}; kaynak değiştirilmedi")
    min_os = info.get("MinimumOSVersion", "15.0")

    with open(a.template, encoding="utf-8") as f:
        src = json.load(f)
    app = src["apps"][0]
    app["bundleIdentifier"] = bundle

    old = []
    if a.existing and os.path.exists(a.existing):
        try:
            with open(a.existing, encoding="utf-8") as f:
                prev = json.load(f)
            old = prev["apps"][0]["versions"]
            if not isinstance(old, list):
                raise TypeError("versions liste değil")
        except (ValueError, KeyError, IndexError, TypeError) as e:
            sys.exit(f"HATA: mevcut kaynak dosyası bozuk veya boş ({a.existing}): {e!r}; sıfırdan başlanmadı")

    url = f"https://github.com/{a.repo}/releases/download/{a.tag}/{os.path.basename(a.ipa)}"
    entry = {
        "version": version,
        "date": a.date,
        "size": size,
        "downloadURL": url,
        "minOSVersion": min_os,
        "localizedDescription": a.notes or f"GameTranslator iPhone sürümü {version}.",
    }
    # aynı sürüm ikinci kez eklenmez: varsa güncellenir
    versions = [v for v in old if v.get("version") != version] + [entry]
    versions.sort(key=lambda v: v.get("date", ""), reverse=True)
    app["versions"] = versions
    top = versions[0]
    app["version"] = top["version"]
    app["versionDate"] = top["date"]
    app["size"] = top["size"]
    app["downloadURL"] = top["downloadURL"]

    with open(a.out, "w", encoding="utf-8", newline="\n") as f:
        json.dump(src, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"{bundle} {version} minOS={min_os} size={size} -> {a.out}")


if __name__ == "__main__":
    sys.exit(main())
