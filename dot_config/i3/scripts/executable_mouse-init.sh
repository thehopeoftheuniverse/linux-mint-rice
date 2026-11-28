#!/usr/bin/env bash
set -u

# Share substring for the mouse both in wired and wireless mode
MOUSE_PATTERN="Logitech G703 L"

if [[ "${DESKTOP_SESSION:-}" != *"i3"* ]] && [[ -z "${I3SOCK:-}" ]]; then
  exit 0
fi

command -v xinput >/dev/null 2>&1 || exit 0

mapfile -t DEVICES < <(xinput --list --id-only "$MOUSE_PATTERN" 2>/dev/null || true)

for ID in "${DEVICES[@]}"; do
  if [[ -n "$ID" ]]; then
    xinput set-prop "$ID" "libinput Accel Speed" 0.20172043010752688 2>/dev/null || true
    xinput set-prop "$ID" "libinput Accel Profile Enabled" 0 1 0 2>/dev/null || true
  fi
done
