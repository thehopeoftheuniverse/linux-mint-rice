#!/usr/bin/env bash
# ============================================================================
#  linux-mint-rice — bootstrap from nothing
#
#  curl -fsSL https://raw.githubusercontent.com/thehopeoftheuniverse/linux-mint-rice/main/bootstrap.sh | bash
#
#  Clones the repo into ~/.local/share/linux-mint-rice (or updates it) and runs
#  the installer.  Pass installer flags after `-s --`, e.g.
#      curl ... | bash -s -- --theme gruvbox --shell
# ============================================================================
set -Eeuo pipefail

REPO_URL="https://github.com/thehopeoftheuniverse/linux-mint-rice.git"
DEST="${RICING_DIR:-$HOME/.local/share/linux-mint-rice}"

command -v git >/dev/null || { echo "git is required: sudo apt install git" >&2; exit 1; }

if [[ -d "$DEST/.git" ]]; then
    echo "── updating $DEST"
    git -C "$DEST" pull --ff-only
else
    echo "── cloning into $DEST"
    mkdir -p "$(dirname "$DEST")"
    git clone --depth 1 "$REPO_URL" "$DEST"
fi

exec "$DEST/install.sh" "$@"
