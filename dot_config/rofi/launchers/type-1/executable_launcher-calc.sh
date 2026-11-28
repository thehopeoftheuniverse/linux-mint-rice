#!/usr/bin/env bash
set -u

STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/rofi-launcher"
STYLE_REL="type-1/style-6.rasi"
[[ -r "$STYLE_FILE" ]] && STYLE_REL="$(tr -d '[:space:]' < "$STYLE_FILE")"

THEME_PATH="$HOME/.config/rofi/launchers/$STYLE_REL"
[[ -f "$THEME_PATH" ]] || THEME_PATH="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

if rofi -dump-config 2>/dev/null | grep -qi calc || [[ -f /usr/lib/x86_64-linux-gnu/rofi/calc.so || -f /usr/lib/rofi/calc.so ]]; then
  exec rofi -show calc -theme "$THEME_PATH" -no-show-icons -modi calc
else
  exec rofi -show run -theme "$THEME_PATH"
fi
