#!/usr/bin/env bash
# Rofi power menu
set -euo pipefail

theme="$HOME/.config/rofi/themes/theme.rasi"
sel="$(printf '%s\n' \
    "@GLYPH_LOCK@   Lock" \
    "@GLYPH_LOGOUT@   Logout" \
    "@GLYPH_MOON@   Suspend" \
    "@GLYPH_SYNC@   Reboot" \
    "@GLYPH_POWER@   Shutdown" | \
    rofi -dmenu -i -p "@GLYPH_POWER@  power" -theme "$theme" \
         -theme-str 'window {width: 320px;} entry {enabled: false;} listview {lines: 5;} mainbox {padding: 14px;}' || true)"

[[ -z $sel ]] && exit 0

case "$sel" in
    *Lock)     exec "$HOME/.config/i3/scripts/lock.sh" ;;
    *Logout)   i3-msg exit ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
