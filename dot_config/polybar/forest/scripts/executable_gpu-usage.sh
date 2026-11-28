#!/usr/bin/env bash
set -u

if command -v nvidia-smi >/dev/null 2>&1; then
  out=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 || true)
  [[ -n "$out" ]] && { echo "${out}%"; exit 0; }
fi

for f in /sys/class/drm/card*/device/gpu_busy_percent; do
  if [[ -r "$f" ]]; then
    echo "$(<"$f")%"
    exit 0
  fi
done

echo "N/A"
