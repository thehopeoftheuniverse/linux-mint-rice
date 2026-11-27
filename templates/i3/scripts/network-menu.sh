#!/usr/bin/env bash
# rofi network switcher on top of nmcli
set -euo pipefail
command -v nmcli >/dev/null || { notify-send "network" "nmcli (NetworkManager) not available"; exit 0; }
theme="$HOME/.config/rofi/themes/theme.rasi"

list="$(python3 - <<'PY'
import re, subprocess

out = subprocess.run(
    ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"],
    capture_output=True, text=True, check=False
).stdout

best = {}
for raw in out.splitlines():
    parts = re.split(r"(?<!\\):", raw)
    if len(parts) < 4:
        continue
    in_use = parts[0].strip() == "*"
    ssid = parts[1].replace("\\:", ":").strip()
    if not ssid:
        continue
    try:
        sig = int(parts[2])
    except ValueError:
        sig = 0
    sec = parts[3].replace("\\:", ":").strip() or "open"
    prev = best.get(ssid)
    if prev is None or (in_use and not prev[0]) or (sig > prev[1]):
        best[ssid] = (in_use, sig, sec)

for ssid, (in_use, sig, sec) in sorted(best.items(), key=lambda kv: (kv[1][0], kv[1][1]), reverse=True):
    mark = "* " if in_use else "  "
    print(f"{mark}{ssid}\t({sig}%)  {sec}")
PY
)"

[[ -z $list ]] && { notify-send "network" "no wifi networks found"; exit 0; }

sel="$(printf '%s\n' "$list" | rofi -dmenu -i -p "@GLYPH_WIFI@  wifi" -theme "$theme" \
        -theme-str 'window {width: 520px;} listview {lines: 10;}' || true)"
[[ -z $sel ]] && exit 0

ssid="${sel:2}"
ssid="${ssid%%$'\t'*}"

if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    if nmcli connection up id "$ssid"; then
        notify-send "network" "connected to $ssid"
    else
        notify-send -u critical "network" "failed to connect to $ssid"
    fi
else
    pass="$(rofi -dmenu -password -p "@GLYPH_LOCK@  password ($ssid)" -theme "$theme" \
            -theme-str 'window {width: 520px;} entry {placeholder: "enter wifi password…";} listview {enabled: false;}' || true)"
    [[ -z $pass ]] && exit 0
    if nmcli device wifi connect "$ssid" password "$pass"; then
        notify-send "network" "connected to $ssid"
    else
        notify-send -u critical "network" "failed to connect to $ssid"
    fi
fi
