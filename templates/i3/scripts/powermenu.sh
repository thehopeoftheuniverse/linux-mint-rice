#!/usr/bin/env bash
# Rofi power menu
set -euo pipefail

theme="$HOME/.config/rofi/themes/theme.rasi"
sel="$(printf '%s\n' "lock" "logout" "suspend" "reboot" "shutdown" | \
    rofi -dmenu -i -p "" -theme "$theme" \
         -theme-str 'window {width: 300px;} listview {lines: 5;} mainbox {padding: 12px;}')"

[[ -z $sel ]] && exit 0

case "$sel" in
    *lock)     exec "$HOME/.config/i3/scripts/lock.sh" ;;
    *logout)   i3-msg exit ;;
    *suspend)  systemctl suspend ;;
    *reboot)   systemctl reboot ;;
    *shutdown) systemctl poweroff ;;
esac
