#!/usr/bin/env bash
set -u

FAN="${1:-fan1}"
command -v sensors >/dev/null 2>&1 || { echo "N/A"; exit 0; }

speed=$(sensors 2>/dev/null | grep -m1 "^${FAN}:" | sed -E "s/^${FAN}:[[:space:]]*//; s/[[:space:]]*RPM.*$//")
if [[ -n "$speed" ]]; then
  echo "$speed RPM"
else
  echo "N/A"
fi
