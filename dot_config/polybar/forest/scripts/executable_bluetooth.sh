#!/usr/bin/env bash
set -u

if ! command -v bluetoothctl >/dev/null 2>&1; then
  exit 0
fi

THEME_INI="$HOME/.config/polybar/forest/current-theme.ini"
theme_color() {
  local key="$1" fallback="$2" val=""
  if [[ -r "$THEME_INI" ]]; then
    val=$(awk -F'=' -v k="$key" '$1 ~ "^[[:space:]]*"k"[[:space:]]*$" {gsub(/[[:space:]]/, "", $2); print $2; exit}' "$THEME_INI")
  fi
  if [[ "$val" =~ ^#[0-9a-fA-F]{6,8}$ ]]; then
    printf '%s' "$val"
  else
    printf '%s' "$fallback"
  fi
}

bt_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 2 bluetoothctl "$@" 2>/dev/null
  else
    bluetoothctl "$@" 2>/dev/null
  fi
}

# Hide cleanly when no Bluetooth controller exists
if ! bt_cmd list | grep -q '^Controller '; then
  exit 0
fi

C_MUTED="$(theme_color overlay0 '#6c7086')"
C_ACCENT="$(theme_color accent '#7df9ff')"

if ! bt_cmd show | grep -q "Powered: yes"; then
  echo "%{F${C_MUTED}}󰂲%{F-}"
elif bt_cmd devices Connected | grep -q '^Device '; then
  echo "%{F${C_ACCENT}}󰂱%{F-}"
else
  echo ""
fi
