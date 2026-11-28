#!/usr/bin/env bash
set -u

command -v feh >/dev/null 2>&1 || exit 0

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
WALLPAPER_FILE="$STATE_DIR/wallpaper"
THEME_FILE="$STATE_DIR/theme"
WP_DIR="$HOME/.config/wallpapers"

if [[ -r "$WALLPAPER_FILE" ]]; then
  WP="$(cat "$WALLPAPER_FILE")"
  if [[ -f "$WP" ]]; then
    feh --bg-fill "$WP"
    exit 0
  fi
fi

if [[ -x "$HOME/.fehbg" ]]; then
  "$HOME/.fehbg"
  exit 0
fi

THEME="catppuccin-mocha"
[[ -r "$THEME_FILE" ]] && THEME="$(tr -d '[:space:]' < "$THEME_FILE")"

case "$THEME" in
  ultra-instinct|ultra-instinct-omen)
    DEFAULT_WP="$WP_DIR/ultra-instinct.jpg"
    ;;
  tokyo-night)
    DEFAULT_WP="$WP_DIR/City-Night.png"
    ;;
  rose-pine)
    DEFAULT_WP="$WP_DIR/sakura-gate.jpg"
    ;;
  *)
    DEFAULT_WP="$WP_DIR/catppuccin-wallpaper-25-hq.png"
    ;;
esac

if [[ -f "$DEFAULT_WP" ]]; then
  feh --bg-fill "$DEFAULT_WP"
else
  first_wp=$(find "$WP_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)
  [[ -n "$first_wp" ]] && feh --bg-fill "$first_wp"
fi
