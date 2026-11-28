#!/usr/bin/env bash
set -u

command -v bluetoothctl >/dev/null 2>&1 || exit 0
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  bluetoothctl power off >/dev/null 2>&1
else
  bluetoothctl power on >/dev/null 2>&1
fi
