#!/usr/bin/env bash
# Switch picom profile:  effects.sh [safe|glx|toggle|restore] [--quiet]
set -euo pipefail
state="$HOME/.config/ricing/effects"
mkdir -p "$(dirname "$state")"

mode="${1:-toggle}"
quiet="${2:-}"

detect_default() {
    if command -v glxinfo >/dev/null 2>&1; then
        local info
        info="$(glxinfo -B 2>/dev/null || true)"
        if [[ -n $info ]] && ! grep -qiE 'llvmpipe|softpipe|swrast|svga3d|vmware' <<<"$info"; then
            echo "glx"
            return
        fi
    fi
    echo "safe"
}

if [[ -r $state ]]; then
    cur="$(<"$state")"
else
    cur="$(detect_default)"
fi

case "$mode" in
    toggle)  [[ $cur == glx ]] && mode=safe || mode=glx ;;
    restore) mode="$cur"; quiet="--quiet" ;;
esac

case "$mode" in
    glx)  conf="$HOME/.config/picom/picom-glx.conf" ;;
    safe) conf="$HOME/.config/picom/picom.conf" ;;
    *)    echo "usage: effects.sh [safe|glx|toggle|restore] [--quiet]" >&2; exit 2 ;;
esac

log="${XDG_CACHE_HOME:-$HOME/.cache}/picom.log"
mkdir -p "$(dirname "$log")"
pkill -x picom 2>/dev/null || true
sleep 0.2
nohup picom --config "$conf" >"$log" 2>&1 &
printf '%s\n' "$mode" > "$state"
[[ $quiet == "--quiet" ]] || notify-send -a picom "compositor" "$mode profile active"
