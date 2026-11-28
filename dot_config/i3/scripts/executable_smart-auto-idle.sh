#!/usr/bin/env bash
set -u

SCREENSAVER_TIME="${1:-1200}"
SUSPEND_TIME="${2:-1500}"
LOCK_CMD="$HOME/.config/i3/scripts/i3lock.sh"

# Ensure no duplicate idle managers run
pkill -u "$UID" -x xidlehook 2>/dev/null || true
pkill -u "$UID" -x xautolock 2>/dev/null || true

# Configure X11 DPMS & screensaver baseline
if command -v xset >/dev/null 2>&1; then
  xset s "$SCREENSAVER_TIME" 300 2>/dev/null || true
  xset dpms "$SCREENSAVER_TIME" "$((SCREENSAVER_TIME + 120))" "$((SCREENSAVER_TIME + SUSPEND_TIME))" 2>/dev/null || true
fi

if command -v xidlehook >/dev/null 2>&1; then
  exec xidlehook \
    --not-when-fullscreen \
    --not-when-audio \
    --timer "$SCREENSAVER_TIME" "loginctl lock-session 2>/dev/null || $LOCK_CMD" '' \
    --timer "$SUSPEND_TIME" 'systemctl suspend' ''
fi

# Debian/Mint fallback: xautolock (available via apt)
if command -v xautolock >/dev/null 2>&1; then
  MINS=$(( (SCREENSAVER_TIME + 59) / 60 ))
  [[ "$MINS" -lt 1 ]] && MINS=1
  exec xautolock -detectsleep -time "$MINS" -locker "$LOCK_CMD"
fi
