#!/usr/bin/env bash
# Restore the newest backup created by install-debian.sh.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="${1:-}"

if [[ -z "$BACKUP" ]]; then
  BACKUP="$(find "$REPO_DIR/backups" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -n1 || true)"
fi
[[ -n "$BACKUP" && -d "$BACKUP" && -f "$BACKUP/.manifest" ]] || {
  echo "No backup found in $REPO_DIR/backups" >&2
  exit 1
}

echo "Restoring from $BACKUP..."

while IFS=: read -r kind relpath; do
  [[ -n "$kind" && -n "$relpath" ]] || continue
  case "$kind" in
    existing)
      src="$BACKUP/$relpath"
      if [[ -e "$src" ]]; then
        rm -rf "${HOME:?}/$relpath"
        mkdir -p "$(dirname "$HOME/$relpath")"
        cp -a "$src" "$HOME/$relpath"
        echo "  restored $relpath"
      fi
      ;;
    created)
      rm -rf "${HOME:?}/$relpath"
      echo "  removed  $relpath (did not exist before)"
      ;;
  esac
done < "$BACKUP/.manifest"

echo "Rollback complete. Select your previous session at the login screen if desired."
