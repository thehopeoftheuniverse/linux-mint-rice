#!/usr/bin/env bash
set -u

# Start whichever clipboard daemon is available on Debian/Mint
if command -v xfce4-clipman >/dev/null 2>&1; then
  pkill -u "$UID" -x xfce4-clipman 2>/dev/null || true
  sleep 0.3
  exec /usr/bin/env xfce4-clipman >/tmp/clipman_boot.log 2>&1
elif command -v greenclip >/dev/null 2>&1; then
  pkill -u "$UID" -x greenclip 2>/dev/null || true
  sleep 0.2
  exec greenclip daemon
fi
