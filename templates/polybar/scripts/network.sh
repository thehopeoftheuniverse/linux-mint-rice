#!/usr/bin/env bash
# Active network indicator for polybar: shows Wi-Fi SSID or wired IP.
set -u

if command -v nmcli >/dev/null 2>&1; then
    active="$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null \
        | awk -F: '$2=="connected" && ($1=="wifi" || $1=="ethernet") {print $1 ":" $3; exit}')"
    if [[ -n $active ]]; then
        kind="${active%%:*}"
        name="${active#*:}"
        (( ${#name} > 12 )) && name="${name:0:11}…"
        if [[ $kind == "wifi" ]]; then
            printf '%%{F@TEAL@}%%{T2}@GLYPH_WIFI@%%{T-}%%{F-} %s\n' "$name"
        else
            printf '%%{F@TEAL@}%%{T2}@GLYPH_NET@%%{T-}%%{F-} %s\n' "$name"
        fi
        exit 0
    fi
fi

iface="${NET_IF:-}"
if [[ -z $iface ]]; then
    iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
fi
if [[ -n $iface ]]; then
    ip_addr="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)"
    if [[ -n $ip_addr ]]; then
        printf '%%{F@TEAL@}%%{T2}@GLYPH_NET@%%{T-}%%{F-} %s\n' "$ip_addr"
        exit 0
    fi
fi

printf '%%{F@MUTED@}%%{T2}@GLYPH_NET@%%{T-} offline%%{F-}\n'
