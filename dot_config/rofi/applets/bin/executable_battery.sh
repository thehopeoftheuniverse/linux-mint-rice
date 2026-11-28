#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

battery="No Battery"
status="AC"
percentage="100"

shopt -s nullglob
bats=(/sys/class/power_supply/BAT*)
if (( ${#bats[@]} > 0 )); then
  bat="${bats[0]}"
  battery="$(basename "$bat")"
  [[ -r "$bat/status" ]] && status="$(<"$bat/status")"
  [[ -r "$bat/capacity" ]] && percentage="$(<"$bat/capacity")"
elif command -v acpi >/dev/null 2>&1; then
  battery="$(acpi -b | cut -d',' -f1 | cut -d':' -f1)"
  status="$(acpi -b | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')"
  percentage="$(acpi -b | cut -d',' -f2 | tr -d ' %')"
fi

prompt="$status"
mesg="${battery}: ${percentage}%"

if [[ "$theme" == *'type-1'* ]]; then
  list_col='1'; list_row='4'; win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
  list_col='1'; list_row='4'; win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
  list_col='1'; list_row='4'; win_width='500px'
else
  list_col='4'; list_row='1'; win_width='550px'
fi

active=""
urgent=""
if [[ "$status" == *"Charging"* ]]; then
  active="-a 1"; ICON_CHRG="󰂄"
elif [[ "$status" == *"Full"* ]]; then
  active="-u 1"; ICON_CHRG="󰁹"
else
  urgent="-u 1"; ICON_CHRG="󰂃"
fi

if (( percentage <= 19 )); then ICON_DISCHRG="󰁺"
elif (( percentage <= 39 )); then ICON_DISCHRG="󰁼"
elif (( percentage <= 59 )); then ICON_DISCHRG="󰁾"
elif (( percentage <= 79 )); then ICON_DISCHRG="󰂀"
else ICON_DISCHRG="󰁹"
fi

layout="$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo 'NO')"
if [[ "$layout" == 'NO' ]]; then
  option_1="󰁹 Remaining ${percentage}%"
  option_2="󰂄 $status"
  option_3=" Power Manager"
  option_4="󰒓 Monitor (btop)"
else
  option_1="$ICON_DISCHRG"; option_2="$ICON_CHRG"; option_3=""; option_4="󰒓"
fi

rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str "textbox-prompt-colon {str: \"$ICON_DISCHRG\";}" \
    -dmenu -p "$prompt" -mesg "$mesg" ${active} ${urgent} -markup-rows -theme "${theme}"
}

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd)"
case "$chosen" in
  "$option_1") notify-send -u low "Battery" "Remaining: ${percentage}%" ;;
  "$option_2") notify-send -u low "Battery" "Status: $status" ;;
  "$option_3") command -v xfce4-power-manager-settings >/dev/null 2>&1 && xfce4-power-manager-settings ;;
  "$option_4") "$HOME/.config/i3/scripts/open-monitor.sh" ;;
esac
