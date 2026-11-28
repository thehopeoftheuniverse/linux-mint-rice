#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

prompt="$(hostname)"
mesg="Uptime : $(uptime -p | sed -e 's/up //g')"

if [[ "$theme" == *'type-1'* || "$theme" == *'type-3'* || "$theme" == *'type-5'* ]]; then
  list_col='1'
  list_row='6'
else
  list_col='6'
  list_row='1'
fi

layout=$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo "NO")
if [[ "$layout" == 'NO' ]]; then
  option_1=" Lock"
  option_2="󰍃 Logout"
  option_3="󰤄 Suspend"
  option_4="󰒲 Hibernate"
  option_5="󰜉 Reboot"
  option_6="⏻ Shutdown"
  yes=' Yes'
  no=' No'
else
  option_1=""
  option_2="󰍃"
  option_3="󰤄"
  option_4="󰒲"
  option_5="󰜉"
  option_6="⏻"
  yes=''
  no=''
fi

rofi_cmd() {
  rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "${theme}"
}

run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

confirm_cmd() {
  rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
    -theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you Sure?' \
    -theme "${theme}"
}

confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

do_logout() {
  if [[ -n "${I3SOCK:-}" ]] || pgrep -u "$UID" -x i3 >/dev/null 2>&1; then
    i3-msg exit
  else
    loginctl terminate-user "$USER"
  fi
}

chosen="$(run_rofi)"
case "$chosen" in
  "$option_1") "$HOME/.config/i3/scripts/i3lock.sh" ;;
  "$option_2") [[ "$(confirm_exit)" == "$yes" ]] && do_logout ;;
  "$option_3")
    if [[ "$(confirm_exit)" == "$yes" ]]; then
      command -v mpc >/dev/null 2>&1 && mpc -q pause || true
      command -v playerctl >/dev/null 2>&1 && playerctl pause 2>/dev/null || true
      systemctl suspend
    fi
    ;;
  "$option_4") [[ "$(confirm_exit)" == "$yes" ]] && systemctl hibernate ;;
  "$option_5") [[ "$(confirm_exit)" == "$yes" ]] && systemctl reboot ;;
  "$option_6") [[ "$(confirm_exit)" == "$yes" ]] && systemctl poweroff ;;
esac
