#!/usr/bin/env bash
# Start (or restart) polybar cleanly on every connected monitor.
set -u

kill_running() { polybar-msg cmd quit >/dev/null 2>&1; pkill -x polybar >/dev/null 2>&1; }

# give the bar a moment on i3 reload
sleep 0.4

# default route interface, so the network module shows the live IP
NET_IF="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
export NET_IF="${NET_IF:-eth0}"

CONFIG="$HOME/.config/polybar/config.ini"
LOG="$HOME/.cache/polybar.log"
mkdir -p "$(dirname "$LOG")"
: > "$LOG"

# wait (max 5s) for the i3 IPC socket, the i3 module needs it
for _ in $(seq 1 25); do
    i3-msg -t get_version >/dev/null 2>&1 && break
    sleep 0.2
done

kill_running
for m in $(polybar --list-monitors | cut -d: -f1); do
    MONITOR="$m" polybar --reload -c "$CONFIG" top >>"$LOG" 2>&1 &
    sleep 0.2
done

if ! pgrep -x polybar >/dev/null; then
    MONITOR= polybar -c "$CONFIG" top >>"$LOG" 2>&1 &
fi
