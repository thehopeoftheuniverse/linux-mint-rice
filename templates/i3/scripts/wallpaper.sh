#!/usr/bin/env bash
# Set / rotate the wallpaper.  --random | --restore | <path>
set -euo pipefail
DIR="$HOME/.local/share/wallpapers"
CUR="$DIR/current"

pick_random() {
    find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
        ! -name 'current' | sort | shuf -n1
}

case "${1:---restore}" in
    --random)
        img="$(pick_random)"
        ;;
    --restore)
        if [[ -s $CUR ]]; then img="$(<"$CUR")"; else img="$(pick_random)"; fi
        ;;
    *)
        img="$1"
        ;;
esac

[[ -f $img ]] || { echo "wallpaper: no image found in $DIR" >&2; exit 1; }

feh --no-fehbg --bg-fill "$img"
printf '%s\n' "$img" > "$CUR"
feh --no-fehbg --bg-fill "$img"   # re-apply after a reload
[[ "${2:-}" == "--quiet" ]] || notify-send -a wallpaper -i "$img" "wallpaper" "$(basename "$img")"
