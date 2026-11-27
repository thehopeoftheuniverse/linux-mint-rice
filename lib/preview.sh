#!/usr/bin/env bash
# ============================================================================
#  Boot the whole rice inside a private X server + throwaway HOME.
#  Nothing in your real session is touched.  Produces screenshots.
#    preview.sh [theme] [display] [shot-dir]
# ============================================================================
set -euo pipefail
RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="${1:-tokyonight}"
DISP="${2:-:9}"
SHOTS="${3:-$RICE/screenshots}"
SANDBOX="/tmp/rice-sandbox-$THEME"
W=1718; H=920

mkdir -p "$SHOTS"
pkill -f "Xvfb $DISP" 2>/dev/null || true
sleep 0.3

echo "── sandbox deploy → $SANDBOX"
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX/.local/share" "$SANDBOX/.icons"
ln -sfn "$HOME/.local/share/fonts" "$SANDBOX/.local/share/fonts"
ln -sfn "$HOME/.icons/Bibata-Modern-Ice" "$SANDBOX/.icons/Bibata-Modern-Ice"
ln -sfn "$HOME/.themes" "$SANDBOX/.themes"
HOME="$SANDBOX" DBUS_SESSION_BUS_ADDRESS="unix:path=/dev/null" \
    "$RICE/apply.sh" --theme "$THEME" --yes >/dev/null

echo "── Xvfb $DISP (${W}x${H})"
Xvfb "$DISP" -screen 0 ${W}x${H}x24 +extension GLX +extension RANDR +render -noreset \
    >/tmp/rice-xvfb.log 2>&1 &
sleep 1.5

export DISPLAY="$DISP" HOME="$SANDBOX" THEME SHOTS
REAL_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_RUNTIME_DIR="/tmp/rice-runtime-$THEME"
export PULSE_SERVER="unix:$REAL_RUNTIME/pulse/native"
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"

dbus-run-session -- bash -c '
    i3 > /tmp/rice-i3.log 2>&1 &
    sleep 5

    # 1) clean desktop: bar + wallpaper only
    import -window root "'"$SHOTS"'/"$THEME"-desktop.png"

    # 2) one terminal, given time to draw the shell + fastfetch
    alacritty --working-directory "$HOME" >/tmp/rice-alacritty.log 2>&1 &
    sleep 5
    import -window root "'"$SHOTS"'/"$THEME"-terminal.png"

    # populate three workspaces so the bar strip reads like a real session
    WS2=$(python3 "'"$RICE"'/lib/wsname.py" 2)
    WS3=$(python3 "'"$RICE"'/lib/wsname.py" 3)
    WS1=$(python3 "'"$RICE"'/lib/wsname.py" 1)
    i3-msg "workspace $WS2" >/dev/null 2>&1; (alacritty -e cava >/dev/null 2>&1 &); sleep 2
    i3-msg "workspace $WS3" >/dev/null 2>&1; (thunar >/dev/null 2>&1 &); sleep 2
    i3-msg "workspace $WS1" >/dev/null 2>&1; sleep 1

    # 3) real workload: fastfetch beside btop, sized so neither side is dead space
    i3-msg "split h" >/dev/null 2>&1; sleep 0.4
    alacritty -o font.size=14 -e btop >/dev/null 2>&1 &
    sleep 4
    i3-msg "focus left" >/dev/null 2>&1; sleep 0.3
    i3-msg "resize set width 46 ppt" >/dev/null 2>&1; sleep 0.6
    import -window root "'"$SHOTS"'/"$THEME"-main.png"

    # 4) rofi over the desktop
    rofi -show drun >/dev/null 2>&1 &
    sleep 2
    import -window root "'"$SHOTS"'/"$THEME"-rofi.png"
    sleep 0.3
    xdotool key Escape >/dev/null 2>&1 || true
' 2>/dev/null || true

echo "── logs"
echo "  i3:     $(grep -ciE "error|warn" /tmp/rice-i3.log || true) error/warn lines"
grep -iE "error|warn" /tmp/rice-i3.log | head -8 || true
echo "  picom:  $(grep -ciE "error|warn" /tmp/rice-picom.log 2>/dev/null || echo n/a)"
echo "  polybar: $(grep -ciE "error|warn" /tmp/rice-polybar.log 2>/dev/null || echo n/a)"

echo "── screenshots"
ls -1 "$SHOTS"/"$THEME"-*.png 2>/dev/null || echo "  none produced"

pkill -f "Xvfb $DISP" 2>/dev/null || true
