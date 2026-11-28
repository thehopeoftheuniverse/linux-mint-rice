#!/usr/bin/env bash
set -u

command -v bluetui >/dev/null 2>&1 || exit 0
command -v bluetoothctl >/dev/null 2>&1 || exit 0

command -v rfkill >/dev/null 2>&1 && rfkill unblock bluetooth 2>/dev/null || true
sleep 1

if ! pgrep -f '^kitty --class bluetui-scrtch' >/dev/null 2>&1; then
  kitty --class 'bluetui-scrtch' bluetui &
  sleep 3
  bluetoothctl power off >/dev/null 2>&1 || true
fi
