#!/usr/bin/env bash
# Render + deploy a palette, then live-reload every themed component.
#   theme.sh              → list themes
#   theme.sh tokyonight   → switch
set -euo pipefail

RICE="${RICE_ROOT:-$HOME/.config/ricing}"
CONF="$HOME/.config"
BUILD_ROOT="${TMPDIR:-/tmp}/ricing-build"

list_themes() {
    for f in "$RICE"/themes/*.theme; do
        printf '  %-12s %s\n' "$(basename "$f" .theme)" \
            "$(grep -m1 '^THEME_NAME=' "$f" | cut -d= -f2- | tr -d '"')"
    done
}

if [[ $# -lt 1 ]]; then
    echo "available themes:"
    list_themes
    echo
    echo "current: $(cat "$CONF/ricing/current-theme" 2>/dev/null || echo unknown)"
    exit 0
fi

THEME="$1"
THEME_FILE="$RICE/themes/$THEME.theme"
[[ -f $THEME_FILE ]] || { echo "no such theme: $THEME" >&2; list_themes; exit 1; }

BUILD="$BUILD_ROOT/$THEME"
rm -rf "$BUILD"
python3 "$RICE/render.py" "$THEME_FILE" "$RICE/templates" "$BUILD"

for d in i3 polybar picom rofi dunst alacritty btop cava fastfetch gtk-3.0 gtk-4.0 xsettingsd; do
    [[ -d $BUILD/$d ]] || continue
    mkdir -p "$CONF/$d"
    cp -a "$BUILD/$d/." "$CONF/$d/"
done
[[ -f $BUILD/Xresources ]] && cp -a "$BUILD/Xresources" "$HOME/.Xresources"
cp -a "$BUILD/palette.env" "$CONF/ricing/palette.env"
printf '%s\n' "$THEME" > "$CONF/ricing/current-theme"

python3 "$RICE/compat.py" "$CONF" --verbose 2>/dev/null || true

chmod +x "$CONF"/i3/scripts/*.sh "$CONF"/i3/scripts/*.py "$CONF"/polybar/scripts/*.sh 2>/dev/null || true

# live reload (ignore failures when not inside an i3 session)
[[ -n ${DISPLAY:-} ]] && command -v xrdb >/dev/null && xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
i3-msg reload >/dev/null 2>&1 || true
polybar-msg cmd restart >/dev/null 2>&1 || "$CONF/polybar/scripts/launch.sh" >/dev/null 2>&1 || true
dunstctl reload >/dev/null 2>&1 || pkill -USR1 dunst 2>/dev/null || true
pkill -HUP xsettingsd 2>/dev/null || true
if [[ -x "$CONF/i3/scripts/effects.sh" ]] && pgrep -x picom >/dev/null 2>&1; then
    "$CONF/i3/scripts/effects.sh" restore --quiet >/dev/null 2>&1 || true
fi

# theme-matched wallpaper, if one ships with this palette
for ext in png jpg; do
    wp="$HOME/.local/share/wallpapers/$THEME.$ext"
    [[ -f $wp ]] && { "$CONF/i3/scripts/wallpaper.sh" "$wp" --quiet; break; }
done

echo "theme → $THEME"
