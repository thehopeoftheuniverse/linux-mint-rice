#!/usr/bin/env bash
# Rofi picker over the clipboard history; puts the selected entry back on the clipboard.
set -euo pipefail
dir="${XDG_CACHE_HOME:-$HOME/.cache}/rice-clip"
hist="$dir/history.b64"
[[ -s $hist ]] || { notify-send -a clipboard "clipboard" "history is empty"; exit 0; }

theme="$HOME/.config/rofi/themes/theme.rasi"
idx="$(python3 - "$hist" <<'PY' | rofi -dmenu -i -format i -p "@GLYPH_CLIP@  clipboard" -theme "$theme" \
        -theme-str 'window {width: 680px;} listview {lines: 12;}' || true
import base64, sys

with open(sys.argv[1], encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            text = base64.b64decode(line).decode("utf-8", errors="replace")
        except Exception:
            continue
        preview = " ↵ ".join(text.splitlines()).strip()
        if len(preview) > 100:
            preview = preview[:97] + "…"
        print(preview if preview else "(whitespace)")
PY
)"
[[ -z $idx ]] && exit 0

python3 - "$hist" "$idx" <<'PY' | xclip -selection clipboard
import base64, sys

target = int(sys.argv[2])
entries = []
with open(sys.argv[1], encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if line:
            entries.append(line)
if 0 <= target < len(entries):
    sys.stdout.buffer.write(base64.b64decode(entries[target]))
PY
notify-send -a clipboard "clipboard" "copied to clipboard"
