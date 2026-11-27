#!/usr/bin/env bash
# area | full | window  → ~/Pictures/Screenshots + clipboard
set -euo pipefail
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-area}" in
    area)   maim -s -u "$file" ;;
    full)   maim -u "$file" ;;
    window) maim -u -i "$(xdotool getactivewindow)" "$file" ;;
    *)      echo "usage: screenshot.sh [area|full|window]" >&2; exit 2 ;;
esac

[[ -s $file ]] || exit 0
xclip -selection clipboard -t image/png -i "$file"
notify-send -a screenshot -i "$file" "screenshot saved" "$(basename "$file")"
