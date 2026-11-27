#!/usr/bin/env bash
# Now playing for polybar. Prints nothing when no player is active.
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
(( ${#out} > 24 )) && out="${out:0:23}…"

icon="@GLYPH_PLAY@"
color="@GREEN@"
if [[ $status == "Paused" ]]; then
    icon="@GLYPH_PAUSE@"
    color="@YELLOW@"
fi

printf '%%{F%s}%%{T2}%s%%{T-}%%{F-} %%{F@FG_DIM@}%s%%{F-}\n' "$color" "$icon" "$out"
