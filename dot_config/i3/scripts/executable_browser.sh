#!/usr/bin/env bash
set -u

# Launch preferred installed browser on Debian/Mint
if [[ -n "${BROWSER:-}" ]] && command -v "${BROWSER%% *}" >/dev/null 2>&1; then
  exec $BROWSER "$@"
fi

for candidate in firefox firefox-esr brave-browser chromium chromium-browser google-chrome vivaldi vivaldi-stable; do
  if command -v "$candidate" >/dev/null 2>&1; then
    if [[ "$candidate" == vivaldi* ]]; then
      exec "$candidate" --password-store=gnome-libsecret "$@"
    fi
    exec "$candidate" "$@"
  fi
done

command -v xdg-open >/dev/null 2>&1 && exec xdg-open "https://start.duckduckgo.com"
