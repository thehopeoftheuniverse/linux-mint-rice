#!/usr/bin/env bash
set -u

# Theme-aware screen locker for Debian/Mint (supports i3lock-color and stock i3lock)
command -v i3lock >/dev/null 2>&1 || exit 0

# Avoid spawning duplicate lockers
pgrep -u "$UID" -x i3lock >/dev/null 2>&1 && exit 0

THEME_STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme/theme"
THEME="catppuccin-mocha"
if [[ -r "$THEME_STATE_FILE" ]]; then
  THEME="$(tr -d '[:space:]' < "$THEME_STATE_FILE")"
fi

case "$THEME" in
  ultra-instinct)
    BG_HEX="050508"
    RING_HEX="1a1d2bff"
    INSIDE_HEX="0a0b10cc"
    KEY_HEX="7df9ffff"
    VERIFY_HEX="c084fcff"
    WRONG_HEX="fb7185ff"
    TEXT_HEX="f4f7ffff"
    ;;
  goku-ssj4)
    BG_HEX="080406"
    RING_HEX="351622ff"
    INSIDE_HEX="0d0609cc"
    KEY_HEX="ef233cff"
    VERIFY_HEX="fbbf24ff"
    WRONG_HEX="ff3b5cff"
    TEXT_HEX="fff1f2ff"
    ;;
  tokyo-night)
    BG_HEX="1a1b26"
    RING_HEX="292e42ff"
    INSIDE_HEX="16161ecc"
    KEY_HEX="7aa2f7ff"
    VERIFY_HEX="bb9af7ff"
    WRONG_HEX="f7768eff"
    TEXT_HEX="c0caf5ff"
    ;;
  rose-pine)
    BG_HEX="191724"
    RING_HEX="26233aff"
    INSIDE_HEX="191724cc"
    KEY_HEX="ebbcbaFF"
    VERIFY_HEX="c4a7e7ff"
    WRONG_HEX="eb6f92ff"
    TEXT_HEX="e0def4ff"
    ;;
  ddlc)
    BG_HEX="0e0910"
    RING_HEX="3a2642ff"
    INSIDE_HEX="130c16cc"
    KEY_HEX="ff6b9dff"
    VERIFY_HEX="34d399ff"
    WRONG_HEX="f43f5eff"
    TEXT_HEX="fff0f6ff"
    ;;
  bleach-yhwach)
    BG_HEX="040405"
    RING_HEX="2a2a30ff"
    INSIDE_HEX="08080acc"
    KEY_HEX="ffffffff"
    VERIFY_HEX="d4d4d8ff"
    WRONG_HEX="e4e4e7ff"
    TEXT_HEX="fafafaff"
    ;;
  sasuke)
    BG_HEX="06040c"
    RING_HEX="2d2152ff"
    INSIDE_HEX="0a0714cc"
    KEY_HEX="a855f7ff"
    VERIFY_HEX="c084fcff"
    WRONG_HEX="f43f5eff"
    TEXT_HEX="f5f3ffff"
    ;;
  *)
    BG_HEX="1e1e2e"
    RING_HEX="313244ff"
    INSIDE_HEX="181825cc"
    KEY_HEX="b4befeff"
    VERIFY_HEX="cba6f7ff"
    WRONG_HEX="f38ba8ff"
    TEXT_HEX="cdd6f4ff"
    ;;
esac

# Pause media players cleanly on lock if desired? No, let user control via audio idle.
# Detect i3lock-color vs stock Debian i3lock
if i3lock --version 2>&1 | grep -qiE 'color|ring|Raymond'; then
  exec i3lock -n -e \
    --color="${BG_HEX}ff" \
    --inside-color="$INSIDE_HEX" \
    --ring-color="$RING_HEX" \
    --line-uses-inside \
    --keyhl-color="$KEY_HEX" \
    --bshl-color="$WRONG_HEX" \
    --separator-color="$RING_HEX" \
    --insidever-color="$INSIDE_HEX" \
    --ringver-color="$VERIFY_HEX" \
    --insidewrong-color="$INSIDE_HEX" \
    --ringwrong-color="$WRONG_HEX" \
    --verif-color="$TEXT_HEX" \
    --wrong-color="$WRONG_HEX" \
    --time-color="$TEXT_HEX" \
    --date-color="$KEY_HEX" \
    --clock \
    --indicator \
    --time-str="%H:%M" \
    --date-str="%A, %d %b" \
    --radius=110 \
    --ring-width=7
fi

# Fallback for stock Debian/Mint i3lock: generate blurred/darkened screenshot if possible
if command -v scrot >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
  LOCK_RAW="$(mktemp "/tmp/i3lock_raw_${UID}_XXXXXX.png")"
  LOCK_IMG="$(mktemp "/tmp/i3lock_${UID}_XXXXXX.png")"
  trap 'rm -f "$LOCK_RAW" "$LOCK_IMG"' EXIT
  if scrot -o -z "$LOCK_RAW" 2>/dev/null && \
     convert "$LOCK_RAW" -scale 10% -blur 0x2.5 -scale 1000% -fill "#${BG_HEX}" -colorize 45% "$LOCK_IMG" 2>/dev/null && \
     [[ -s "$LOCK_IMG" ]]; then
    rm -f "$LOCK_RAW"
    i3lock -n -e -i "$LOCK_IMG"
    exit $?
  fi
  rm -f "$LOCK_RAW" "$LOCK_IMG"
  trap - EXIT
fi

exec i3lock -n -e -c "$BG_HEX"
