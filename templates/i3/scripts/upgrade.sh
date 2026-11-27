#!/usr/bin/env bash
# Full system upgrade for whichever package manager this machine uses.
set -u
echo "── upgrading with the native package manager"
if command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get full-upgrade -y
elif command -v dnf >/dev/null; then
    sudo dnf upgrade -y
elif command -v pacman >/dev/null; then
    sudo pacman -Syu --noconfirm
else
    echo "no supported package manager found"; exit 1
fi
# let the bar recount instead of showing a stale number
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/rice-updates"
echo
echo "── done. press any key to close"
read -rn1 _
