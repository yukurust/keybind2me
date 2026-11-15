#!/bin/bash
# obsidian/.obsidian.vimrc と、閲覧モード用プラグインを各保管庫へリンクする。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/obsidian/.obsidian.vimrc"
PLUGIN="${ROOT}/obsidian/reading-vim"
CONFIG="${HOME}/Library/Application Support/obsidian/obsidian.json"

if [[ ! -f "$SRC" ]]; then
    echo "Obsidian vimrc not found: $SRC" >&2
    exit 1
fi
if [[ ! -f "$PLUGIN/manifest.json" || ! -f "$PLUGIN/main.js" ]]; then
    echo "Reading vim plugin not found: $PLUGIN" >&2
    exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "==> Obsidian の保管庫一覧が無いので、vimrc はリンクしません。"
    exit 0
fi

python3 - "$SRC" "$PLUGIN" "$CONFIG" <<'PY'
import json
import pathlib
import sys

src, plugin, config_path = sys.argv[1:]
plugin_id = json.loads((pathlib.Path(plugin) / "manifest.json").read_text(encoding="utf-8"))["id"]
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
    else:
        dest.unlink(missing_ok=True)
        dest.symlink_to(src)
        print(f"==> {dest} -> {src}")
        linked += 1
    plugin_dest = root / ".obsidian" / "plugins" / plugin_id
    plugin_dest.parent.mkdir(parents=True, exist_ok=True)
    if plugin_dest.exists() and not plugin_dest.is_symlink():
        print(f"==> 既存のプラグインがあるので上書きしません: {plugin_dest}")
    else:
        plugin_dest.unlink(missing_ok=True)
        plugin_dest.symlink_to(plugin, target_is_directory=True)
        print(f"==> {plugin_dest} -> {plugin}")
        linked += 1
    plugins_file = root / ".obsidian" / "community-plugins.json"
    enabled = []
    if plugins_file.exists():
        enabled = json.loads(plugins_file.read_text(encoding="utf-8"))
    if plugin_id not in enabled:
        enabled.append(plugin_id)
        plugins_file.write_text(json.dumps(enabled, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"==> {plugin_id} を有効にしました: {plugins_file}")
if linked == 0:
    sys.exit("リンクした保管庫がありません。")
print("==> Obsidian を再起動すると、編集画面は .obsidian.vimrc、閲覧画面は reading vim を読みます。")
PY
