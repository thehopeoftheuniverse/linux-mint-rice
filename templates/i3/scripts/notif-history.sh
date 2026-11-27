#!/usr/bin/env bash
# Browse dunst's history in rofi.
set -euo pipefail
command -v dunstctl >/dev/null || { notify-send -a dunst "notifications" "dunstctl not available"; exit 0; }

theme="$HOME/.config/rofi/themes/theme.rasi"
raw="$(dunstctl history 2>/dev/null || true)"
[[ -n $raw ]] || { notify-send -a dunst "notifications" "history is empty"; exit 0; }

list="$(printf '%s' "$raw" | jq -r '
    (.data[0] // [])[] | "\(.appname.data // "?"): \(.summary.data // "") — \(.body.data // "")"
    | gsub("\\s+"; " ") | .[0:140]' 2>/dev/null || true)"

[[ -n $list ]] || { notify-send -a dunst "notifications" "history is empty"; exit 0; }

printf '%s\n' "$list" | rofi -dmenu -i -p "@GLYPH_BELL@  notifications" -theme "$theme" \
    -theme-str 'window {width: 740px;} listview {lines: 12;}' >/dev/null || true
