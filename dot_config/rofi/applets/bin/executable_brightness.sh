#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

if command -v brightnessctl >/dev/null 2>&1; then
  card="$(brightnessctl -m 2>/dev/null | head -n1 | cut -d',' -f1 || echo 'backlight')"
  backlight="$(brightnessctl -m 2>/dev/null | head -n1 | cut -d',' -f4 | tr -d '%' || echo '50')"
elif command -v light >/dev/null 2>&1; then
  backlight="$(printf '%.0f\n' "$(light -G)")"
  card="$(light -L | grep 'backlight' | head -n1 | cut -d'/' -f3)"
else
  notify-send -a "Brightness" "Brightness" "No backlight controller found." 2>/dev/null || true
  exit 1
fi
backlight="${backlight:-50}"

if (( backlight <= 29 )); then
  level="Low"
elif (( backlight <= 49 )); then
  level="Optimal"
elif (( backlight <= 69 )); then
  level="High"
else
  level="Peak"
fi

prompt="${backlight}%"
mesg="Device: ${card}, Level: $level"

if [[ "$theme" == *'type-1'* ]]; then
  list_col='1'; list_row='4'; win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
  list_col='1'; list_row='4'; win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
  list_col='1'; list_row='4'; win_width='425px'
else
  list_col='4'; list_row='1'; win_width='550px'
fi

layout="$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo 'NO')"
if [[ "$layout" == 'NO' ]]; then
  option_1="󰃠 Increase (+10%)"
  option_2="󰃟 Optimal (50%)"
  option_3="󰃞 Decrease (-10%)"
  option_4=" Settings"
else
  option_1="󰃠"; option_2="󰃟"; option_3="󰃞"; option_4=""
fi

rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "󰃠";}' \
    -dmenu -p "$prompt" -mesg "$mesg" -markup-rows -theme "${theme}"
}

set_bright() {
  local op="$1"
  if command -v brightnessctl >/dev/null 2>&1; then
    brightnessctl set "$op" >/dev/null 2>&1
  elif command -v light >/dev/null 2>&1; then
    case "$op" in
      +10%) light -A 10 ;;
      10%-) light -U 10 ;;
      50%) light -S 50 ;;
    esac
  fi
}

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd)"
case "$chosen" in
  "$option_1") set_bright "+10%" ;;
  "$option_2") set_bright "50%" ;;
  "$option_3") set_bright "10%-" ;;
  "$option_4") command -v xfce4-power-manager-settings >/dev/null 2>&1 && xfce4-power-manager-settings ;;
esac
