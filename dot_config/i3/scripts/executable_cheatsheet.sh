#!/usr/bin/env bash
# Parse ~/.config/i3/config (and included bind files) and show every binding in rofi.
set -euo pipefail

cfg="$HOME/.config/i3/config"
theme="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

python3 - "$cfg" <<'PY' | rofi -dmenu -i -p "  Keybinds" -theme "$theme" \
  -theme-str 'window {width: 780px;} listview {lines: 14;} element-text {font: "JetBrainsMono Nerd Font 10";}' >/dev/null || true
import os, re, sys

subs = {
    "$mod": "Super",
    "$alt": "Alt",
    "Mod4": "Super",
    "Mod1": "Alt",
    "XF86AudioRaiseVolume": "Vol+",
    "XF86AudioLowerVolume": "Vol-",
    "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "MicMute",
    "XF86MonBrightnessUp": "Bright+",
    "XF86MonBrightnessDown": "Bright-",
    "XF86AudioPlay": "Play",
    "XF86AudioNext": "Next",
    "XF86AudioPrev": "Prev",
}
order = [
    "Super+Return", "Super+space", "Super+t", "Super+b", "Super+f",
    "Super+q", "Super+Shift+m", "Super+Shift+f", "Super+Shift+space", "Super+p",
    "Alt+1", "Alt+2", "Super+F1", "Super+F2",
]
rows = []
seen_files = set()

def parse_file(path):
    path = os.path.expanduser(path)
    if path in seen_files or not os.path.isfile(path):
        return
    seen_files.add(path)
    mode = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\n")
            inc = re.match(r"^\s*include\s+(.+)$", line)
            if inc:
                parse_file(inc.group(1).strip())
                continue
            if re.match(r"\s*\}\s*$", line) and mode:
                mode = None
                continue
            m = re.match(r'\s*mode\s+"(.+?)"\s*\{', line)
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
            if len(action) > 54:
                action = action[:51] + "..."
            prefix = f"[{mode}] " if mode else ""
            rank = order.index(keys) if keys in order else 99
            rows.append((rank, f"{prefix}{keys:<24} {action}"))

parse_file(sys.argv[1])
for _, r in sorted(rows, key=lambda x: (x[0], x[1])):
    print(r)
PY
