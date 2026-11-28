#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
mkdir -p "$STATE_DIR"

THEMES=(
  "catppuccin-mocha"
  "ultra-instinct"
  "goku-ssj4"
  "tokyo-night"
  "rose-pine"
)

notify_ui() {
  local title="$1"
  local msg="$2"
  [[ -n "${DISPLAY:-}" ]] || return 0
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "UI Theme" -r 7711 -t 2500 "$title" "$msg" 2>/dev/null || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a "UI Theme" -t 2500 "$title" "$msg" 2>/dev/null || true
  fi
}

update_cava_colors() {
  local c1="$1" c2="$2" c3="$3" c4="$4" c5="$5" c6="$6" c7="$7" c8="$8"
  local cava_cfg="$HOME/.config/cava/config"
  [[ -f "$cava_cfg" ]] || return 0
  sed -i -E \
    -e "s|^gradient_color_1 = .*|gradient_color_1 = '${c1}'|" \
    -e "s|^gradient_color_2 = .*|gradient_color_2 = '${c2}'|" \
    -e "s|^gradient_color_3 = .*|gradient_color_3 = '${c3}'|" \
    -e "s|^gradient_color_4 = .*|gradient_color_4 = '${c4}'|" \
    -e "s|^gradient_color_5 = .*|gradient_color_5 = '${c5}'|" \
    -e "s|^gradient_color_6 = .*|gradient_color_6 = '${c6}'|" \
    -e "s|^gradient_color_7 = .*|gradient_color_7 = '${c7}'|" \
    -e "s|^gradient_color_8 = .*|gradient_color_8 = '${c8}'|" \
    "$cava_cfg" 2>/dev/null || true
}

