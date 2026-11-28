#!/usr/bin/env bash
set -u

command -v xrandr >/dev/null 2>&1 || exit 0

HOST_NAME="$(hostname 2>/dev/null || true)"
CONNECTED="$(xrandr --query | awk '/ connected/{print $1}')"

if [[ "$HOST_NAME" == "brozi-desktop" ]] && \
   grep -qx "HDMI-0" <<< "$CONNECTED" && \
   grep -qx "HDMI-1" <<< "$CONNECTED" && \
   grep -qx "DP-2" <<< "$CONNECTED"; then
  xrandr \
    --output HDMI-0 --mode 2560x1440 --rate 144.00 --pos 5120x0 --rotate normal \
    --output DP-0 --off --output DP-1 --off \
    --output HDMI-1 --mode 2560x1440 --rate 144.00 --pos 0x0 --rotate normal \
    --output DP-2 --primary --mode 2560x1440 --rate 144.00 --pos 2560x0 --rotate normal \
    --output DP-3 --off
else
  # Generic Debian/Mint setup: ensure connected outputs are enabled cleanly
  xrandr --auto
fi
