#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    lock)     exec "$HOME/.config/i3/scripts/lock.sh" ;;
    logout)   i3-msg exit ;;
    suspend)  systemctl suspend ;;
    reboot)   systemctl reboot ;;
    shutdown) systemctl poweroff ;;
    *)        echo "usage: i3exit.sh lock|logout|suspend|reboot|shutdown" >&2; exit 2 ;;
esac
