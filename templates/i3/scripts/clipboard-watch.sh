#!/usr/bin/env bash
# Polls the X clipboard and keeps a deduplicated history file.
# Cheap by design: one xclip call per second, nothing when unchanged.
set -u
dir="${XDG_CACHE_HOME:-$HOME/.cache}/rice-clip"
mkdir -p "$dir"
hist="$dir/history"
last=""
touch "$hist"

while :; do
    cur="$(xclip -o -selection clipboard 2>/dev/null | head -c 10000)"
    if [[ -n $cur && $cur != "$last" ]]; then
        last="$cur"
        # newest first, drop duplicates, keep 80 entries
        { printf '%s\n---%%---\n' "$cur"; cat "$hist"; } \
            | awk 'BEGIN{RS="---%%---\n"} !seen[$0]++' \
            | head -c 200000 > "$hist.tmp" && mv "$hist.tmp" "$hist"
    fi
    sleep 1
done
