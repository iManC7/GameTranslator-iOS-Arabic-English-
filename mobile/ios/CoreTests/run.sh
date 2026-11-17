#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Runner/Core/*.swift'i testlerle birlikte swiftc ile derleyip çalıştırır (XCTest gerekmez).
# Kullanım: CoreTests/run.sh [derleme klasörü]   (varsayılan: $TMPDIR altında geçici klasör; depoya yazılmaz)
# SWIFT_VERSION=6 ile Swift 6 dil kipinde derlenir (varsayılan 5).
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$HERE/../Runner"
REPO="$(cd "$HERE/../../.." && pwd)"
# Ortak deneme dosyaları (Android testleriyle aynı) ve uygulamayla gelen paketler (Kotlin'deki "gametranslator.packs").
# GT_PACKS_DIR boş verilirse gömülü paket denemeleri atlanır.
export GT_FIXTURES_DIR="${GT_FIXTURES_DIR:-$REPO/mobile/android/app/src/test/resources/fixtures}"
export GT_PACKS_DIR="${GT_PACKS_DIR-$REPO/windows/src/GameTranslator.Core/Resources/packs}"
[ -n "$GT_PACKS_DIR" ] || unset GT_PACKS_DIR

if [ $# -ge 1 ]; then
  BUILD="$1"
  mkdir -p "$BUILD"
else
  BUILD="$(mktemp -d "${TMPDIR:-/tmp}/gt-coretests.XXXXXX")"
  trap 'rm -rf "$BUILD"' EXIT
fi

# TextBox tek kaynaktan gelir: SubtitleServer.swift'teki tanım çıkarılır (dosyanın geri kalanı Network/uygulama ister).
awk '/^struct TextBox[: {]/ { on = 1 } on { print } on && /^}/ { exit }' "$RUNNER/SubtitleServer.swift" > "$BUILD/TextBox.swift"
if ! grep -q 'struct TextBox' "$BUILD/TextBox.swift"; then
  echo "TextBox tanımı $RUNNER/SubtitleServer.swift içinde bulunamadı" >&2
  exit 1
fi

xcrun swiftc -swift-version "${SWIFT_VERSION:-5}" -O \
  -module-name CoreTests \
  -module-cache-path "$BUILD/module-cache" \
  "$RUNNER"/Core/*.swift "$BUILD/TextBox.swift" \
  "$HERE/Harness.swift" "$HERE/CoreTest.swift" "$HERE/GlossaryTest.swift" "$HERE/SpeakerNameTest.swift" "$HERE/ButtonHintsTest.swift" \
  "$HERE/GamePacksTest.swift" "$HERE/PackFuzzyTest.swift" "$HERE/PackPipelineTest.swift" "$HERE/PackStoreTest.swift" \
  "$HERE/main.swift" \
  -o "$BUILD/coretests"

# macOS libmalloc bırakılan büyük blokları önbellekte tutar (iOS'ta yok); bellek ölçümü (PackMemoryTest) şişmesin.
MallocLargeCache=0 "$BUILD/coretests"
