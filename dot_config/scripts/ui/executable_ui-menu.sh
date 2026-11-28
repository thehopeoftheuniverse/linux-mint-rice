#!/usr/bin/env bash
set -u

SWITCHER="$HOME/.config/scripts/ui/theme-switch.sh"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
ROFI_THEME="$HOME/.config/rofi/launchers/type-1/style-6.rasi"

rofi_menu() {
  local prompt="$1"
  local mesg="$2"
  rofi -dmenu -i -p "$prompt" -mesg "$mesg" -theme "$ROFI_THEME" \
    -theme-str 'inputbar { children: [ "textbox-prompt-colon", "prompt", "entry" ]; } prompt { padding: 4px 10px; border-radius: 6px; background-color: @selected; text-color: @background-solid; }'
}

mark_active() {
  local key="$1"
  local active="$2"
  if [[ "$key" == "$active" ]]; then
    printf '✓ '
  else
    printf '  '
  fi
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
      "$(mark_active catppuccin-mocha "$current_theme")catppuccin-mocha     │ Default Pastel Glass" \
      "$(mark_active ultra-instinct "$current_theme")ultra-instinct       │ Dragon Ball Black UI (Silver & Ki Cyan)" \
      "$(mark_active goku-ssj4 "$current_theme")goku-ssj4            │ Dragon Ball SSJ4 Red (Crimson Fur & Gold Ki)" \
      "$(mark_active tokyo-night "$current_theme")tokyo-night          │ Neon Midnight Blue Glass" \
      "$(mark_active rose-pine "$current_theme")rose-pine            │ Rosé Pine Twilight Glass" | \
      rofi_menu "Theme" "Choose desktop theme across i3, Polybar, Rofi, Kitty, Dunst & btop")
    clean="${pick#✓ }"
    clean="${clean#  }"
    [[ -n "$clean" ]] && "$SWITCHER" --theme "${clean%% *}"
    ;;
  *"Polybar Layout"*)
    pick=$(printf '%s\n' \
      "$(mark_active sleek "$current_bar")sleek      │ Full-width translucent top bar (Default)" \
      "$(mark_active floating "$current_bar")floating   │ Detached floating pill bar with accent border" \
      "$(mark_active minimal "$current_bar")minimal    │ Ultra-clean minimal floating island" \
      "$(mark_active telemetry "$current_bar")telemetry  │ Top main bar + bottom CPU/GPU telemetry bar" | \
      rofi_menu "Bar Layout" "Choose Polybar layout")
    clean="${pick#✓ }"
    clean="${clean#  }"
    [[ -n "$clean" ]] && "$SWITCHER" --bar "${clean%% *}"
    ;;
  *"Rofi Launcher Style"*)
    styles=()
    while IFS= read -r f; do
      styles+=("${f#$HOME/.config/rofi/launchers/}")
    done < <(find "$HOME/.config/rofi/launchers" -maxdepth 2 -type f -name 'style-*.rasi' \
      \( -path '*/type-1/*' -o -path '*/type-2/*' -o -path '*/type-3/*' -o -path '*/type-4/*' \) | sort -V)
    pick=$(printf '%s\n' "${styles[@]}" | rofi_menu "Launcher" "Select theme-synced Rofi launcher template")
    [[ -n "$pick" ]] && "$SWITCHER" --launcher "$pick"
    ;;
  *"Rofi Powermenu Style"*)
    styles=()
    while IFS= read -r f; do
      styles+=("${f#$HOME/.config/rofi/powermenu/}")
    done < <(find "$HOME/.config/rofi/powermenu" -maxdepth 2 -type f -name 'style-*.rasi' \
      \( -path '*/type-1/*' -o -path '*/type-2/*' -o -path '*/type-3/*' \) | sort -V)
    pick=$(printf '%s\n' "${styles[@]}" | rofi_menu "Powermenu" "Select theme-synced Rofi powermenu template")
    [[ -n "$pick" ]] && "$SWITCHER" --powermenu "$pick"
    ;;
  *"Wallpaper Picker"*)
    "$HOME/.config/i3/scripts/wallpaper-pick.sh"
    ;;
  *"Compositor Effects"*)
    pick=$(printf '%s\n' \
      "$(mark_active full "$current_effects")full     │ Rounded corners, dual-kawase blur & glass translucency" \
      "$(mark_active minimal "$current_effects")minimal  │ Lightweight shadows & translucency (VMs / battery)" \
      "$(mark_active off "$current_effects")off      │ Disable picom compositor" | \
      rofi_menu "Effects" "Choose picom compositor profile")
    clean="${pick#✓ }"
    clean="${clean#  }"
    [[ -n "$clean" ]] && "$SWITCHER" --effects "${clean%% *}"
    ;;
esac
