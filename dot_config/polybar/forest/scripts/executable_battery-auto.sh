#!/usr/bin/env bash
set -u

shopt -s nullglob

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

C_GREEN="$(theme_color green '#a6e3a1')"
C_PINK="$(theme_color pink '#f5c2e7')"
C_PURPLE="$(theme_color purple '#cba6f7')"

# 1. Laptop/system batteries first (BAT0, BAT1, ...)
for bat in /sys/class/power_supply/BAT*; do
  if [[ -r "$bat/capacity" ]]; then
    cap=$(<"$bat/capacity")
    status="Discharging"
    [[ -r "$bat/status" ]] && status=$(<"$bat/status")
    if [[ "$status" == "Charging" ]]; then
      echo "%{F${C_GREEN}}󰂄%{F-} ${cap}%"
    elif [[ "$status" == "Full" ]]; then
      echo "%{F${C_GREEN}}󰁹%{F-} ${cap}%"
    else
      echo "%{F${C_PINK}}󰁹%{F-} ${cap}%"
    fi
    exit 0
  fi
done

# 2. Fallback to HID wireless peripheral battery (mouse/keyboard) if present
for ps in /sys/class/power_supply/*; do
  name="$(basename "$ps")"
  case "$name" in
    BAT*|AC*|ADP*|ACAD*|CMB*|ucsi*) continue ;;
  esac
  [[ -r "$ps/scope" && "$(<"$ps/scope")" == "System" ]] && continue
  [[ -r "$ps/capacity" ]] || continue
  cap=$(<"$ps/capacity")
  echo "%{F${C_PURPLE}}%{F-} ${cap}%"
  exit 0
done

# Hide cleanly when no battery exists
exit 0
