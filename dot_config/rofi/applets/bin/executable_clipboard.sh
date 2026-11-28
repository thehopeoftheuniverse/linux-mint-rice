#!/usr/bin/env bash
set -u

if command -v xfce4-popup-clipman >/dev/null 2>&1; then
  exec xfce4-popup-clipman
elif command -v greenclip >/dev/null 2>&1; then
  exec rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}' \
    -theme "$HOME/.config/rofi/launchers/type-1/style-6.rasi"
else
  notify-send -a "Clipboard" "Clipboard Manager" "Install xfce4-clipman or greenclip." 2>/dev/null || true
fi
