#!/usr/bin/env bash
set -u

# Toggle kitty-monitor scratchpad if present in i3, otherwise launch btop/htop in kitty.
if command -v i3-msg >/dev/null 2>&1 && i3-msg -t get_tree 2>/dev/null | grep -q '"class":"kitty-monitor"'; then
  i3-msg '[class="^kitty-monitor$"] scratchpad show' >/dev/null 2>&1 && exit 0
fi

if command -v kitty >/dev/null 2>&1; then
  if command -v btop >/dev/null 2>&1; then
    exec kitty --class 'kitty-monitor' --override window_margin_width=0 -e btop
  elif command -v htop >/dev/null 2>&1; then
    exec kitty --class 'kitty-monitor' -e htop
  else
    exec kitty --class 'kitty-monitor' -e top
  fi
fi
