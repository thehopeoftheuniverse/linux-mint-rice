#!/usr/bin/env bash
# Browse dunst's history in rofi.
set -euo pipefail
command -v dunstctl >/dev/null || { notify-send -a dunst "notifications" "dunstctl not available"; exit 0; }

theme="$HOME/.config/rofi/themes/theme.rasi"
list="$(dunstctl history 2>/dev/null | jq -r '
    .data[0][] | "\(.appname.data // "?"): \(.summary.data // "") \(.body.data // "")"
    | gsub("\\s+"; " ") | .[0:160]' 2>/dev/null)"

[[ -n $list ]] || { notify-send -a dunst "notifications" "history is empty"; exit 0; }

printf '%s\n' "$list" | rofi -dmenu -i -p "notifications" -theme "$theme" \
    -theme-str 'window {width: 720px;} listview {lines: 14;}' >/dev/null
