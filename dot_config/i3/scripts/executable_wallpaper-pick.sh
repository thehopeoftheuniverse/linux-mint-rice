#!/usr/bin/env bash
# Rofi visual grid of installed wallpapers with live thumbnails.
set -euo pipefail

dir="$HOME/.config/wallpapers"
theme="$HOME/.config/rofi/launchers/type-1/style-6.rasi"
switcher="$HOME/.config/scripts/ui/theme-switch.sh"

mapfile -t files < <(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)
[[ ${#files[@]} -gt 0 ]] || { notify-send -a wallpaper "Wallpaper" "No images found in $dir"; exit 0; }

sel="$(for f in "${files[@]}"; do
  printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
done | rofi -dmenu -i -p "󰸉  Wallpaper" -show-icons -theme "$theme" \
  -theme-str 'window {width: 820px;} listview {lines: 2; columns: 3; spacing: 12px;} element {orientation: vertical; padding: 10px; border-radius: 8px;} element-icon {size: 136px;} element-text {horizontal-align: 0.5;}' || true)"

[[ -n "$sel" ]] || exit 0

if [[ "${1:-}" == "--stdout" ]]; then
  printf '%s\n' "$dir/$sel"
elif [[ -x "$switcher" ]]; then
  "$switcher" --wallpaper "$dir/$sel"
else
  feh --bg-fill "$dir/$sel"
fi
