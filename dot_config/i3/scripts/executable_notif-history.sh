#!/usr/bin/env bash
# Browse dunst's notification history in rofi.
set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-1/style-6.rasi"
command -v dunstctl >/dev/null 2>&1 || { notify-send -a dunst "Notifications" "dunstctl not available"; exit 0; }
command -v jq >/dev/null 2>&1 || { notify-send -a dunst "Notifications" "Install jq to view history"; exit 0; }

raw="$(dunstctl history 2>/dev/null || true)"
[[ -n "$raw" ]] || { notify-send -a dunst "Notifications" "History is empty"; exit 0; }

list="$(printf '%s' "$raw" | jq -r '
  (.data[0] // [])[] | "\(.appname.data // "?"): \(.summary.data // "") — \(.body.data // "")"
  | gsub("\\s+"; " ") | .[0:140]' 2>/dev/null || true)"

[[ -n "$list" ]] || { notify-send -a dunst "Notifications" "History is empty"; exit 0; }

printf '%s\n' "$list" | rofi -dmenu -i -p "  Notifications" -theme "$theme" \
  -theme-str 'window {width: 740px;} listview {lines: 12;}' >/dev/null || true
