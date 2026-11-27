#!/usr/bin/env bash
# Toggle inner/outer gaps between the normal and a zero-gap layout.
set -euo pipefail
state="${XDG_CACHE_HOME:-$HOME/.cache}/rice-gaps"
mkdir -p "$(dirname "$state")"
cur=1; [[ -r $state ]] && cur="$(<"$state")"

if [[ $cur == 1 ]]; then
    i3-msg 'gaps inner all set 0' >/dev/null
    i3-msg 'gaps outer all set 0' >/dev/null
    echo 0 > "$state"
    notify-send -a i3 "gaps" "off"
else
    i3-msg 'gaps inner all set 8' >/dev/null
    i3-msg 'gaps outer all set 10' >/dev/null
    echo 1 > "$state"
    notify-send -a i3 "gaps" "on"
fi
