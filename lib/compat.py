#!/usr/bin/env python3
"""Adapt the deployed config to the versions actually installed.

Debian 12 / Ubuntu 22.04 ship alacritty 0.12 (YAML, not TOML) and polybar 3.6
(no internal/tray module). Rather than gating those distros out, the config is
rewritten to the shape their binaries understand.

usage: compat.py <config-dir> [--verbose]
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path


def version_of(binary: str) -> tuple[int, int] | None:
    try:
        out = subprocess.run([binary, "--version"], capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return None
    m = re.search(r"(\d+)\.(\d+)", out)
    return (int(m.group(1)), int(m.group(2))) if m else None


def fix_alacritty(conf: Path) -> str | None:
    d = conf / "alacritty"
    toml, yml = d / "alacritty.toml", d / "alacritty.yml"
    ver = version_of("alacritty")
    if ver is None or not (toml.exists() or yml.exists()):
        return None

    if ver < (0, 13):          # YAML only
        if not yml.exists():
            return f"WARNING alacritty {ver[0]}.{ver[1]} needs alacritty.yml but it is missing"
        toml.unlink(missing_ok=True)
        return f"alacritty {ver[0]}.{ver[1]} -> alacritty.yml"
    else:                      # TOML only
        if not toml.exists():
            return f"WARNING alacritty {ver[0]}.{ver[1]} needs alacritty.toml but it is missing"
        yml.unlink(missing_ok=True)
        return f"alacritty {ver[0]}.{ver[1]} -> alacritty.toml"
    return None


def fix_polybar(conf: Path) -> str | None:
    ini = conf / "polybar" / "config.ini"
    ver = version_of("polybar")
    if ver is None or not ini.exists() or ver >= (3, 7):
        return None

    text = ini.read_text()
    if "[module/tray]" not in text:
        return None

    # 3.6 has no internal/tray: drop the module and use the legacy bar keys
    text = re.sub(r"\n\[module/tray\].*?(?=\n\[|\Z)", "\n", text, flags=re.S)
    text = text.replace(" tray ", " ")
    text = re.sub(r"^(modules-right = .*)$",
                  r"\1\ntray-position = right\ntray-padding = 2\ntray-background = ${colors.background}",
                  text, count=1, flags=re.M)
    # 3.6 predates the colorset syntax used above; use the literal bar colour
    bg = re.search(r"^background = (#[0-9a-fA-F]{6})", text, flags=re.M)
    if bg:
        text = text.replace("tray-background = ${colors.background}",
                            f"tray-background = {bg.group(1)}")
    ini.write_text(text)
    return f"polybar {ver[0]}.{ver[1]} -> legacy tray keys"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    conf = Path(sys.argv[1]).expanduser()
    verbose = "--verbose" in sys.argv

    changes = [c for c in (fix_alacritty(conf), fix_polybar(conf)) if c]
    for c in changes:
        print(f"  compat: {c}")
    if verbose and not changes:
        print("  compat: nothing to adapt")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
