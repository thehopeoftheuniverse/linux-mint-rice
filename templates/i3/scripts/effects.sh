#!/usr/bin/env bash
# Switch picom profile:  effects.sh safe | glx [| toggle]
set -euo pipefail
state="$HOME/.config/ricing/effects"
mode="${1:-toggle}"

cur="safe"; [[ -r $state ]] && cur="$(<"$state")"
case "$mode" in
    toggle) [[ $cur == glx ]] && mode=safe || mode=glx ;;
esac

case "$mode" in
    glx)  conf="$HOME/.config/picom/picom-glx.conf" ;;
    safe) conf="$HOME/.config/picom/picom.conf" ;;
    *)    echo "usage: effects.sh [safe|glx|toggle]" >&2; exit 2 ;;
esac

pkill -x picom 2>/dev/null || true
sleep 0.2
nohup picom --config "$conf" >/dev/null 2>&1 &
printf '%s\n' "$mode" > "$state"
notify-send -a picom "compositor" "$mode profile"
