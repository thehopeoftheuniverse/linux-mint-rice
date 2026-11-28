#!/usr/bin/env bash
# Toggle maximizing the focused i3 window to fill the output workarea
# (full screen space excluding Polybar / dock bars), restoring prior state on repeat.
set -euo pipefail

python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp") / f"i3-max-{os.getuid()}"
STATE_DIR.mkdir(parents=True, exist_ok=True)


def i3_cmd(cmd: str) -> None:
    subprocess.run(["i3-msg", cmd], check=True, stdout=subprocess.DEVNULL)


tree = json.loads(subprocess.check_output(["i3-msg", "-t", "get_tree"], text=True))


def find_focused(node, output=None, workspace=None):
    ntype = node.get("type")
    if ntype == "output" and node.get("name") != "__i3":
        output = node
    elif ntype == "workspace":
        workspace = node
    if node.get("focused"):
        return node, output, workspace
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        res = find_focused(child, output, workspace)
        if res[0] is not None:
            return res
    return None, None, None


def find_content_rect(output_node):
    for child in output_node.get("nodes", []):
        if child.get("type") == "con" and child.get("name") == "content":
            return child.get("rect")
    return output_node.get("rect")


focused, output, workspace = find_focused(tree)
if focused is None or output is None:
    raise SystemExit(0)

# If currently fullscreen, exit fullscreen first and re-read geometry so
# state_file records the window's true pre-maximize rect instead of fullscreen.
if focused.get("fullscreen_mode", 0) != 0:
    i3_cmd("fullscreen disable")
    tree = json.loads(subprocess.check_output(["i3-msg", "-t", "get_tree"], text=True))
    focused, output, workspace = find_focused(tree)
    if focused is None or output is None:
        raise SystemExit(0)

win_id = focused.get("id")
state_file = STATE_DIR / f"{win_id}.json"
work_rect = find_content_rect(output)
cur_rect = focused.get("rect") or {}
is_floating = focused.get("floating") in ("user_on", "auto_on")

wx, wy, ww, wh = (
    int(work_rect["x"]),
    int(work_rect["y"]),
    int(work_rect["width"]),
    int(work_rect["height"]),
)

already_max = (
    is_floating
    and abs(int(cur_rect.get("x", -1)) - wx) <= 12
    and abs(int(cur_rect.get("y", -1)) - wy) <= 12
    and abs(int(cur_rect.get("width", -1)) - ww) <= 32
    and abs(int(cur_rect.get("height", -1)) - wh) <= 32
)

if state_file.exists() and already_max:
    prev = json.loads(state_file.read_text(encoding="utf-8"))
    state_file.unlink(missing_ok=True)
    if prev.get("floating"):
        r = prev["rect"]
        i3_cmd(
            f"border pixel 2, floating enable, "
            f"resize set {int(r['width'])} px {int(r['height'])} px, "
            f"move position {int(r['x'])} px {int(r['y'])} px"
        )
    else:
        i3_cmd("floating disable, border pixel 2")
else:
    state_file.write_text(
        json.dumps({"floating": is_floating, "rect": cur_rect}),
        encoding="utf-8",
    )
    i3_cmd(
        f"floating enable, border pixel 0, "
        f"resize set {ww} px {wh} px, "
        f"move position {wx} px {wy} px"
    )
PY
