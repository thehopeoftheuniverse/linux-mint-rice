#!/usr/bin/env bash
set -u

if ! command -v bluetoothctl >/dev/null 2>&1; then
  exit 0
fi

# Hide cleanly when no Bluetooth controller exists
if ! bluetoothctl list 2>/dev/null | grep -q '^Controller '; then
  exit 0
fi

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  echo "%{F#6c7086}󰂲%{F-}"
elif bluetoothctl devices Connected 2>/dev/null | grep -q '^Device '; then
  echo "%{F#7df9ff}󰂱%{F-}"
else
  echo ""
fi
