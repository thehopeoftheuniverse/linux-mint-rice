#!/usr/bin/env bash
# up | down | mute | mic-mute  with an OSD-style notification
set -euo pipefail
case "${1:-}" in
    up)       pamixer -i 5 ;;
    down)     pamixer -d 5 ;;
    mute)     pamixer -t ;;
    mic-mute)
        pamixer --default-source -t
        mic_muted="$(pamixer --default-source --get-mute)"
        if [[ $mic_muted == "true" ]]; then
            notify-send -a volume -h string:x-canonical-private-synchronous:mic "Microphone" "Muted"
        else
            notify-send -a volume -h string:x-canonical-private-synchronous:mic "Microphone" "Active"
        fi
        exit 0
        ;;
    *)        echo "usage: volume.sh up|down|mute|mic-mute" >&2; exit 2 ;;
esac

vol="$(pamixer --get-volume)"
muted="$(pamixer --get-mute)"

bar_len=20
filled=$(( vol * bar_len / 100 ))
(( filled < 0 )) && filled=0
(( filled > bar_len )) && filled=$bar_len
empty=$(( bar_len - filled ))

bar=""
for (( i=0; i<filled; i++ )); do bar+="█"; done
for (( i=0; i<empty;  i++ )); do bar+="░"; done

if [[ $muted == "true" ]]; then
    notify-send -a volume -h string:x-canonical-private-synchronous:volume -h int:value:0 "@GLYPH_VOL_MUTE@  Muted" "$bar"
else
    notify-send -a volume -h string:x-canonical-private-synchronous:volume -h int:value:"$vol" \
        "@GLYPH_VOL_UP@  ${vol}%" "$bar"
fi
