#!/usr/bin/env bash
set -u

NOTIF_ID=2593
DURATION=1000
VOLUME_STEP=5

notify_vol() {
  local vol="$1"
  local muted="$2"
  if command -v dunstify >/dev/null 2>&1; then
    if [[ "$muted" == "true" ]]; then
      dunstify -a "Volume" -r "$NOTIF_ID" -t "$DURATION" "Volume: Muted"
    else
      dunstify -a "Volume" -r "$NOTIF_ID" -t "$DURATION" -h "int:value:$vol" "Volume: ${vol}%"
    fi
  elif command -v notify-send >/dev/null 2>&1; then
    if [[ "$muted" == "true" ]]; then
      notify-send -a "Volume" -t "$DURATION" -h "string:x-dunst-stack-tag:volume" "Volume: Muted"
    else
      notify-send -a "Volume" -t "$DURATION" -h "string:x-dunst-stack-tag:volume" -h "int:value:$vol" "Volume: ${vol}%"
    fi
  fi
}

get_state_and_notify() {
  local vol="0"
  local muted="false"
  if command -v pamixer >/dev/null 2>&1; then
    vol=$(pamixer --get-volume 2>/dev/null || echo 0)
    muted=$(pamixer --get-mute 2>/dev/null || echo false)
  elif command -v wpctl >/dev/null 2>&1; then
    local out
    out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
    vol=$(awk '{printf "%.0f", $2 * 100}' <<< "$out")
    [[ "$out" == *"[MUTED]"* ]] && muted="true"
  elif command -v pactl >/dev/null 2>&1; then
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1 | tr -d '%')
    [[ "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" == *"yes"* ]] && muted="true"
  fi
  notify_vol "${vol:-0}" "$muted"
}

case "${1:-}" in
  up)
    if command -v pamixer >/dev/null 2>&1; then
      pamixer -i "$VOLUME_STEP"
    elif command -v wpctl >/dev/null 2>&1; then
      wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${VOLUME_STEP}%+"
    elif command -v pactl >/dev/null 2>&1; then
      pactl set-sink-volume @DEFAULT_SINK@ "+${VOLUME_STEP}%"
    fi
    get_state_and_notify
    ;;
  down)
    if command -v pamixer >/dev/null 2>&1; then
      pamixer -d "$VOLUME_STEP"
    elif command -v wpctl >/dev/null 2>&1; then
      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${VOLUME_STEP}%-"
    elif command -v pactl >/dev/null 2>&1; then
      pactl set-sink-volume @DEFAULT_SINK@ "-${VOLUME_STEP}%"
    fi
    get_state_and_notify
    ;;
  mute)
    if command -v pamixer >/dev/null 2>&1; then
      pamixer -t
    elif command -v wpctl >/dev/null 2>&1; then
      wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    elif command -v pactl >/dev/null 2>&1; then
      pactl set-sink-mute @DEFAULT_SINK@ toggle
    fi
    get_state_and_notify
    ;;
esac
