#!/bin/bash
# vimium/key-mappings を、起動していない Zen の Vimium (storage.sync) に書き込む。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAPPINGS="${ROOT}/vimium/key-mappings"
EXT_ID="{d7742d87-e61d-4b78-b8a1-b469842139fa}"
SETTINGS_VERSION="2.4.2"

if [[ ! -f "$MAPPINGS" ]]; then
    echo "Vimium mappings not found: $MAPPINGS" >&2
    exit 1
fi

if pgrep -x zen >/dev/null 2>&1; then
    echo "==> Zen が起動中のため、Vimium の保存データは書き込みません。終了してから vimium/apply.sh を再実行してください。"
    exit 0
fi

python3 - "$MAPPINGS" "$EXT_ID" "$SETTINGS_VERSION" <<'PY'
import json
import pathlib
import sqlite3
import sys

mappings_path, ext_id, settings_version = sys.argv[1:]
text = pathlib.Path(mappings_path).read_text(encoding="utf-8")
support = pathlib.Path.home() / "Library/Application Support/zen"
profiles = support / "Profiles"
xpi_name = f"{ext_id}.xpi"
matches = [p.parent.parent for p in profiles.glob(f"*/extensions/{xpi_name}")] if profiles.is_dir() else []
if not matches:
    sys.exit("Vimium が入っている Zen プロファイルが見つかりません。")
if len(matches) > 1:
    sys.exit("Vimium のプロファイルが複数あります。どれに書くか決められないので中止しました。")

db_path = matches[0] / "storage-sync-v2.sqlite"
if not db_path.exists():
    sys.exit(f"storage sync が見つかりません: {db_path}")

con = sqlite3.connect(db_path)
try:
    row = con.execute(
        "SELECT data FROM storage_sync_data WHERE ext_id = ?",
        (ext_id,),
    ).fetchone()
    data = json.loads(row[0]) if row and row[0] else {}
    if not isinstance(data, dict):
        data = {}
    data["keyMappings"] = text
    data["settingsVersion"] = settings_version
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    con.execute(
        """
        INSERT INTO storage_sync_data (ext_id, data, sync_change_counter)
        VALUES (?, ?, 1)
        ON CONFLICT(ext_id) DO UPDATE SET
            data = excluded.data,
            sync_change_counter = storage_sync_data.sync_change_counter + 1
        """,
        (ext_id, payload),
    )
    con.commit()
finally:
    con.close()

print(f"==> Vimium の keyMappings を書き込みました: {db_path}")
print("==> Zen を起動すると反映されます。")
PY
