#!/usr/bin/env bash
# Rofi grid of the installed wallpapers, applies the pick.
set -euo pipefail
dir="$HOME/.local/share/wallpapers"
theme="$HOME/.config/rofi/themes/theme.rasi"

mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
[[ ${#files[@]} -gt 0 ]] || { notify-send -a wallpaper "wallpaper" "no images in $dir"; exit 0; }

sel="$(for f in "${files[@]}"; do
    printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
done | rofi -dmenu -i -p "@GLYPH_PICTURE@  wallpaper" -show-icons -theme "$theme" \
        -theme-str 'window {width: 780px;} listview {lines: 2; columns: 3; spacing: 12px;} element {orientation: vertical; padding: 10px; border-radius: 8px;} element-icon {size: 136px;} element-text {horizontal-align: 0.5;}' || true)"

[[ -z $sel ]] && exit 0
"$HOME/.config/i3/scripts/wallpaper.sh" "$dir/$sel"
