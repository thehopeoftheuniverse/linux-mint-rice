#!/usr/bin/env bash
set -u

ok()   { printf '\033[1;32m[OK]\033[0m   %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; ERRORS=$((ERRORS + 1)); }

ERRORS=0

echo "== Dotfiles Environment Check =="

# 1. Core binaries
for bin in i3 polybar rofi picom dunst feh kitty zsh nvim git; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "Binary found: $bin ($(command -v "$bin"))"
  else
    fail "Missing binary: $bin"
  fi
done

# 2. Debian/Mint binary shims & utilities
if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
  ok "bat/batcat available"
else
  warn "bat/batcat not installed"
fi

if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
  ok "fd/fdfind available"
else
  warn "fd/fdfind not installed"
fi

for util in nmcli pamixer brightnessctl maim xclip; do
  if command -v "$util" >/dev/null 2>&1; then
    ok "Utility available: $util"
  else
    warn "Optional utility missing: $util"
  fi
done

# 3. Fonts
if command -v fc-list >/dev/null 2>&1; then
  if fc-list | grep -qi "JetBrainsMono"; then
    ok "JetBrainsMono Nerd Font installed"
  else
    warn "JetBrainsMono Nerd Font missing (run install-debian.sh or install into ~/.local/share/fonts)"
  fi
fi

# 4. Broken symlinks check
broken=0
for dir in "$HOME/.config/i3" "$HOME/.config/polybar" "$HOME/.config/rofi" "$HOME/.config/kitty" "$HOME/.config/dunst"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r link; do
    warn "Broken symlink: $link -> $(readlink "$link" || true)"
    broken=$((broken + 1))
  done < <(find "$dir" -xtype l 2>/dev/null)
done
(( broken == 0 )) && ok "No broken symlinks in ~/.config/{i3,polybar,rofi,kitty,dunst}"

# 5. Theme state files
for f in \
  "$HOME/.config/i3/current-theme.conf" \
  "$HOME/.config/polybar/forest/current-theme.ini" \
  "$HOME/.config/polybar/forest/current-layout.ini" \
  "$HOME/.config/rofi/colors/current-theme.rasi" \
  "$HOME/.config/kitty/current-theme.conf" \
  "$HOME/.config/dunst/dunstrc"; do
  if [[ -f "$f" ]]; then
    ok "Theme target exists: ${f#"$HOME/"}"
  else
    fail "Missing theme target: $f"
  fi
done

# 6. i3 config validation (when X display is active)
if command -v i3 >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]] && [[ -f "$HOME/.config/i3/config" ]]; then
  if i3 -C -c "$HOME/.config/i3/config" >/dev/null 2>&1; then
    ok "i3 config syntax valid"
  else
    fail "i3 config syntax check failed (run: i3 -C -c ~/.config/i3/config)"
  fi
fi

# 7. Running compositor / bar status
if [[ -n "${DISPLAY:-}" ]]; then
  pgrep -u "$UID" -x picom >/dev/null 2>&1 && ok "picom running (translucency/blur active)" || warn "picom not running"
  pgrep -u "$UID" -x polybar >/dev/null 2>&1 && ok "polybar running" || warn "polybar not running"
  pgrep -u "$UID" -x dunst >/dev/null 2>&1 && ok "dunst running" || warn "dunst not running"
fi

# 8. UI Theme state
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
echo "Active UI theme: $(cat "$STATE_DIR/theme" 2>/dev/null || echo 'catppuccin-mocha (default)')"
echo "Active bar layout: $(cat "$STATE_DIR/bar-layout" 2>/dev/null || echo 'sleek (default)')"
echo "Active compositor profile: $(cat "$STATE_DIR/effects" 2>/dev/null || echo 'full (default)')"

exit "$ERRORS"
