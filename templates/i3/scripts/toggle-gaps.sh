#!/usr/bin/env bash
# Toggle inner/outer gaps between the configured layout and a zero-gap layout.
# Always keeps top clearance for the floating Polybar.
set -euo pipefail
cfg="$HOME/.config/i3/config"
state="${XDG_CACHE_HOME:-$HOME/.cache}/rice-gaps"
mkdir -p "$(dirname "$state")"

default_inner="$(awk '/^gaps inner / {print $3; exit}' "$cfg" 2>/dev/null || echo 12)"
default_outer="$(awk '/^gaps outer / {print $3; exit}' "$cfg" 2>/dev/null || echo 8)"
default_top="$(awk '/^gaps top / {print $3; exit}' "$cfg" 2>/dev/null || echo 48)"
default_inner="${default_inner:-12}"
default_outer="${default_outer:-8}"
default_top="${default_top:-48}"

cur=1
[[ -r $state ]] && cur="$(<"$state")"

if [[ $cur == 1 ]]; then
    i3-msg 'gaps inner all set 0' >/dev/null
    i3-msg 'gaps outer all set 0' >/dev/null
    i3-msg "gaps top all set $default_top" >/dev/null
    echo 0 > "$state"
    notify-send -a i3 "gaps" "off"
else
    i3-msg "gaps inner all set $default_inner" >/dev/null
    i3-msg "gaps outer all set $default_outer" >/dev/null
    i3-msg "gaps top all set $default_top" >/dev/null
    echo 1 > "$state"
    notify-send -a i3 "gaps" "on (${default_inner}/${default_outer})"
fi
