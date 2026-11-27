#!/usr/bin/env bash
# Blurred, palette-tinted lockscreen on the current wallpaper.
set -euo pipefail
palette="$HOME/.config/ricing/palette.env"
BG="#1a1b26"
[[ -r $palette ]] && source "$palette" && BG="#$BG"
BG="${BG##\#}"

WALL_DIR="$HOME/.local/share/wallpapers"
src="$(cat "$WALL_DIR/current" 2>/dev/null || true)"
[[ -f ${src:-} ]] || src="$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) | head -1)"

tmp="/tmp/i3lock-$(id -u).png"
IM="$(command -v magick || command -v convert)"
"$IM" "$src" -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -blur 0x14 -fill "#$BG" -colorize 42 "$tmp" 2>/dev/null

i3lock -n -i "$tmp" -t
