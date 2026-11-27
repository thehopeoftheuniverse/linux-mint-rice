#!/usr/bin/env bash
# Parse ~/.config/i3/config and show every binding in rofi.
set -euo pipefail
cfg="$HOME/.config/i3/config"
theme="$HOME/.config/rofi/themes/theme.rasi"

python3 - "$cfg" <<'PY' | rofi -dmenu -i -p "@GLYPH_SEARCH@  keybinds" -theme "$theme" \
        -theme-str 'window {width: 760px;} listview {lines: 12;} element-text {font: "JetBrainsMono Nerd Font 10";}' >/dev/null || true
import re, sys

subs = {
    "$mod": "Super", "$term": "alacritty", "$menu": "rofi -show drun",
    "Mod4": "Super", "Mod1": "Alt",
    "XF86AudioRaiseVolume": "Vol+", "XF86AudioLowerVolume": "Vol-",
    "XF86AudioMute": "Mute", "XF86AudioPlay": "Play", "XF86AudioNext": "Next",
    "XF86AudioPrev": "Prev", "XF86AudioStop": "Stop", "XF86AudioMicMute": "MicMute",
}
order = ["Super+Return", "Super+d", "Super+Tab", "Super+q", "Super+f", "Super+space", "Super+v"]
rows = []
mode = None
with open(sys.argv[1], encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if re.match(r"\s*\}\s*$", line) and mode:
            mode = None
            continue
        m = re.match(r"\s*mode\s+\"(.+?)\"\s*\{", line)
        if m:
            mode = m.group(1)
            continue
        m = re.match(r"\s*bindsym\s+(?:--release\s+)?(\S+)\s+(.+)", line)
        if not m:
            continue
        keys, action = m.group(1), m.group(2)
        for k, v in subs.items():
            keys = keys.replace(k, v)
            action = action.replace(k, v)
        action = action.replace("--no-startup-id ", "").replace("exec ", "").strip()
        if len(action) > 52:
            action = action[:49] + "…"
        prefix = f"[{mode}] " if mode else ""
        rank = order.index(keys) if keys in order else 99
        rows.append((rank, f"{prefix}{keys:<24} {action}"))

for _, r in sorted(rows, key=lambda x: (x[0], x[1])):
    print(r)
PY
