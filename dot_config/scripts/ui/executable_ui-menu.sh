#!/usr/bin/env bash
set -u

SWITCHER="$HOME/.config/scripts/ui/theme-switch.sh"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
ROFI_THEME="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

rofi_menu() {
  local prompt="$1"
  local mesg="$2"
  rofi -dmenu -i -p "$prompt" -mesg "$mesg" -theme "$ROFI_THEME"
}

current_theme="$(cat "$STATE_DIR/theme" 2>/dev/null || echo 'catppuccin-mocha')"
current_bar="$(cat "$STATE_DIR/bar-layout" 2>/dev/null || echo 'sleek')"
current_effects="$(cat "$STATE_DIR/effects" 2>/dev/null || echo 'full')"

main_choice=$(printf '%s\n' \
  "󰏘  Theme Preset (${current_theme})" \
  "󱂬  Polybar Layout (${current_bar})" \
  "󰀻  Rofi Launcher Style" \
  "⏻  Rofi Powermenu Style" \
  "󰸉  Wallpaper Picker" \
  "󰖲  Compositor Effects (${current_effects})" | \
  rofi_menu "UI Studio" "Theme: ${current_theme} · Bar: ${current_bar} · Effects: ${current_effects}")

case "$main_choice" in
  *"Theme Preset"*)
    pick=$(printf '%s\n' \
      "catppuccin-mocha     │ Default Pastel Dark" \
      "ultra-instinct       │ Dragon Ball Black UI (Silver & Ki Cyan)" \
      "ultra-instinct-omen  │ Dragon Ball Deep Void (Electric Sapphire)" \
      "tokyo-night          │ Neon Midnight Blue" | \
      rofi_menu "Theme" "Choose desktop theme across i3, Polybar, Rofi, Kitty & Dunst")
    [[ -n "$pick" ]] && "$SWITCHER" --theme "${pick%% *}"
    ;;
  *"Polybar Layout"*)
    pick=$(printf '%s\n' \
      "sleek      │ Full-width clean top bar (Default)" \
      "floating   │ Detached floating pill bar with accent border" \
      "minimal    │ Ultra-clean minimal floating island" \
      "telemetry  │ Top main bar + bottom CPU/GPU telemetry bar" | \
      rofi_menu "Bar Layout" "Choose Polybar layout")
    [[ -n "$pick" ]] && "$SWITCHER" --bar "${pick%% *}"
    ;;
  *"Rofi Launcher Style"*)
    styles=()
    while IFS= read -r f; do
      styles+=("${f#$HOME/.config/rofi/launchers/}")
    done < <(find "$HOME/.config/rofi/launchers" -maxdepth 2 -type f -name 'style-*.rasi' | sort -V)
    pick=$(printf '%s\n' "${styles[@]}" | rofi_menu "Launcher Style" "Select Rofi launcher template")
    [[ -n "$pick" ]] && "$SWITCHER" --launcher "$pick"
    ;;
  *"Rofi Powermenu Style"*)
    styles=()
    while IFS= read -r f; do
      styles+=("${f#$HOME/.config/rofi/powermenu/}")
    done < <(find "$HOME/.config/rofi/powermenu" -maxdepth 2 -type f -name 'style-*.rasi' | sort -V)
    pick=$(printf '%s\n' "${styles[@]}" | rofi_menu "Powermenu Style" "Select Rofi powermenu template")
    [[ -n "$pick" ]] && "$SWITCHER" --powermenu "$pick"
    ;;
  *"Wallpaper Picker"*)
    "$HOME/.config/i3/scripts/wallpaper-pick.sh"
    ;;
  *"Compositor Effects"*)
    pick=$(printf '%s\n' \
      "full     │ Rounded corners, blur, shadows & animations" \
      "minimal  │ Lightweight shadows only (best for VMs / battery)" \
      "off      │ Disable picom compositor" | \
      rofi_menu "Effects" "Choose picom compositor profile")
    [[ -n "$pick" ]] && "$SWITCHER" --effects "${pick%% *}"
    ;;
esac
