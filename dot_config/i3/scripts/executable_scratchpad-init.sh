#!/usr/bin/env bash
set -u

# Launch configured scratchpads only when their underlying commands exist
command -v kitty >/dev/null 2>&1 || exit 0

if ! pgrep -u "$UID" -f '^kitty --class kitty-monitor' >/dev/null 2>&1; then
  if command -v btop >/dev/null 2>&1; then
    kitty --class 'kitty-monitor' \
      --override window_margin_width=0 \
      --override remember_window_size=no \
      --override initial_window_width=1600 \
      --override initial_window_height=900 \
      --session "$HOME/.config/kitty/sessions/monitor.kitty-session" &
  elif command -v htop >/dev/null 2>&1; then
    kitty --class 'kitty-monitor' htop &
  fi
fi

if ! pgrep -u "$UID" -f '^kitty --class 1-scrtch' >/dev/null 2>&1; then
  kitty --class '1-scrtch' &
fi
if ! pgrep -u "$UID" -f '^kitty --class 2-scrtch' >/dev/null 2>&1; then
  kitty --class '2-scrtch' &
fi

if command -v yazi >/dev/null 2>&1 && ! pgrep -u "$UID" -f '^kitty --class yazi-scrtch' >/dev/null 2>&1; then
  if command -v zsh >/dev/null 2>&1; then
    kitty --class 'yazi-scrtch' zsh -ic "exec y" &
  else
    kitty --class 'yazi-scrtch' yazi &
  fi
fi

if command -v wiremix >/dev/null 2>&1 && ! pgrep -u "$UID" -f '^kitty --class wiremix-scrtch' >/dev/null 2>&1; then
  kitty --class 'wiremix-scrtch' wiremix &
elif command -v pulsemixer >/dev/null 2>&1 && ! pgrep -u "$UID" -f '^kitty --class wiremix-scrtch' >/dev/null 2>&1; then
  kitty --class 'wiremix-scrtch' pulsemixer &
elif command -v alsamixer >/dev/null 2>&1 && ! pgrep -u "$UID" -f '^kitty --class wiremix-scrtch' >/dev/null 2>&1; then
  kitty --class 'wiremix-scrtch' alsamixer &
fi

if command -v cliamp >/dev/null 2>&1 && ! pgrep -u "$UID" -f '^kitty --class cliamp-scrtch' >/dev/null 2>&1; then
  kitty --class 'cliamp-scrtch' cliamp &
fi

if [[ -x "$HOME/.local/bin/run-topgrade" ]] && ! pgrep -u "$UID" -f '^kitty --class upgrade' >/dev/null 2>&1; then
  env FROM_ROFI=1 kitty --class 'upgrade' --hold "$HOME/.local/bin/run-topgrade" &
fi

"$HOME/.config/i3/scripts/bluetui-start.sh" &
