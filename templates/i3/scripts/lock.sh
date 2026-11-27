#!/usr/bin/env bash
# Blurred, palette-tinted lockscreen on the current wallpaper.
set -euo pipefail
palette="$HOME/.config/ricing/palette.env"
BG="1a1b26"
if [[ -r $palette ]]; then
    # shellcheck disable=SC1090
    source "$palette"
fi
BG="${BG##*#}"
[[ $BG =~ ^[0-9a-fA-F]{6}$ ]] || BG="1a1b26"

WALL_DIR="$HOME/.local/share/wallpapers"
src="$(cat "$WALL_DIR/current" 2>/dev/null || true)"
if [[ ! -f ${src:-} ]]; then
    src="$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -1 || true)"
fi

res="$(xrandr 2>/dev/null | awk '/\*/ {print $1; exit}')"
[[ $res =~ ^[0-9]+x[0-9]+$ ]] || res="1920x1080"

umask 077
tmp="/tmp/i3lock-$(id -u).png"
IM="$(command -v magick || command -v convert || true)"

if [[ -n $IM && -n ${src:-} && -f $src ]]; then
    "$IM" "$src" -resize "${res}^" -gravity center -extent "$res" \
        -blur 0x16 -fill "#$BG" -colorize 45 "$tmp" 2>/dev/null || true
elif [[ -n $IM ]]; then
    "$IM" -size "$res" "xc:#$BG" "$tmp" 2>/dev/null || true
fi

if [[ -f $tmp ]]; then
    exec i3lock -n -i "$tmp" -t
else
    exec i3lock -n -c "$BG"
fi
