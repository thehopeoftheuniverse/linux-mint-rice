#!/usr/bin/env bash
set -u

shopt -s nullglob

# 1. Laptop/system batteries first (BAT0, BAT1, ...)
for bat in /sys/class/power_supply/BAT*; do
  if [[ -r "$bat/capacity" ]]; then
    cap=$(<"$bat/capacity")
    status="Discharging"
    [[ -r "$bat/status" ]] && status=$(<"$bat/status")
    if [[ "$status" == "Charging" ]]; then
      echo "%{F#a6e3a1}󰂄%{F-} ${cap}%"
    elif [[ "$status" == "Full" ]]; then
      echo "%{F#a6e3a1}󰁹%{F-} ${cap}%"
    else
      echo "%{F#f5c2e7}󰁹%{F-} ${cap}%"
    fi
    exit 0
  fi
done

# 2. Fallback to HID wireless peripheral battery (mouse/keyboard) if present
for ps in /sys/class/power_supply/*; do
  [[ -r "$ps/capacity" ]] || continue
  cap=$(<"$ps/capacity")
  echo "%{F#cba6f7}%{F-} ${cap}%"
  exit 0
done

# Hide cleanly when no battery exists
exit 0
