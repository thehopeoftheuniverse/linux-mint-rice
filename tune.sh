#!/usr/bin/env bash
# Optional VM / low-RAM laptop tuning (dry-run by default).
# Usage: ./tune.sh | sudo ./tune.sh --apply | sudo ./tune.sh --undo
set -euo pipefail

MODE="dry"
[[ "${1:-}" == "--apply" ]] && MODE="apply"
[[ "${1:-}" == "--undo" ]] && MODE="undo"

run() {
  if [[ "$MODE" == "apply" || "$MODE" == "undo" ]]; then
    echo "  + $*"
    eval "$@"
  else
    echo "  · $*"
  fi
}
ok()   { echo "  [ok] $*"; }
warn() { echo "  [!]  $*"; }

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi
case "${ID:-}" in
  fedora|rhel|centos|rocky|almalinux) FAMILY=fedora ;;
  arch|manjaro|endeavouros|garuda|artix) FAMILY=arch ;;
  *) FAMILY=debian ;;
esac

echo "== zram (compressed RAM swap, ~50% of RAM) — $FAMILY =="
if [[ "$MODE" == "undo" ]]; then
  case "$FAMILY" in
    debian)
      run "sudo systemctl disable --now zramswap 2>/dev/null || true"
      run "sudo rm -f /etc/default/zramswap"
      ;;
    *)
      run "sudo rm -f /etc/systemd/zram-generator.conf"
      run "sudo systemctl daemon-reload"
      run "sudo systemctl stop 'systemd-zram-setup@zram0.service' 2>/dev/null || true"
      ;;
  esac
else
  case "$FAMILY" in
    debian)
      if command -v zramswap >/dev/null 2>&1 || [[ -e /etc/default/zramswap ]]; then
        run "sudo tee /etc/default/zramswap >/dev/null <<'EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF"
        run "sudo systemctl enable --now zramswap 2>/dev/null || true"
      else
        warn "zram-tools not installed (run: sudo apt install zram-tools)"
      fi
      ;;
    fedora|arch)
      if zramctl --noheadings 2>/dev/null | grep -q zram; then
        ok "zram already active"
      else
        run "sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF"
        run "sudo systemctl daemon-reload"
        run "sudo systemctl start 'systemd-zram-setup@zram0.service' 2>/dev/null || true"
      fi
      ;;
  esac
fi

echo
echo "== sysctl (zram-friendly swappiness & inotify watches) =="
if [[ "$MODE" == "undo" ]]; then
  run "sudo rm -f /etc/sysctl.d/99-dotfiles-tune.conf"
  run "sudo sysctl --system >/dev/null"
else
  run "sudo tee /etc/sysctl.d/99-dotfiles-tune.conf >/dev/null <<'EOF'
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
echo "== journald cap (200 MB) =="
run "sudo mkdir -p /etc/systemd/journald.conf.d"
if [[ "$MODE" == "undo" ]]; then
  run "sudo rm -f /etc/systemd/journald.conf.d/99-dotfiles-tune.conf"
else
  run "sudo tee /etc/systemd/journald.conf.d/99-dotfiles-tune.conf >/dev/null <<'EOF'
[Journal]
SystemMaxUse=200M
RuntimeMaxUse=64M
EOF"
fi
run "sudo systemctl restart systemd-journald 2>/dev/null || true"

echo
[[ "$MODE" == "dry" ]] && echo "Dry run — nothing changed. Re-run with --apply (or --undo)."
exit 0
