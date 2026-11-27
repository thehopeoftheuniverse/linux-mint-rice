#!/usr/bin/env python3
"""Print the deployed i3 workspace name for an index (glyph names make shell parsing awkward)."""
import pathlib, re, sys

cfg = pathlib.Path.home() / ".config/i3/config"
m = re.search(rf'^set \$ws{re.escape(sys.argv[1])} "(.*)"', cfg.read_text(), re.M)
print(m.group(1) if m else "")
