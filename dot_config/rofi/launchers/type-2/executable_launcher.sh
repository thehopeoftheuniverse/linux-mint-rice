#!/usr/bin/env bash
set -u

STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/rofi-launcher"
dir="$HOME/.config/rofi/launchers/type-2"
theme='style-1'
if [[ -r "$STYLE_FILE" ]]; then
  style_rel="$(tr -d '[:space:]' < "$STYLE_FILE")"
  if [[ "$style_rel" == type-2/*.rasi ]] && [[ -f "$HOME/.config/rofi/launchers/$style_rel" ]]; then
    theme="${style_rel#type-2/}"
    theme="${theme%.rasi}"
  fi
fi

exec rofi -show drun -theme "${dir}/${theme}.rasi"
