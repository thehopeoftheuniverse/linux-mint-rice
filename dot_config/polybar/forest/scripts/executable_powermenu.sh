#!/usr/bin/env bash
set -u

dir="$HOME/.config/polybar/forest/scripts/rofi"
uptime=$(uptime -p | sed -e 's/up //g')

rofi_command="rofi -no-config -theme $dir/powermenu.rasi"

shutdown="⏻ Shutdown"
reboot="󰜉 Restart"
lock=" Lock"
suspend="󰤄 Sleep"
logout="󰍃 Logout"

confirm_exit() {
  rofi -dmenu \
    -no-config \
    -i \
    -no-fixed-num-lines \
    -p "Are You Sure? : " \
    -theme "$dir/confirm.rasi"
}

msg() {
  rofi -no-config -theme "$dir/message.rasi" -e "Available Options - yes / y / no / n"
}

options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | $rofi_command -p "Uptime: $uptime" -dmenu -selected-row 0)"
case "$chosen" in
  "$shutdown")
    ans=$(confirm_exit)
    if [[ "$ans" =~ ^(yes|YES|y|Y)$ ]]; then
      systemctl poweroff
    elif [[ ! "$ans" =~ ^(no|NO|n|N|)$ ]]; then
      msg
    fi
    ;;
  "$reboot")
    ans=$(confirm_exit)
    if [[ "$ans" =~ ^(yes|YES|y|Y)$ ]]; then
      systemctl reboot
    elif [[ ! "$ans" =~ ^(no|NO|n|N|)$ ]]; then
      msg
    fi
    ;;
  "$lock")
    "$HOME/.config/i3/scripts/i3lock.sh"
    ;;
  "$suspend")
    ans=$(confirm_exit)
    if [[ "$ans" =~ ^(yes|YES|y|Y)$ ]]; then
      command -v mpc >/dev/null 2>&1 && mpc -q pause || true
      command -v playerctl >/dev/null 2>&1 && playerctl pause 2>/dev/null || true
      systemctl suspend
    elif [[ ! "$ans" =~ ^(no|NO|n|N|)$ ]]; then
      msg
    fi
    ;;
  "$logout")
    ans=$(confirm_exit)
    if [[ "$ans" =~ ^(yes|YES|y|Y)$ ]]; then
      if [[ -n "${I3SOCK:-}" ]] || pgrep -u "$UID" -x i3 >/dev/null 2>&1; then
        i3-msg exit
      elif [[ "${DESKTOP_SESSION:-}" == "openbox" ]]; then
        openbox --exit
      elif [[ "${DESKTOP_SESSION:-}" == "bspwm" ]]; then
        bspc quit
      fi
    elif [[ ! "$ans" =~ ^(no|NO|n|N|)$ ]]; then
      msg
    fi
    ;;
esac
