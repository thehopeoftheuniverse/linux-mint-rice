#!/usr/bin/env bash
# Toggle inner/outer gaps cleanly while keeping current layout clearance.
set -euo pipefail

cfg="$HOME/.config/i3/config"
state="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-gaps"
mkdir -p "$(dirname "$state")"

default_inner="$(awk '/^gaps inner / {print $3; exit}' "$cfg" 2>/dev/null || echo 10)"
default_outer="$(awk '/^gaps outer / {print $3; exit}' "$cfg" 2>/dev/null || echo 5)"
default_inner="${default_inner:-10}"
default_outer="${default_outer:-5}"

cur=1
[[ -r "$state" ]] && cur="$(<"$state")"

if [[ "$cur" == "1" ]]; then
  i3-msg 'gaps inner all set 0' >/dev/null
  i3-msg 'gaps outer all set 0' >/dev/null
  echo 0 > "$state"
  command -v notify-send >/dev/null 2>&1 && notify-send -a i3 "Gaps" "Off (focus mode)"
else
  i3-msg "gaps inner all set $default_inner" >/dev/null
  i3-msg "gaps outer all set $default_outer" >/dev/null
  echo 1 > "$state"
  command -v notify-send >/dev/null 2>&1 && notify-send -a i3 "Gaps" "On (${default_inner}/${default_outer})"
fi
