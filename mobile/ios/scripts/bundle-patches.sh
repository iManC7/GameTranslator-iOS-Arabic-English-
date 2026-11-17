#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Xcode derleme adımı ("Topluluk yamaları"). Depodaki patches/ klasöründeki topluluk yamaları (bilgisayar sürümüyle aynı
# dosyalar) uygulamanın "packs" klasörüne eklenir:
# - Uygulamayla zaten gelen pakette olanlar (windows/.../Resources/packs/<ad>.gz, aynı içerik) atlanır, diğerleri
#   sıkıştırılarak eklenir.
# - Her yamanın Git blob özeti packs/patches-sha1.txt'ye yazılır; uygulama GitLab'deki yamayla aynı mı diye buna bakar
#   (CommunityPatches.swift) ve yalnız yeni ya da değişenleri indirir.
set -e
SRC="$SRCROOT/../../patches"
PACKS="$SRCROOT/../../windows/src/GameTranslator.Core/Resources/packs"
DEST="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/packs"
[ -d "$SRC" ] || exit 0
mkdir -p "$DEST"
LIST="$DEST/patches-sha1.txt.tmp"
: > "$LIST"
for f in "$SRC"/*.json; do
  [ -f "$f" ] || continue
  n="$(basename "$f")"
  size="$(wc -c < "$f" | tr -d ' ')"
  sha="$( { printf 'blob %s\000' "$size"; cat "$f"; } | shasum -a 1 | cut -d' ' -f1)"
  printf '%s %s\n' "$sha" "$n" >> "$LIST"
  [ -f "$PACKS/$n.gz" ] && continue
  gzip -9 -n -c "$f" > "$DEST/$n.gz"
done
mv "$LIST" "$DEST/patches-sha1.txt"
