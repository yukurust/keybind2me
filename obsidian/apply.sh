#!/bin/bash
# obsidian/.obsidian.vimrc を、Obsidian の各保管庫の直下へリンクする。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/obsidian/.obsidian.vimrc"
CONFIG="${HOME}/Library/Application Support/obsidian/obsidian.json"

if [[ ! -f "$SRC" ]]; then
    echo "Obsidian vimrc not found: $SRC" >&2
    exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "==> Obsidian の保管庫一覧が無いので、vimrc はリンクしません。"
    exit 0
fi

python3 - "$SRC" "$CONFIG" <<'PY'
import json
import pathlib
import sys

src, config_path = sys.argv[1:]
config = json.loads(pathlib.Path(config_path).read_text(encoding="utf-8"))
vaults = config.get("vaults") or {}
linked = 0
for vault in vaults.values():
    raw = vault.get("path")
    if not raw:
        continue
    root = pathlib.Path(raw).expanduser()
    if not root.is_dir():
        print(f"==> 保管庫が見つからないので飛ばします: {root}")
        continue
    dest = root / ".obsidian.vimrc"
    if dest.exists() and not dest.is_symlink():
        print(f"==> 既存のファイルがあるので上書きしません: {dest}")
        continue
    if dest.is_symlink() or not dest.exists():
        dest.unlink(missing_ok=True)
        dest.symlink_to(src)
        print(f"==> {dest} -> {src}")
        linked += 1
if linked == 0:
    sys.exit("リンクした保管庫がありません。")
print("==> Obsidian を再起動すると .obsidian.vimrc を読み込みます。")
PY
