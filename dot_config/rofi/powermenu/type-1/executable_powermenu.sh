#!/usr/bin/env bash
set -u

STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/rofi-powermenu"
STYLE_REL="type-1/style-1.rasi"
[[ -r "$STYLE_FILE" ]] && STYLE_REL="$(tr -d '[:space:]' < "$STYLE_FILE")"

THEME_PATH="$HOME/.config/rofi/powermenu/$STYLE_REL"
[[ -f "$THEME_PATH" ]] || THEME_PATH="$HOME/.config/rofi/powermenu/type-1/style-1.rasi"

uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

if grep -q 'USE_BUTTONS=YES' "$THEME_PATH" 2>/dev/null; then
  shutdown='⏻'
  reboot='󰜉'
  lock=''
  suspend='󰤄'
  logout='󰍃'
  yes=''
  no=''
else
  shutdown='⏻ Shutdown'
  reboot='󰜉 Reboot'
  lock=' Lock'
  suspend='󰤄 Suspend'
  logout='󰍃 Logout'
  yes=' Yes'
  no=' No'
fi

rofi_cmd() {
  rofi -dmenu \
    -p "$host" \
    -mesg "Uptime: $uptime" \
    -theme "$THEME_PATH"
}

confirm_cmd() {
  if [[ "$STYLE_REL" == type-3/* ]] && [[ -f "$HOME/.config/rofi/powermenu/type-3/shared/confirm.rasi" ]]; then
    rofi -dmenu \
      -p 'Confirmation' \
      -mesg 'Are you sure?' \
      -theme "$HOME/.config/rofi/powermenu/type-3/shared/confirm.rasi"
  else
    rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
      -theme-str 'mainbox {children: [ "message", "listview" ];}' \
      -theme-str 'listview {columns: 2; lines: 1;}' \
      -theme-str 'element-text {horizontal-align: 0.5;}' \
      -theme-str 'textbox {horizontal-align: 0.5;}' \
      -dmenu \
      -p 'Confirmation' \
      -mesg 'Are you sure?' \
      -theme "$THEME_PATH"
  fi
}

confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case "$1" in
      --shutdown) systemctl poweroff ;;
      --reboot) systemctl reboot ;;
      --suspend)
        command -v mpc >/dev/null 2>&1 && mpc -q pause || true
        command -v playerctl >/dev/null 2>&1 && playerctl pause 2>/dev/null || true
        systemctl suspend
        ;;
      --logout)
        if [[ -n "${I3SOCK:-}" ]] || pgrep -u "$UID" -x i3 >/dev/null 2>&1; then
          i3-msg exit
        elif [[ "${DESKTOP_SESSION:-}" == "openbox" ]]; then
          openbox --exit
        elif [[ "${DESKTOP_SESSION:-}" == "bspwm" ]]; then
          bspc quit
        elif [[ "${DESKTOP_SESSION:-}" == "plasma" ]]; then
          qdbus org.kde.ksmserver /KSMServer logout 0 0 0
        fi
        ;;
    esac
  fi
}

chosen="$(run_rofi)"
case "$chosen" in
  "$shutdown") run_cmd --shutdown ;;
  "$reboot") run_cmd --reboot ;;
  "$lock") "$HOME/.config/i3/scripts/i3lock.sh" ;;
  "$suspend") run_cmd --suspend ;;
  "$logout") run_cmd --logout ;;
esac
