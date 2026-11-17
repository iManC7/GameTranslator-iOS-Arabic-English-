#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
# iOS uygulamasının bağladığı libchiaki'yi (libgtchiaki_ios.a + başlıklar) work/libchiaki-ios altına koyar.
# Kaynak: ios-port dalındaki "iOS native (libchiaki)" iş akışının son başarılı koşusunun libchiaki-ios-arm64 çıktısı
# (mobile/ios-native/build.sh). gh CLI ve depoya okuma izni gerekir.
#   ./mobile/ios/scripts/fetch-libchiaki.sh            # depo kökünden
#   GT_CHIAKI_RUN=<koşu no> ./mobile/ios/scripts/...   # belirli bir koşu
# Kendiniz derlemek isterseniz: ios-port dalında ./mobile/ios-native/build.sh, sonra work/ios-native/out içeriğini
# work/libchiaki-ios altına kopyalayın.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEST="$REPO/work/libchiaki-ios"
BRANCH="${GT_CHIAKI_BRANCH:-ios-port}"
WORKFLOW="ios-native.yml"

RUN="${GT_CHIAKI_RUN:-}"
if [[ -z "$RUN" ]]; then
	RUN="$(gh run list --workflow "$WORKFLOW" --branch "$BRANCH" --status success --limit 1 --json databaseId --jq '.[0].databaseId')"
fi
[[ -n "$RUN" && "$RUN" != "null" ]] || { echo "$BRANCH dalında başarılı $WORKFLOW koşusu bulunamadı." >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "libchiaki-ios-arm64 indiriliyor (koşu $RUN)"
gh run download "$RUN" -n libchiaki-ios-arm64 -D "$TMP"
[[ -f "$TMP/lib/libgtchiaki_ios.a" && -d "$TMP/include/chiaki" ]] || { echo "Çıktıda lib/libgtchiaki_ios.a ya da include/chiaki yok." >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP" "$DEST"
trap - EXIT
echo "$RUN" > "$DEST/RUN_ID"
echo "Hazır: $DEST"
