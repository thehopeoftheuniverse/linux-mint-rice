#!/usr/bin/env bash
set -u

if command -v networkmanager_dmenu >/dev/null 2>&1; then
  exec networkmanager_dmenu "$@"
fi

ROFI_THEME="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

rofi_menu() {
  local prompt="$1"
  local mesg="$2"
  rofi -dmenu -i -p "$prompt" -mesg "$mesg" -theme "$ROFI_THEME" \
    -theme-str 'inputbar { children: [ "textbox-prompt-colon", "prompt", "entry" ]; } prompt { padding: 4px 10px; border-radius: 6px; background-color: @selected; text-color: @background-solid; }'
}

if ! command -v nmcli >/dev/null 2>&1; then
  command -v nm-connection-editor >/dev/null 2>&1 && exec nm-connection-editor
  notify-send -a "Network" "Network Manager" "Install network-manager (nmcli) to manage connections." 2>/dev/null || true
  exit 1
fi

wifi_state="$(nmcli radio wifi 2>/dev/null || echo disabled)"
if [[ "$wifi_state" == "enabled" ]]; then
  toggle_opt="󰖪  Disable Wi-Fi"
else
  toggle_opt="󰖩  Enable Wi-Fi"
fi

active_conn="$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | head -n1 || true)"
mesg="Active: ${active_conn:-None}"

nets=""
if [[ "$wifi_state" == "enabled" ]]; then
  nets="$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null | awk -F: '
    $2 != "" {
      mark = ($1 == "*") ? "✓" : " ";
      sec = ($3 == "" || $3 == "--") ? "Open" : $3;
      printf "%s %-28s [%s · %s%%]\n", mark, $2, sec, $4
    }' | awk '!seen[$0]++')"
fi

menu_items="${toggle_opt}"
[[ -n "$nets" ]] && menu_items+=$'\n'"${nets}"
menu_items+=$'\n'"󰑓  Rescan Wi-Fi"$'\n'"  Connection Editor"

choice="$(printf '%s\n' "$menu_items" | rofi_menu "Network" "$mesg")"
[[ -n "$choice" ]] || exit 0

case "$choice" in
  "󰖪  Disable Wi-Fi")
    nmcli radio wifi off
    notify-send -a "Network" "Wi-Fi" "Disabled" 2>/dev/null || true
    ;;
  "󰖩  Enable Wi-Fi")
    nmcli radio wifi on
    notify-send -a "Network" "Wi-Fi" "Enabled" 2>/dev/null || true
    ;;
  "󰑓  Rescan Wi-Fi")
    nmcli dev wifi rescan 2>/dev/null || true
    exec "$0"
    ;;
  "  Connection Editor")
    exec nm-connection-editor
    ;;
  *)
    ssid="$(sed -E 's/^[✓ ] //; s/[[:space:]]+\[[^]]+\]$//' <<< "$choice" | sed -E 's/[[:space:]]+$//')"
    [[ -n "$ssid" ]] || exit 0
    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
      notify-send -a "Network" "Connected" "$ssid" 2>/dev/null || true
    else
      pass="$(rofi -dmenu -password -p "Password" -mesg "Enter Wi-Fi passphrase for $ssid" -theme "$ROFI_THEME" \
        -theme-str 'listview { lines: 0; } inputbar { children: [ "textbox-prompt-colon", "prompt", "entry" ]; } prompt { padding: 4px 10px; border-radius: 6px; background-color: @selected; text-color: @background-solid; }')"
      [[ -n "$pass" ]] || exit 0
      if nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify-send -a "Network" "Connected" "$ssid" 2>/dev/null || true
      else
        notify-send -u critical -a "Network" "Connection Failed" "$ssid" 2>/dev/null || true
      fi
    fi
    ;;
esac
