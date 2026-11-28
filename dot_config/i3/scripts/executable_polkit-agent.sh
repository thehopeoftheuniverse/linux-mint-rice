#!/usr/bin/env bash
set -u

# Launch whichever polkit authentication agent is installed on Debian/Mint/Ubuntu
CANDIDATES=(
  /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
  /usr/libexec/polkit-gnome-authentication-agent-1
  /usr/lib/x86_64-linux-gnu/polkit-gnome/polkit-gnome-authentication-agent-1
  /usr/libexec/polkit-mate-authentication-agent-1
  /usr/lib/x86_64-linux-gnu/polkit-mate-authentication-agent-1
  /usr/lib/mate-polkit/polkit-mate-authentication-agent-1
  /usr/bin/lxpolkit
  /usr/bin/lxqt-policykit-agent
  /usr/libexec/lxqt-policykit-agent
)

for agent in "${CANDIDATES[@]}"; do
  if [[ -x "$agent" ]]; then
    pgrep -u "$UID" -f "$(basename "$agent")" >/dev/null 2>&1 && exit 0
    exec "$agent"
  fi
done
