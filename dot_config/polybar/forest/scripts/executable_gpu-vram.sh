#!/usr/bin/env bash
set -u

if command -v nvidia-smi >/dev/null 2>&1; then
  out=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>/dev/null | head -n1 || true)
  [[ -n "$out" ]] && { echo "$out"; exit 0; }
fi

for used in /sys/class/drm/card*/device/mem_info_vram_used; do
  total="${used%_used}_total"
  if [[ -r "$used" && -r "$total" ]]; then
    awk '{a[NR]=$1/1048576} END {printf "%.0f/%.0f MiB\n", a[1], a[2]}' "$used" "$total"
    exit 0
  fi
done

echo "N/A"
