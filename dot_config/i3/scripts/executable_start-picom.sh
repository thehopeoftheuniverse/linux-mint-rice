#!/usr/bin/env bash
set -u

# Start picom safely across picom v9/v10 (Debian 12 / Mint 21-22), picom v12+ (animations), and VMs.
# Always tries full GLX + dual_kawase blur first so translucency/glass works; falls back to xrender if GLX fails.
command -v picom >/dev/null 2>&1 || exit 0

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ui-theme"
EFFECTS_FILE="$STATE_DIR/effects"
EFFECTS=""
[[ -r "$EFFECTS_FILE" ]] && EFFECTS="$(tr -d '[:space:]' < "$EFFECTS_FILE")"
EFFECTS="${EFFECTS:-full}"

pkill -u "$UID" -x picom 2>/dev/null || true
while pgrep -u "$UID" -x picom >/dev/null 2>&1; do
  sleep 0.1
done

[[ "$EFFECTS" == "off" ]] && exit 0

CONF_FULL="$HOME/.config/picom/picom.conf"
CONF_MINIMAL="$HOME/.config/picom/picom-minimal.conf"
CONF_COMPAT="/tmp/picom-compat-${UID}.conf"

PICOM_VER_RAW="$(picom --version 2>/dev/null | head -n1 || true)"
PICOM_MAJOR="$(sed -nE 's/^v?([0-9]+).*/\1/p' <<< "$PICOM_VER_RAW")"
PICOM_MAJOR="${PICOM_MAJOR:-10}"

prepare_config() {
  local src="$1"
  if (( PICOM_MAJOR >= 12 )); then
    printf '%s\n' "$src"
    return 0
  fi
  # Strip picom v12-only `animations = (...);` and `animations-exclude = [...];` for Debian/Mint picom < 12
  awk '
    /^animations[[:space:]]*=[[:space:]]*\(/ { skip_paren=1; next }
    skip_paren { if (/^\)[;]?[[:space:]]*$/) skip_paren=0; next }
    /^animations-exclude[[:space:]]*=[[:space:]]*\[/ { skip_brack=1; next }
    skip_brack { if (/^\][;]?[[:space:]]*$/) skip_brack=0; next }
    { print }
  ' "$src" > "$CONF_COMPAT"
  printf '%s\n' "$CONF_COMPAT"
}

launch_picom() {
  local cfg="$1"
  local extra=()
  if (( PICOM_MAJOR < 10 )) && picom --help 2>&1 | grep -q -- '--experimental-backends'; then
    extra+=(--experimental-backends)
  fi
  picom -b "${extra[@]}" --config "$cfg" >/dev/null 2>&1
}

if [[ "$EFFECTS" == "minimal" && -f "$CONF_MINIMAL" ]]; then
  cfg="$(prepare_config "$CONF_MINIMAL")"
  launch_picom "$cfg"
  exit $?
fi

cfg="$(prepare_config "$CONF_FULL")"
if launch_picom "$cfg"; then
  exit 0
fi

# Fallback to xrender minimal profile if GLX fails (e.g. headless/broken GPU driver)
if [[ -f "$CONF_MINIMAL" ]]; then
  cfg_min="$(prepare_config "$CONF_MINIMAL")"
  launch_picom "$cfg_min" || true
fi
