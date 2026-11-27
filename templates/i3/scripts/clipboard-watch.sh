#!/usr/bin/env bash
# Polls the X clipboard and keeps a deduplicated history (one base64 entry per line).
# Cheap by design: one xclip call per second, nothing when unchanged.
set -u
dir="${XDG_CACHE_HOME:-$HOME/.cache}/rice-clip"
mkdir -p "$dir"
hist="$dir/history.b64"
last_b64=""
touch "$hist"

while :; do
    cur_b64="$(xclip -o -selection clipboard 2>/dev/null | head -c 16384 | base64 -w0 2>/dev/null || true)"
    if [[ -n $cur_b64 && $cur_b64 != "$last_b64" ]]; then
        last_b64="$cur_b64"
        { printf '%s\n' "$cur_b64"; grep -Fxv "$cur_b64" "$hist" 2>/dev/null || true; } \
            | head -n 80 > "$hist.tmp" && mv "$hist.tmp" "$hist"
    fi
    sleep 1
done
