#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

if command -v dpkg-query >/dev/null 2>&1; then
  pkg_count="$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l) (apt)"
elif command -v pacman >/dev/null 2>&1; then
  pkg_count="$(pacman -Q 2>/dev/null | wc -l) (pacman)"
else
  pkg_count="unknown"
fi

prompt='Applications'
mesg="Installed Packages : ${pkg_count}"

if [[ "$theme" == *'type-1'* || "$theme" == *'type-3'* || "$theme" == *'type-5'* ]]; then
  list_col='1'; list_row='6'
else
  list_col='6'; list_row='1'
fi

term_cmd='kitty'
file_cmd='thunar'
text_cmd='kitty -e nvim'
web_cmd="$HOME/.config/i3/scripts/browser.sh"
music_cmd='kitty -e btop'
setting_cmd="$HOME/.config/scripts/ui/ui-menu.sh"

layout="$(grep 'USE_ICON' "${theme}" 2>/dev/null | cut -d'=' -f2 || echo 'NO')"
if [[ "$layout" == 'NO' ]]; then
  option_1=" Terminal <span weight='light' size='small'><i>(kitty)</i></span>"
  option_2=" Files <span weight='light' size='small'><i>(thunar)</i></span>"
  option_3=" Editor <span weight='light' size='small'><i>(nvim)</i></span>"
  option_4=" Browser"
  option_5=" Monitor <span weight='light' size='small'><i>(btop)</i></span>"
  option_6="󰏘 UI Studio"
else
  option_1=""; option_2=""; option_3=""; option_4=""; option_5=""; option_6="󰏘"
fi

rofi_cmd() {
  rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "󰀻";}' \
    -dmenu -p "$prompt" -mesg "$mesg" -markup-rows -theme "${theme}"
}

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd)"
case "$chosen" in
  "$option_1") $term_cmd & ;;
  "$option_2") $file_cmd & ;;
  "$option_3") $text_cmd & ;;
  "$option_4") $web_cmd & ;;
  "$option_5") $music_cmd & ;;
  "$option_6") $setting_cmd & ;;
esac
