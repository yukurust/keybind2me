#!/bin/bash
# homerow/com.superultra.Homerow.plist のキーだけを Homerow の設定へ書き、起動し直す。
# ライセンスなど、このファイルに無いキーは残す。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/homerow/com.superultra.Homerow.plist"
DOMAIN="com.superultra.Homerow"

if [[ ! -f "$SRC" ]]; then
    echo "Homerow preferences not found: $SRC" >&2
    exit 1
fi
if [[ ! -d /Applications/Homerow.app ]]; then
    echo "Homerow.app がありません。install.sh を実行するか、brew install --cask homerow してください。" >&2
    exit 1
fi

plutil -lint "$SRC" >/dev/null

CURRENT="$(mktemp -t homerow-current.plist)"
MERGED="$(mktemp -t homerow-merged.plist)"
trap 'rm -f "$CURRENT" "$MERGED"' EXIT

if defaults export "$DOMAIN" "$CURRENT" 2>/dev/null; then
    :
else
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict/></plist>\n' > "$CURRENT"
fi

python3 - "$CURRENT" "$SRC" "$MERGED" <<'PY'
import plistlib
import sys

current_path, src_path, merged_path = sys.argv[1:]
with open(current_path, "rb") as handle:
    current = plistlib.load(handle)
with open(src_path, "rb") as handle:
    managed = plistlib.load(handle)
current.update(managed)
with open(merged_path, "wb") as handle:
    plistlib.dump(current, handle)
PY

if pgrep -x Homerow >/dev/null; then
    killall Homerow
    for _ in 1 2 3 4 5; do
        pgrep -x Homerow >/dev/null || break
        sleep 0.2
    done
fi

defaults import "$DOMAIN" "$MERGED"
open -a Homerow
echo "==> Homerow の設定を読み込み、起動しました。"
