#!/usr/bin/env bash
set -u

# Start picom safely across picom v9/v10 (Debian 12 / Mint 21-22), picom v12+ (animations), and VMs
command -v picom >/dev/null 2>&1 || exit 0

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
EFFECTS_FILE="$STATE_DIR/effects"
EFFECTS=""
[[ -r "$EFFECTS_FILE" ]] && EFFECTS="$(tr -d '[:space:]' < "$EFFECTS_FILE")"

# Auto-select lightweight xrender profile on VMs unless user explicitly picked one
if [[ -z "$EFFECTS" ]]; then
  if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt -q --vm 2>/dev/null; then
    EFFECTS="minimal"
  else
    EFFECTS="full"
  fi
fi

pkill -u "$UID" -x picom 2>/dev/null || true
while pgrep -u "$UID" -x picom >/dev/null 2>&1; do
  sleep 0.1
done

[[ "$EFFECTS" == "off" ]] && exit 0

CONF_FULL="$HOME/.config/picom/picom.conf"
CONF_MINIMAL="$HOME/.config/picom/picom-minimal.conf"
CONF_COMPAT="/tmp/picom-compat-${UID}.conf"

SRC_CONF="$CONF_FULL"
if [[ "$EFFECTS" == "minimal" && -f "$CONF_MINIMAL" ]]; then
  SRC_CONF="$CONF_MINIMAL"
fi

PICOM_VER_RAW="$(picom --version 2>/dev/null | head -n1 || true)"
PICOM_MAJOR="$(sed -nE 's/^v?([0-9]+).*/\1/p' <<< "$PICOM_VER_RAW")"
PICOM_MAJOR="${PICOM_MAJOR:-10}"

if (( PICOM_MAJOR >= 12 )); then
  exec picom -b --config "$SRC_CONF"
fi

# Strip picom v12-only `animations = (...);` and `animations-exclude = [...];` for Debian/Mint picom < 12
awk '
  /^animations[[:space:]]*=[[:space:]]*\(/ { skip_paren=1; next }
  skip_paren { if (/^\)[;]?[[:space:]]*$/) skip_paren=0; next }
  /^animations-exclude[[:space:]]*=[[:space:]]*\[/ { skip_brack=1; next }
  skip_brack { if (/^\][;]?[[:space:]]*$/) skip_brack=0; next }
  { print }
' "$SRC_CONF" > "$CONF_COMPAT"

if (( PICOM_MAJOR < 10 )) && picom --help 2>&1 | grep -q -- '--experimental-backends'; then
  exec picom -b --experimental-backends --config "$CONF_COMPAT"
fi

exec picom -b --config "$CONF_COMPAT"
