#!/usr/bin/env bash
set -u

command -v nvidia-settings >/dev/null 2>&1 || { echo "N/A"; exit 0; }
speed=$(nvidia-settings -t -q GPUCurrentFanSpeedRPM 2>/dev/null | head -n1 || true)

if [[ -n "$speed" ]]; then
  echo "$speed RPM"
else
  echo "N/A"
fi
