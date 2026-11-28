#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

prompt='Applications'
mesg='Run Applications as Root'

if [[ "$theme" == *'type-1'* ]]; then
  list_col='1'; list_row='4'; win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
  list_col='1'; list_row='4'; win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
  list_col='1'; list_row='4'; win_width='520px'
else
  list_col='4'; list_row='1'; win_width='600px'
fi

layout="$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo 'NO')"
if [[ "$layout" == 'NO' ]]; then
  option_1=" Kitty (Root)"
  option_2=" Thunar (Root)"
  option_3="󰇥 Yazi (Root)"
  option_4=" Neovim (Root)"
else
  option_1=""; option_2=""; option_3="󰇥"; option_4=""
fi

rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu -p "$prompt" -mesg "$mesg" -markup-rows -theme "${theme}"
}

run_as_root() {
  local -a env_args=("PATH=$PATH")
  [[ -n "${DISPLAY:-}" ]] && env_args+=("DISPLAY=$DISPLAY")
  [[ -n "${XAUTHORITY:-}" ]] && env_args+=("XAUTHORITY=$XAUTHORITY")
  pkexec env "${env_args[@]}" "$@"
}

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd)"
case "$chosen" in
  "$option_1") run_as_root kitty ;;
  "$option_2") run_as_root dbus-run-session thunar ;;
  "$option_3") run_as_root kitty -e yazi ;;
  "$option_4") run_as_root kitty -e nvim ;;
esac