apply_theme() {
  local theme="$1"
  local i3_src="$HOME/.config/i3/themes/${theme}.conf"
  local pb_src="$HOME/.config/polybar/forest/themes/${theme}.ini"
  local rofi_src="$HOME/.config/rofi/colors/${theme}.rasi"
  local dunst_src="$HOME/.config/dunst/themes/${theme}.conf"
  local dunst_base="$HOME/.config/dunst/dunstrc-base"

  local kitty_src="$HOME/.config/kitty/themes/mocha.conf"
  local btop_theme="$HOME/.config/btop/themes/catppuccin_mocha.theme"
  local wp_default="$HOME/.config/wallpapers/catppuccin-wallpaper-25-hq.png"

  case "$theme" in
    catppuccin-mocha)
      kitty_src="$HOME/.config/kitty/themes/mocha.conf"
      btop_theme="$HOME/.config/btop/themes/catppuccin_mocha.theme"
      wp_default="$HOME/.config/wallpapers/catppuccin-wallpaper-25-hq.png"
      update_cava_colors "#94e2d5" "#89dceb" "#74c7ec" "#89b4fa" "#cba6f7" "#f5c2e7" "#eba0ac" "#f38ba8"
      ;;
    ultra-instinct)
      kitty_src="$HOME/.config/kitty/themes/ultra-instinct.conf"
      btop_theme="$HOME/.config/btop/themes/ultra_instinct.theme"
      wp_default="$HOME/.config/wallpapers/ultra-instinct.jpg"
      update_cava_colors "#5eead4" "#7df9ff" "#38bdf8" "#60a5fa" "#c084fc" "#d8b4fe" "#f472b6" "#fb7185"
      ;;
    goku-ssj4)
      kitty_src="$HOME/.config/kitty/themes/goku-ssj4.conf"
      btop_theme="$HOME/.config/btop/themes/goku_ssj4.theme"
      wp_default="$HOME/.config/wallpapers/goku-ssj4.jpg"
      update_cava_colors "#fbbf24" "#f59e0b" "#fb923c" "#fb7185" "#f43f5e" "#ef233c" "#dc2626" "#ff3b5c"
      ;;
    tokyo-night)
      kitty_src="$HOME/.config/kitty/themes/tokyo-night.conf"
      btop_theme="$HOME/.config/btop/themes/tokyo_night.theme"
      wp_default="$HOME/.config/wallpapers/City-Night.png"
      update_cava_colors "#73daca" "#7dcfff" "#2ac3de" "#7aa2f7" "#bb9af7" "#c0caf5" "#ff9e64" "#f7768e"
      ;;
    rose-pine)
      kitty_src="$HOME/.config/kitty/themes/rose-pine.conf"
      btop_theme="$HOME/.config/btop/themes/rose_pine.theme"
      wp_default="$HOME/.config/wallpapers/sakura-gate.jpg"
      update_cava_colors "#31748f" "#9ccfd8" "#c4a7e7" "#ebbcba" "#ea9a97" "#f6c177" "#eb6f92" "#eb6f92"
      ;;
    *)
      echo "Unknown theme: $theme" >&2
      exit 1
      ;;
  esac

  printf '%s\n' "$theme" > "$STATE_DIR/theme"

  # 1. i3 colors
  if [[ -f "$i3_src" ]]; then
    cp "$i3_src" "$HOME/.config/i3/current-theme.conf"
  fi

  # 2. Polybar colors
  if [[ -f "$pb_src" ]]; then
    cp "$pb_src" "$HOME/.config/polybar/forest/current-theme.ini"
  fi

  # 3. Rofi unified color import
  if [[ -f "$rofi_src" ]]; then
    cp "$rofi_src" "$HOME/.config/rofi/colors/current-theme.rasi"
    for shared_colors in \
      "$HOME/.config/rofi"/launchers/type-*/shared/colors.rasi \
      "$HOME/.config/rofi"/powermenu/type-*/shared/colors.rasi \
      "$HOME/.config/rofi/applets/shared/colors.rasi"; do
      if [[ -f "$shared_colors" ]]; then
        printf '@import "~/.config/rofi/colors/current-theme.rasi"\n' > "$shared_colors"
      fi
    done
  fi

  # 4. Kitty live theme reload
  if [[ -f "$kitty_src" ]]; then
    cp "$kitty_src" "$HOME/.config/kitty/current-theme.conf"
    if command -v kitty >/dev/null 2>&1; then
      for sock in /tmp/kitty-*; do
        [[ -S "$sock" ]] && kitty @ --to "unix:$sock" set-colors -a -c "$HOME/.config/kitty/current-theme.conf" >/dev/null 2>&1 || true
      done
    fi
    pkill -USR1 -u "$UID" -x kitty 2>/dev/null || true
  fi

  # 5. Dunst live reload (wait for old process to release DBus name)
  if [[ -f "$dunst_base" && -f "$dunst_src" ]]; then
    cat "$dunst_base" <(printf '\n') "$dunst_src" > "$HOME/.config/dunst/dunstrc"
    if [[ -n "${DISPLAY:-}" ]] && command -v dunst >/dev/null 2>&1 && pgrep -u "$UID" -x dunst >/dev/null 2>&1; then
      pkill -u "$UID" -x dunst 2>/dev/null || true
      local tries=0
      while pgrep -u "$UID" -x dunst >/dev/null 2>&1 && (( tries < 20 )); do
        sleep 0.05
        tries=$((tries + 1))
      done
      nohup dunst >/dev/null 2>&1 &
    fi
  fi

  # 6. btop theme (keep theme_background = False so kitty glass shows through)
  if [[ -f "$btop_theme" ]]; then
    for cfg in "$HOME/.config/btop/btop.conf" "$HOME/.config/btop/monitor.conf"; do
      if [[ -f "$cfg" ]]; then
        sed -i -E \
          -e "s|^color_theme = .*|color_theme = \"$btop_theme\"|" \
          -e "s|^theme_background = .*|theme_background = False|" \
          "$cfg"
      fi
    done
  fi

  # 7. Wallpaper (set theme default if exists)
  if [[ -f "$wp_default" ]]; then
    printf '%s\n' "$wp_default" > "$STATE_DIR/wallpaper"
    if [[ -n "${DISPLAY:-}" ]] && command -v feh >/dev/null 2>&1; then
      feh --bg-fill "$wp_default" >/dev/null 2>&1 || true
    fi
  fi

  # 8. Reload i3 & Polybar (only when an X session is active)
  if [[ -n "${DISPLAY:-}" ]]; then
    if command -v i3-msg >/dev/null 2>&1 && [[ -n "${I3SOCK:-}" || -n "$(pgrep -u "$UID" -x i3 || true)" ]]; then
      i3-msg reload >/dev/null 2>&1 || true
    fi
    if [[ -x "$HOME/.config/polybar/launch.sh" ]]; then
      nohup "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 &
    fi
  fi

  notify_ui "Theme Applied" "Switched UI to ${theme}"
}

