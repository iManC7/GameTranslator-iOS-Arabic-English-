#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GameTranslator - Oyun Yaması & Altyazı Dönüştürücü (Patch Converter)
===================================================================
Farklı yama kaynaklarından (Psyama, forumlar, TXT, SRT, CSV) gelen
çeviri dökümlerini GameTranslator uyumlu JSON yamasına dönüştürür.

Kullanım:
    python3 scripts/patch_converter.py -i raw.txt -o patches/oyun.json -g "Oyun Adı"
    python3 scripts/patch_converter.py --en english.txt --tr turkish.txt -o patches/oyun.json -g "Oyun Adı"
    python3 scripts/patch_converter.py --csv dialogues.csv --en-col "Source" --tr-col "Target" -o patches/oyun.json
"""

import os
import sys
import json
import argparse
import csv


def clean_text(text: str) -> str:
    if not text:
        return ""
    text = text.strip()
    # Tırnak işaretlerini düzelt
    text = text.replace("“", "\"").replace("”", "\"").replace("’", "'")
    return text


def parse_delimited_file(file_path: str) -> dict:
    results = {}
    delimiters = ["=", "\t", "|||", "::"]

    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue

            matched = False
            for delim in delimiters:
                if delim in line:
                    parts = line.split(delim, 1)
                    en = clean_text(parts[0])
                    tr = clean_text(parts[1])
                    if en and tr:
                        results[en] = tr
                        matched = True
                        break

            if not matched and ":" in line:
                parts = line.split(":", 1)
                en = clean_text(parts[0])
                tr = clean_text(parts[1])
                # Basit konuşmacı etiketi kontrolü (aşırı uzunsa cümle ayrımı olabilir)
                if en and tr and len(en) < 80:
                    results[en] = tr

    return results


def parse_parallel_files(en_path: str, tr_path: str) -> dict:
    results = {}
    with open(en_path, "r", encoding="utf-8", errors="ignore") as fen, \
         open(tr_path, "r", encoding="utf-8", errors="ignore") as ftr:
        en_lines = [clean_text(line) for line in fen if line.strip()]
        tr_lines = [clean_text(line) for line in ftr if line.strip()]

    count = min(len(en_lines), len(tr_lines))
    for i in range(count):
        en = en_lines[i]
        tr = tr_lines[i]
        if en and tr:
            results[en] = tr

    return results


def parse_csv_file(csv_path: str, en_col: str, tr_col: str) -> dict:
    results = {}
    with open(csv_path, "r", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        for row in reader:
            en = clean_text(row.get(en_col, ""))
            tr = clean_text(row.get(tr_col, ""))
            if en and tr:
                results[en] = tr
    return results


def main():
    parser = argparse.ArgumentParser(description="GameTranslator Topluluk Yaması Dönüştürücüsü")
    parser.add_argument("-i", "--input", help="Tek dosya girdi yolu (.txt, .srt)")
    parser.add_argument("--en", help="İngilizce replikler dosyası (paralel mod)")
    parser.add_argument("--tr", help="Türkçe karşılıklar dosyası (paralel mod)")
    parser.add_argument("--csv", help="CSV dosyası yolu")
    parser.add_argument("--en-col", default="en", help="CSV İngilizce sütun adı (varsayılan: en)")
    parser.add_argument("--tr-col", default="tr", help="CSV Türkçe sütun adı (varsayılan: tr)")
    parser.add_argument("-o", "--output", required=True, help="Çıktı JSON dosya yolu (örn: patches/dead_island_2.json)")
    parser.add_argument("-g", "--game", default="Bilinmeyen Oyun", help="Oyun Adı")
    parser.add_argument("-a", "--author", default="Topluluk", help="Yama Hazırlayıcısı / Çeviri Grubu")

    args = parser.parse_args()

    subtitles = {}

    if args.input:
        if not os.path.exists(args.input):
            print(f"❌ Hata: Girdi dosyası bulunamadı: {args.input}")
            sys.exit(1)
        subtitles = parse_delimited_file(args.input)

    elif args.en and args.tr:
        if not os.path.exists(args.en) or not os.path.exists(args.tr):
            print("❌ Hata: İngilizce veya Türkçe paralel dosya bulunamadı.")
            sys.exit(1)
        subtitles = parse_parallel_files(args.en, args.tr)

    elif args.csv:
        if not os.path.exists(args.csv):
            print(f"❌ Hata: CSV dosyası bulunamadı: {args.csv}")
            sys.exit(1)
        subtitles = parse_csv_file(args.csv, args.en_col, args.tr_col)

    else:
        print("❌ Hata: Lütfen ya bir -i/--input dosyası, ya --en ve --tr dosyaları, ya da --csv belirtin.")
        sys.exit(1)

    if not subtitles:
        print("⚠️ Uyarı: Dosyadan eşleşen altyazı repliği çıkarılamadı!")
        sys.exit(1)

    # JSON Çıktı Yapısı
    patch_data = {
        "game": args.game,
        "author": args.author,
        "version": "1.0",
        "total_lines": len(subtitles),
        "subtitles": subtitles
    }

    out_dir = os.path.dirname(args.output)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(patch_data, f, ensure_ascii=False, indent=2)

    print("=" * 60)
    print(f"✅ Başarılı! {len(subtitles)} replik dönüştürüldü.")
    print(f"🎮 Oyun: {args.game}")
    print(f"📁 Çıktı Dosyası: {args.output}")
    print("=" * 60)
    print("Örnek 3 Replik:")
    for i, (k, v) in enumerate(list(subtitles.items())[:3], 1):
        print(f"  {i}. EN: {k}")
        print(f"     TR: {v}")
    print("=" * 60)


if __name__ == "__main__":
    main()
