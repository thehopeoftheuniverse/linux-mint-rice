#!/usr/bin/env bash
# Rofi grid of the installed wallpapers, applies the pick.
set -euo pipefail
dir="$HOME/.local/share/wallpapers"
theme="$HOME/.config/rofi/themes/theme.rasi"

mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) | sort)
[[ ${#files[@]} -gt 0 ]] || { notify-send -a wallpaper "wallpaper" "no images in $dir"; exit 0; }

sel=""
for f in "${files[@]}"; do
    printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
done | rofi -dmenu -i -p "wallpaper" -show-icons -theme "$theme" \
        -theme-str 'window {width: 620px;} listview {lines: 8; columns: 2;} element-icon {size: 72px;}' \
        > /tmp/rice-wallpick.$$ || true
sel="$(cat /tmp/rice-wallpick.$$ 2>/dev/null)"; rm -f /tmp/rice-wallpick.$$

[[ -z $sel ]] && exit 0
"$HOME/.config/i3/scripts/wallpaper.sh" "$dir/$sel"
