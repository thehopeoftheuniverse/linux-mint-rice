#!/usr/bin/env bash
# ============================================================================
#  VM tuning — makes a 4.6 GB / 4 vCPU box feel much bigger.
#  Default is a dry run.  Use --apply to write, --undo to remove.
# ============================================================================
set -euo pipefail
MODE="dry"
[[ ${1:-} == --apply ]] && MODE="apply"
[[ ${1:-} == --undo  ]] && MODE="undo"

run() {
    if [[ $MODE == apply ]]; then
        echo "  + $*"
        eval "$@"
    else
        echo "  · $*"
    fi
}
ok()   { echo "  [ok] $*"; }
warn() { echo "  [!]  $*"; }

# swap is compressed RAM here; each family wires zram differently
if [[ -f /etc/os-release ]]; then . /etc/os-release; fi
case "${ID:-}" in
    fedora|rhel|centos|rocky|almalinux) FAMILY=fedora ;;
    arch|manjaro|endeavouros|garuda|artix) FAMILY=arch ;;
    *) FAMILY=debian ;;
esac

echo "── zram (compressed RAM swap, ~50% of RAM) — $FAMILY"
if [[ $MODE == undo ]]; then
    case $FAMILY in
        debian)
            run "sudo systemctl disable --now zramswap 2>/dev/null || true"
            run "sudo rm -f /etc/default/zramswap" ;;
        *)
            run "sudo rm -f /etc/systemd/zram-generator.conf"
            run "sudo systemctl daemon-reload"
            run "sudo systemctl stop 'systemd-zram-setup@zram0.service' 2>/dev/null || true" ;;
    esac
else
    case $FAMILY in
        debian)
            if command -v zramswap >/dev/null || [[ -e /etc/default/zramswap ]]; then
                run "sudo tee /etc/default/zramswap >/dev/null <<'EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF"
                run "sudo systemctl enable --now zramswap 2>/dev/null || true"
            else
                warn "zram-tools is not installed — run: sudo apt install zram-tools"
            fi ;;
        fedora|arch)
            if zramctl --noheadings 2>/dev/null | grep -q zram; then
                ok "zram is already active — leaving it alone"
            elif [[ $FAMILY == arch ]] && ! command -v zramctl >/dev/null; then
                warn "install zram-generator first: sudo pacman -S zram-generator"
            else
                run "sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF"
                run "sudo systemctl daemon-reload"
                run "sudo systemctl start 'systemd-zram-setup@zram0.service' 2>/dev/null || true"
            fi ;;
    esac
fi

echo
echo "── sysctl (swappiness tuned for zram, smaller dirty pages)"
if [[ $MODE == undo ]]; then
    run "sudo rm -f /etc/sysctl.d/99-rice.conf"
    run "sudo sysctl --system >/dev/null"
else
    run "sudo tee /etc/sysctl.d/99-rice.conf >/dev/null <<'EOF'
vm.swappiness = 180
vm.vfs_cache_pressure = 50
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.watermark_boost_factor = 0
vm.page-cluster = 0
fs.inotify.max_user_watches = 524288
EOF"
    run "sudo sysctl --system >/dev/null"
fi

echo
echo "── journald capped at 200 MB"
run "sudo mkdir -p /etc/systemd/journald.conf.d"
if [[ $MODE == undo ]]; then
    run "sudo rm -f /etc/systemd/journald.conf.d/99-rice.conf"
else
    run "sudo tee /etc/systemd/journald.conf.d/99-rice.conf >/dev/null <<'EOF'
[Journal]
SystemMaxUse=200M
RuntimeMaxUse=64M
EOF"
fi
run "sudo systemctl restart systemd-journald 2>/dev/null || true"

echo
echo "── services you almost certainly do not need in a VM"
for svc in cups cups-browsed ModemManager avahi-daemon bluetooth; do
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
        [[ $MODE == undo ]] && run "sudo systemctl enable --now $svc 2>/dev/null || true" \
                            || run "sudo systemctl disable --now $svc 2>/dev/null || true"
    fi
done

echo
echo "── showing the truth: what actually eats RAM"
ps -eo pmem,rss,comm --sort=-rss | head -12

echo
[[ $MODE == dry ]] && echo "dry run — nothing changed. re-run with --apply"
exit 0
