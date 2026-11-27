#!/usr/bin/env bash
# Live LAN IP; VMware often reports operstate=unknown so polybar's
# internal/network misreads it as offline.
ip="$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)"
if [[ -n $ip ]]; then
    printf '%%{F@CYAN@}%s%%{F-}\n' "$ip"
else
    printf '%%{F@RED@}offline%%{F-}\n'
fi
