#!/usr/bin/env bash
# Re-apply the active wallpaper when the X screen size changes.
# feh bakes the root pixmap at the size it ran with; after a VM window resize
# or a RandR mode change the image stays anchored top-left with black bars.
# This watcher re-runs wallpaper-init.sh so the same chosen image is re-fitted.
set -u

command -v feh >/dev/null 2>&1 || exit 0
command -v xdpyinfo >/dev/null 2>&1 || exit 0

# One watcher per user session.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/rice-wallpaper-watch.lock"
flock -n 9 || exit 0

last=""
while :; do
    cur="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
    if [[ -n $cur && $cur != "$last" ]]; then
        # Skip the first reading: wallpaper-init.sh already ran at startup.
        if [[ -n $last ]]; then
            sleep 0.3   # let RandR settle before feh reads the root size
            "$HOME/.config/i3/scripts/wallpaper-init.sh" >/dev/null 2>&1 || true
        fi
        last="$cur"
    fi
    sleep 2
done
