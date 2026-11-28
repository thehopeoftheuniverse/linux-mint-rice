#!/usr/bin/env bash
set -u

source "$HOME/.config/rofi/applets/shared/theme.bash"
theme="$type/$style"

# Use PipeWire/PulseAudio (pactl/wpctl) with ALSA fallback for modern Debian/Mint
get_speaker_vol() {
  if command -v pactl >/dev/null 2>&1; then
    pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1 || echo "0%"
  else
    amixer get Master 2>/dev/null | grep -oE '[0-9]+%' | head -n1 || echo "0%"
  fi
}

is_speaker_muted() {
  if command -v pactl >/dev/null 2>&1; then
    [[ "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" == *"yes"* ]]
  else
    amixer get Master 2>/dev/null | grep -q '\[off\]'
  fi
}

get_mic_vol() {
  if command -v pactl >/dev/null 2>&1; then
    pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1 || echo "0%"
  else
    amixer get Capture 2>/dev/null | grep -oE '[0-9]+%' | head -n1 || echo "N/A"
  fi
}

is_mic_muted() {
  if command -v pactl >/dev/null 2>&1; then
    [[ "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)" == *"yes"* ]]
  else
    amixer get Capture 2>/dev/null | grep -q '\[off\]'
  fi
}

speaker="$(get_speaker_vol)"
mic="$(get_mic_vol)"
active=""
urgent=""

if ! is_speaker_muted; then
  active="-a 1"; stext='Unmute'; sicon='󰕾'
else
  urgent="-u 1"; stext='Mute'; sicon='󰖁'
fi

if ! is_mic_muted; then
  [[ -n "$active" ]] && active+=",3" || active="-a 3"
  mtext='Unmute'; micon='󰍬'
else
  [[ -n "$urgent" ]] && urgent+=",3" || urgent="-u 3"
  mtext='Mute'; micon='󰍭'
fi

prompt="Audio"
mesg="Speaker: $speaker · Mic: $mic"

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
  option_1="󰝝 Increase"
  option_2="$sicon $stext"
  option_3="󰝞 Decrease"
  option_4="$micon $mtext"
  option_5="󰒓 Mixer"
else
  option_1="󰝝"; option_2="$sicon"; option_3="󰝞"; option_4="$micon"; option_5="󰒓"
fi

chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | \
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: " ";}' \
    -dmenu -p "$prompt" -mesg "$mesg" ${active} ${urgent} -markup-rows -theme "${theme}")"

case "$chosen" in
  "$option_1") command -v pactl >/dev/null 2>&1 && pactl set-sink-volume @DEFAULT_SINK@ +5% || amixer -Mq set Master 5%+ unmute ;;
  "$option_2") command -v pactl >/dev/null 2>&1 && pactl set-sink-mute @DEFAULT_SINK@ toggle || amixer set Master toggle ;;
  "$option_3") command -v pactl >/dev/null 2>&1 && pactl set-sink-volume @DEFAULT_SINK@ -5% || amixer -Mq set Master 5%- unmute ;;
  "$option_4") command -v pactl >/dev/null 2>&1 && pactl set-source-mute @DEFAULT_SOURCE@ toggle || amixer set Capture toggle ;;
  "$option_5") command -v pavucontrol >/dev/null 2>&1 && pavucontrol & ;;
esac
