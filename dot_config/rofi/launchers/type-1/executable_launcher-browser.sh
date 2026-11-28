#!/usr/bin/env bash
set -u

STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/rofi-launcher"
STYLE_REL="type-1/style-6.rasi"
[[ -r "$STYLE_FILE" ]] && STYLE_REL="$(tr -d '[:space:]' < "$STYLE_FILE")"

THEME_PATH="$HOME/.config/rofi/launchers/$STYLE_REL"
[[ -f "$THEME_PATH" ]] || THEME_PATH="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

if command -v rofi-web-search >/dev/null 2>&1; then
  exec rofi -show search -theme "$THEME_PATH" -no-show-icons -modi search:rofi-web-search
else
  exec rofi -show drun -theme "$THEME_PATH"
fi
