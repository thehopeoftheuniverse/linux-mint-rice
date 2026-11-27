#!/usr/bin/env bash
# Restore the newest backup created by apply.sh.
set -euo pipefail
RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HOME/.config"

BACKUP="${1:-}"
if [[ -z $BACKUP ]]; then
    BACKUP="$(find "$RICE/backups" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)"
fi
[[ -d $BACKUP && -f $BACKUP/.manifest ]] || { echo "no backup found in $RICE/backups" >&2; exit 1; }

echo "restoring from $BACKUP"

while IFS=: read -r kind path; do
    case "$kind" in
        existing)
            src="$BACKUP/$path"
            if [[ -d $src ]]; then
                rm -rf "${HOME:?}/$path"
                mkdir -p "$(dirname "$HOME/$path")"
                cp -a "$src" "$HOME/$path"
            else
                cp -a "$src" "$HOME/$path"
            fi
            echo "  restored $path"
            ;;
        created)
            rm -rf "${HOME:?}/$path"
            echo "  removed  $path (did not exist before)"
            ;;
    esac
done < "$BACKUP/.manifest"

[[ -f $HOME/.zshrc.pre-rice ]] && { mv "$HOME/.zshrc.pre-rice" "$HOME/.zshrc"; echo "  restored .zshrc"; }

echo
echo "done.  log out and choose the XFCE session to get the old desktop back."
