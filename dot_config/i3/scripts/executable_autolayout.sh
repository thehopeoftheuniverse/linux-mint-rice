#!/usr/bin/env bash
set -u

# Prefer i3-autolayout if installed; otherwise use built-in Python IPC autotiling daemon
if command -v i3-autolayout >/dev/null 2>&1; then
  killall -q i3-autolayout 2>/dev/null || true
  while pgrep -u "$UID" -x i3-autolayout >/dev/null 2>&1; do
    sleep 0.2
  done
  exec i3-autolayout autolayout
fi

if command -v python3 >/dev/null 2>&1 && [[ -x "$HOME/.config/i3/scripts/autotiling.py" ]]; then
  pkill -u "$UID" -f "i3/scripts/autotiling.py" 2>/dev/null || true
  sleep 0.1
  exec "$HOME/.config/i3/scripts/autotiling.py"
fi
