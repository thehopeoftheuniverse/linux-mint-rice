#!/usr/bin/env bash
# Pending package updates, family-aware, cached for an hour so the bar stays cheap.
cache="${XDG_CACHE_HOME:-$HOME/.cache}/rice-updates"
mkdir -p "$(dirname "$cache")"

if [[ -f $cache ]] && (( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) < 3600 )); then
    n="$(cat "$cache")"
else
    n=0
    if command -v apt-get >/dev/null; then
        n="$(apt list --upgradable 2>/dev/null | tail -n +2 | grep -c . || true)"
    elif command -v dnf >/dev/null; then
        n="$(dnf -q check-update 2>/dev/null | grep -cE '^[a-zA-Z0-9]' || true)"
    elif command -v pacman >/dev/null; then
        if command -v checkupdates >/dev/null; then
            n="$(checkupdates 2>/dev/null | wc -l || true)"
        else
            n="$(pacman -Qu 2>/dev/null | wc -l || true)"
        fi
    fi
    n=$((n + 0))
    printf '%s' "$n" > "$cache"
fi

(( n > 0 )) && printf '%%{F@YELLOW@}@GLYPH_UPDATE@ %s%%{F-}\n' "$n"
exit 0
