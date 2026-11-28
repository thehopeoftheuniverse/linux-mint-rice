#!/usr/bin/env bash

shopt -s nullglob

base="/sys/class/power_supply"

for cap in "$base"/*/capacity; do
  dev_dir="${cap%/capacity}"
  dev_name="${dev_dir##*/}"
  case "$dev_name" in
    BAT*|AC*|ADP*|ACAD*|CMB*|ucsi*) continue ;;
  esac
  if [[ -r "$dev_dir/scope" ]] && [[ "$(<"$dev_dir/scope")" == "System" ]]; then
    continue
  fi
  if [[ -r "$cap" ]]; then
    printf '%s%%\n' "$(<"$cap")"
    exit 0
  fi
done

printf 'N/A\n'
