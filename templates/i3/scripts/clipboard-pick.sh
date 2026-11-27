#!/usr/bin/env bash
# Rofi picker over the clipboard history, puts the choice back on the clipboard.
set -euo pipefail
dir="${XDG_CACHE_HOME:-$HOME/.cache}/rice-clip"
hist="$dir/history"
[[ -s $hist ]] || { notify-send -a clipboard "clipboard" "history is empty"; exit 0; }

theme="$HOME/.config/rofi/themes/theme.rasi"
sel="$(awk 'BEGIN{RS="---%%---\n"} NF {gsub(/\n/," "); print substr($0,1,120)}' "$hist" \
    | rofi -dmenu -i -p "clipboard" -theme "$theme" \
        -theme-str 'window {width: 640px;} listview {lines: 14;}')"
[[ -z $sel ]] && exit 0

awk -v needle="$sel" 'BEGIN{RS="---%%---\n"} NF && substr($0,1,120)==needle {print; exit}' "$hist" \
    | xclip -selection clipboard
notify-send -a clipboard "clipboard" "copied back"
