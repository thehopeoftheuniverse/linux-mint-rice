#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
mkdir -p "$STATE_DIR"

THEMES=(
  "catppuccin-mocha"
  "ultra-instinct"
  "ultra-instinct-omen"
  "tokyo-night"
)

notify_ui() {
  local title="$1"
  local msg="$2"
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "UI Theme" -r 7711 -t 2500 "$title" "$msg" 2>/dev/null || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a "UI Theme" -t 2500 "$title" "$msg" 2>/dev/null || true
  fi
}

apply_theme() {
  local theme="$1"
  local i3_src="$HOME/.config/i3/themes/${theme}.conf"
  local pb_src="$HOME/.config/polybar/forest/themes/${theme}.ini"
  local rofi_src="$HOME/.config/rofi/colors/${theme}.rasi"
  local dunst_src="$HOME/.config/dunst/themes/${theme}.conf"
  local dunst_base="$HOME/.config/dunst/dunstrc-base"

  # Kitty theme name mapping
  local kitty_src="$HOME/.config/kitty/themes/mocha.conf"
  local btop_theme="$HOME/.config/btop/themes/catppuccin_mocha.theme"
  local wp_default="$HOME/.config/wallpapers/catppuccin-wallpaper-25-hq.png"

  case "$theme" in
    catppuccin-mocha)
      kitty_src="$HOME/.config/kitty/themes/mocha.conf"
      btop_theme="$HOME/.config/btop/themes/catppuccin_mocha.theme"
      wp_default="$HOME/.config/wallpapers/catppuccin-wallpaper-25-hq.png"
      ;;
    ultra-instinct)
      kitty_src="$HOME/.config/kitty/themes/ultra-instinct.conf"
      btop_theme="$HOME/.config/btop/themes/ultra_instinct.theme"
      wp_default="$HOME/.config/wallpapers/ultra-instinct.jpg"
      ;;
    ultra-instinct-omen)
      kitty_src="$HOME/.config/kitty/themes/ultra-instinct-omen.conf"
      btop_theme="$HOME/.config/btop/themes/ultra_instinct.theme"
      wp_default="$HOME/.config/wallpapers/ultra-instinct.jpg"
      ;;
    tokyo-night)
      kitty_src="$HOME/.config/kitty/themes/tokyo-night.conf"
      btop_theme="$HOME/.config/btop/themes/catppuccin_mocha.theme"
      wp_default="$HOME/.config/wallpapers/City-Night.png"
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
    for shared_colors in "$HOME/.config/rofi"/launchers/type-*/shared/colors.rasi "$HOME/.config/rofi"/powermenu/type-*/shared/colors.rasi "$HOME/.config/rofi/applets/shared/colors.rasi"; do
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

  # 5. Dunst live reload
  if [[ -f "$dunst_base" && -f "$dunst_src" ]]; then
    cat "$dunst_base" <(printf '\n') "$dunst_src" > "$HOME/.config/dunst/dunstrc"
    if command -v dunst >/dev/null 2>&1 && pgrep -u "$UID" -x dunst >/dev/null 2>&1; then
      pkill -u "$UID" -x dunst || true
      nohup dunst >/dev/null 2>&1 &
    fi
  fi

  # 6. btop theme
  if [[ -f "$btop_theme" ]]; then
    for cfg in "$HOME/.config/btop/btop.conf" "$HOME/.config/btop/monitor.conf"; do
      if [[ -f "$cfg" ]]; then
        sed -i -E "s|^color_theme = .*|color_theme = \"$btop_theme\"|" "$cfg"
      fi
    done
  fi

  # 7. Wallpaper (set theme default if exists)
  if [[ -f "$wp_default" ]]; then
    printf '%s\n' "$wp_default" > "$STATE_DIR/wallpaper"
    command -v feh >/dev/null 2>&1 && feh --bg-fill "$wp_default" || true
  fi

  # 8. Reload i3 & Polybar
  if command -v i3-msg >/dev/null 2>&1 && [[ -n "${I3SOCK:-}" || -n "$(pgrep -u "$UID" -x i3 || true)" ]]; then
    i3-msg reload >/dev/null 2>&1 || true
  fi
  if [[ -x "$HOME/.config/polybar/launch.sh" ]]; then
    "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 &
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

  "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 &
  notify_ui "Polybar Layout" "Bar layout set to ${layout}"
}

apply_wallpaper() {
  local wp="$1"
  if [[ ! -f "$wp" ]]; then
    echo "Wallpaper not found: $wp" >&2
    exit 1
  fi
  printf '%s\n' "$wp" > "$STATE_DIR/wallpaper"
  command -v feh >/dev/null 2>&1 && feh --bg-fill "$wp"
  notify_ui "Wallpaper Updated" "$(basename "$wp")"
}

apply_effects() {
  local mode="$1"
  case "$mode" in
    full|minimal|off)
      printf '%s\n' "$mode" > "$STATE_DIR/effects"
      "$HOME/.config/i3/scripts/start-picom.sh" >/dev/null 2>&1 &
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

case "${1:-}" in
  --theme) apply_theme "${2:?missing theme}" ;;
  --cycle) cycle_theme ;;
  --bar) apply_bar_layout "${2:?missing layout}" ;;
  --launcher)
    printf '%s\n' "${2:?missing launcher style}" > "$STATE_DIR/rofi-launcher"
    notify_ui "Rofi Launcher" "Style set to $2"
    ;;
  --powermenu)
    printf '%s\n' "${2:?missing powermenu style}" > "$STATE_DIR/rofi-powermenu"
    notify_ui "Rofi Powermenu" "Style set to $2"
    ;;
  --wallpaper) apply_wallpaper "${2:?missing wallpaper path}" ;;
  --effects) apply_effects "${2:?missing effects mode}" ;;
  # Backward-compatible adi1090x flags
  --default) apply_theme "catppuccin-mocha" ;;
  --ultra-instinct) apply_theme "ultra-instinct" ;;
  --omen) apply_theme "ultra-instinct-omen" ;;
  --tokyo-night) apply_theme "tokyo-night" ;;
  *)
    cat <<EOF
Usage: $(basename "$0") [OPTION]
  --theme <catppuccin-mocha|ultra-instinct|ultra-instinct-omen|tokyo-night>
  --cycle
  --bar <sleek|floating|minimal|telemetry>
  --launcher <type-N/style-M.rasi>
  --powermenu <type-N/style-M.rasi>
  --wallpaper <path>
  --effects <full|minimal|off>
EOF
    exit 1
    ;;
esac
