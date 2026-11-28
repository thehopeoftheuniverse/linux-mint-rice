#!/usr/bin/env bash
set -u

NOTIFY_ICON=/usr/share/icons/Papirus/32x32/apps/system-software-update.svg
LAST_COUNT=-1

get_total_updates() {
  UPDATES=$("$HOME/.config/polybar/forest/scripts/updates-apt" 2>/dev/null | grep -c -v '^$' || true)
}

while true; do
  get_total_updates

  if [[ "$UPDATES" != "$LAST_COUNT" ]] && command -v notify-send >/dev/null 2>&1; then
    icon_arg=()
    [[ -f "$NOTIFY_ICON" ]] && icon_arg=(-i "$NOTIFY_ICON")
    if (( UPDATES > 20 )); then
      notify-send -u critical "${icon_arg[@]}" "Updates available" "$UPDATES pending packages"
    elif (( UPDATES > 10 )); then
      notify-send -u normal "${icon_arg[@]}" "Updates available" "$UPDATES pending packages"
    fi
    LAST_COUNT="$UPDATES"
  fi

  if (( UPDATES > 0 )); then
    echo "$UPDATES"
  else
    echo "0"
  fi

  # Guard against missing inotifywait so the loop never spins at 100% CPU
  if command -v inotifywait >/dev/null 2>&1 && [[ -e /var/lib/dpkg/status ]]; then
    inotifywait -e modify /var/lib/dpkg/status -t 7200 >/dev/null 2>&1 || sleep 60
  else
    sleep 1800
  fi
done
