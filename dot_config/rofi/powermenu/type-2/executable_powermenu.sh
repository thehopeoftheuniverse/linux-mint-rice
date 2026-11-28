#!/usr/bin/env bash
set -u

STYLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/rofi-powermenu"
dir="$HOME/.config/rofi/powermenu/type-2"
theme='style-1'
if [[ -r "$STYLE_FILE" ]]; then
  style_rel="$(tr -d '[:space:]' < "$STYLE_FILE")"
  if [[ "$style_rel" == type-2/*.rasi ]] && [[ -f "$HOME/.config/rofi/powermenu/$style_rel" ]]; then
    theme="${style_rel#type-2/}"
    theme="${theme%.rasi}"
  fi
fi

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"

# Options (Nerd Font glyphs)
shutdown='⏻'
reboot='󰜉'
lock=''
suspend='󰤄'
logout='󰍃'
yes=''
no=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Uptime: $uptime" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you sure?' \
		-theme "${dir}/${theme}.rasi"
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
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
				elif [[ "${DESKTOP_SESSION:-}" == 'openbox' ]]; then
					openbox --exit
				elif [[ "${DESKTOP_SESSION:-}" == 'bspwm' ]]; then
					bspc quit
				elif [[ "${DESKTOP_SESSION:-}" == 'plasma' ]]; then
					qdbus org.kde.ksmserver /KSMServer logout 0 0 0
				fi
				;;
		esac
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case "${chosen}" in
    "$shutdown") run_cmd --shutdown ;;
    "$reboot") run_cmd --reboot ;;
    "$lock") "$HOME/.config/i3/scripts/i3lock.sh" ;;
    "$suspend") run_cmd --suspend ;;
    "$logout") run_cmd --logout ;;
esac
