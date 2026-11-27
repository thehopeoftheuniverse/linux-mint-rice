#!/usr/bin/env bash
# up | down | mute  with an OSD-style notification
set -euo pipefail
case "${1:-}" in
    up)   pamixer -i 5 ;;
    down) pamixer -d 5 ;;
    mute) pamixer -t ;;
    *)    echo "usage: volume.sh up|down|mute" >&2; exit 2 ;;
esac

vol="$(pamixer --get-volume)"
muted="$(pamixer --get-mute)"

bar_len=20
filled=$(( vol * bar_len / 100 ))
bar="$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))$(printf '░%.0s' $(seq 1 $((bar_len - filled)) 2>/dev/null))"

if [[ $muted == "true" ]]; then
    notify-send -a volume -h string:x-canonical-private-synchronous:volume -h int:value:0 "  muted" ""
else
    notify-send -a volume -h string:x-canonical-private-synchronous:volume -h int:value:"$vol" \
        "  ${vol}%" "$bar"
fi
