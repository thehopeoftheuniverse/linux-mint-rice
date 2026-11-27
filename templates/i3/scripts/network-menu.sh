#!/usr/bin/env bash
# rofi network switcher on top of nmcli
set -euo pipefail
theme="$HOME/.config/rofi/themes/theme.rasi"

mapfile -t nets < <(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null \
    | awk -F: 'NF && $1!="" {printf "%s  (%s%%)  %s\n", $1, $2, ($3==""?"open":$3)}' | sort -u)

[[ ${#nets[@]} -eq 0 ]] && { notify-send "network" "no wifi networks found"; exit 0; }

sel="$(printf '%s\n' "${nets[@]}" | rofi -dmenu -i -p "wifi" -theme "$theme" \
        -theme-str 'window {width: 480px;} listview {lines: 12;}')"
[[ -z $sel ]] && exit 0

ssid="${sel%%  (*}"
if nmcli -t -f NAME connection show | grep -qx "$ssid"; then
    nmcli connection up id "$ssid" && notify-send "network" "connected to $ssid"
else
    pass="$(rofi -dmenu -password -p "password for $ssid" -theme "$theme" \
            -theme-str 'window {width: 420px;}')"
    nmcli device wifi connect "$ssid" password "$pass" \
        && notify-send "network" "connected to $ssid"
fi
