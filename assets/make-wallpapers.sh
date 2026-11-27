#!/usr/bin/env bash
# Procedural wallpapers, one per palette + Tokyo Night abstracts.
set -euo pipefail
exec python3 "$(dirname "${BASH_SOURCE[0]}")/make-wallpapers.py"
