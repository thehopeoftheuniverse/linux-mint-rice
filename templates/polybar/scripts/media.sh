#!/usr/bin/env bash
# Now playing for polybar. Prints nothing at all when no player is active,
# so the module simply disappears instead of leaving a dead icon.
command -v playerctl >/dev/null 2>&1 || exit 0

status="$(playerctl status 2>/dev/null)" || exit 0
case "$status" in
    Playing|Paused) ;;
    *) exit 0 ;;
esac

title="$(playerctl metadata --format '{{title}}' 2>/dev/null)"
[[ -n $title ]] || exit 0
artist="$(playerctl metadata --format '{{artist}}' 2>/dev/null)"

if [[ -n $artist ]]; then
    out="$artist - $title"
else
    out="$title"
fi
(( ${#out} > 38 )) && out="${out:0:37}..."

icon="@GLYPH_PLAY@"
[[ $status == "Paused" ]] && icon="@GLYPH_PAUSE@"

printf '%s  %s\n' "$icon" "$out"