apply_bar_layout() {
  local layout="$1"
  local layout_file="$HOME/.config/polybar/forest/layouts/${layout}.ini"

  case "$layout" in
    sleek|floating|minimal)
      cp "$layout_file" "$HOME/.config/polybar/forest/current-layout.ini"
      printf '%s\n' "$layout" > "$STATE_DIR/bar-layout"
      ;;
    telemetry)
      cp "$HOME/.config/polybar/forest/layouts/sleek.ini" "$HOME/.config/polybar/forest/current-layout.ini"
      printf '%s\n' "telemetry" > "$STATE_DIR/bar-layout"
      ;;
    *)
      echo "Unknown bar layout: $layout" >&2
      exit 1
      ;;
  esac

  if [[ -n "${DISPLAY:-}" && -x "$HOME/.config/polybar/launch.sh" ]]; then
    nohup "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 &
  fi
  notify_ui "Polybar Layout" "Bar layout set to ${layout}"
}

apply_wallpaper() {
  local wp="$1"
  if [[ ! -f "$wp" ]]; then
    echo "Wallpaper not found: $wp" >&2
    exit 1
  fi
  printf '%s\n' "$wp" > "$STATE_DIR/wallpaper"
  if [[ -n "${DISPLAY:-}" ]] && command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$wp" >/dev/null 2>&1 || true
  fi
  notify_ui "Wallpaper Updated" "$(basename "$wp")"
}

apply_effects() {
  local mode="$1"
  case "$mode" in
    full|minimal|off)
      printf '%s\n' "$mode" > "$STATE_DIR/effects"
      if [[ -n "${DISPLAY:-}" && -x "$HOME/.config/i3/scripts/start-picom.sh" ]]; then
        nohup "$HOME/.config/i3/scripts/start-picom.sh" >/dev/null 2>&1 &
      fi
      notify_ui "Compositor Effects" "Picom set to ${mode}"
      ;;
    *)
      echo "Unknown effects mode: $mode" >&2
      exit 1
      ;;
  esac
}

cycle_theme() {
  local current="catppuccin-mocha"
  [[ -r "$STATE_DIR/theme" ]] && current="$(tr -d '[:space:]' < "$STATE_DIR/theme")"
  local next="${THEMES[0]}"
  for i in "${!THEMES[@]}"; do
    if [[ "${THEMES[$i]}" == "$current" ]]; then
      next="${THEMES[$(( (i + 1) % ${#THEMES[@]} ))]}"
      break
    fi
  done
  apply_theme "$next"
}

set_rofi_style() {
  local subdir="$1"
  local state_key="$2"
  local label="$3"
  local rel="$4"
  if [[ -z "$rel" || "$rel" == /* || "$rel" == *..* || "$rel" != *.rasi || ! -f "$HOME/.config/rofi/${subdir}/${rel}" ]]; then
    echo "Invalid or missing Rofi ${label} style: ${rel}" >&2
    exit 1
  fi
  printf '%s\n' "$rel" > "$STATE_DIR/$state_key"
  notify_ui "Rofi ${label}" "Style set to $rel"
}

case "${1:-}" in
  --theme) apply_theme "${2:?missing theme}" ;;
  catppuccin-mocha|ultra-instinct|goku-ssj4|tokyo-night|rose-pine) apply_theme "$1" ;;
  --cycle) cycle_theme ;;
  --list) printf '%s\n' "${THEMES[@]}" ;;
  --current) cat "$STATE_DIR/theme" 2>/dev/null || echo "catppuccin-mocha" ;;
  --bar) apply_bar_layout "${2:?missing layout}" ;;
  --launcher) set_rofi_style "launchers" "rofi-launcher" "Launcher" "${2:?missing launcher style}" ;;
  --powermenu) set_rofi_style "powermenu" "rofi-powermenu" "Powermenu" "${2:?missing powermenu style}" ;;
  --wallpaper) apply_wallpaper "${2:?missing wallpaper path}" ;;
  --effects) apply_effects "${2:?missing effects mode}" ;;
  # Backward-compatible adi1090x & theme shorthand flags
  --default) apply_theme "catppuccin-mocha" ;;
  --ultra-instinct) apply_theme "ultra-instinct" ;;
  --ssj4|--goku-ssj4) apply_theme "goku-ssj4" ;;
  --tokyo-night) apply_theme "tokyo-night" ;;
  --rose-pine) apply_theme "rose-pine" ;;
  *)
    cat <<EOF
Usage: $(basename "$0") [OPTION]
  --theme <catppuccin-mocha|ultra-instinct|goku-ssj4|tokyo-night|rose-pine>
  --cycle | --list | --current
  --bar <sleek|floating|minimal|telemetry>
  --launcher <type-N/style-M.rasi>
  --powermenu <type-N/style-M.rasi>
  --wallpaper <path>
  --effects <full|minimal|off>
EOF
    exit 1
    ;;
esac
