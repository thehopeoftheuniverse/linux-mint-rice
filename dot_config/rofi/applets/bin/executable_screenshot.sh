#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

pic_dir=$(xdg-user-dir PICTURES 2>/dev/null || true)
[[ -z "$pic_dir" ]] && pic_dir="$HOME/Pictures"
dir="${pic_dir}/Screenshots"

prompt='Screenshot'
mesg="DIR: ${dir}"

if [[ "$theme" == *'type-1'* ]]; then
  list_col='1'; list_row='5'; win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
  list_col='1'; list_row='5'; win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
  list_col='1'; list_row='5'; win_width='520px'
else
  list_col='5'; list_row='1'; win_width='35%'
fi

layout=$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo "NO")
if [[ "$layout" == 'NO' ]]; then
  option_1="󰹑 Capture Desktop"
  option_2="󰩭 Capture Area"
  option_3=" Capture Window"
  option_4="󰔛 Capture in 5s"
  option_5="󰔚 Capture in 10s"
else
  option_1="󰹑"; option_2="󰩭"; option_3=""; option_4="󰔛"; option_5="󰔚"
fi

rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: ""; padding: 11px 18px 11px 14px;}' \
    -dmenu -p "$prompt" -mesg "$mesg" -markup-rows -theme "${theme}"
}

notify_msg() {
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -u low --replace=699 "$1"
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -u low -h "string:x-dunst-stack-tag:screenshot" "$1"
  fi
}

time=$(date +%Y-%m-%d-%H-%M-%S)
filepath="${dir}/Screenshot_${time}.png"
mkdir -p "$dir"

notify_view() {
  if [[ -s "$filepath" ]]; then
    notify_msg "Screenshot saved & copied to clipboard"
    for viewer in viewnior feh imv xdg-open; do
      if command -v "$viewer" >/dev/null 2>&1; then
        "$viewer" "$filepath" >/dev/null 2>&1 &
        break
      fi
    done
  else
    notify_msg "Screenshot failed or cancelled"
  fi
}

copy_shot() {
  if command -v xclip >/dev/null 2>&1; then
    tee "$filepath" | xclip -selection clipboard -t image/png
  else
    cat > "$filepath"
  fi
}

countdown() {
  for sec in $(seq "$1" -1 1); do
    notify_msg "Taking shot in: $sec"
    sleep 1
  done
}

if ! command -v maim >/dev/null 2>&1; then
  notify_msg "Install maim for screenshots (sudo apt install maim)"
  exit 1
fi

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd)"
case "$chosen" in
  "$option_1") sleep 0.4 && maim -u -f png | copy_shot; notify_view ;;
  "$option_2") maim -u -f png -s -b 2 -c 0.49,0.97,1.0,0.25 -l | copy_shot; notify_view ;;
  "$option_3") maim -u -f png -i "$(xdotool getactivewindow)" | copy_shot; notify_view ;;
  "$option_4") countdown 5; sleep 0.5 && maim -u -f png | copy_shot; notify_view ;;
  "$option_5") countdown 10; sleep 0.5 && maim -u -f png | copy_shot; notify_view ;;
esac
