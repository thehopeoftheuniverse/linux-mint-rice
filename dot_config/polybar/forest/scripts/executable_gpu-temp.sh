#!/usr/bin/env bash
set -u

if command -v nvidia-smi >/dev/null 2>&1; then
  out=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -n1 || true)
  [[ -n "$out" ]] && { echo "${out}°C"; exit 0; }
fi

for hw in /sys/class/hwmon/hwmon*; do
  if [[ -r "$hw/name" && "$(<"$hw/name")" == "amdgpu" && -r "$hw/temp1_input" ]]; then
    awk '{printf "%.0f°C\n", $1/1000}' "$hw/temp1_input"
    exit 0
  fi
done

echo "N/A"
