#!/usr/bin/env bash
# Commit and publish whatever changed in this repo.
#   ./sync.sh                     → "chore: sync local config"
#   ./sync.sh "feat: new bind"
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

msg="${1:-chore: sync local config}"

if [[ -z $(git status --porcelain) ]]; then
    echo "nothing to commit — working tree clean"
    exit 0
fi

git add -A
git commit -q -m "$msg"
git push -q origin "$(git symbolic-ref --short HEAD)"
echo "committed + pushed: $(git log --oneline -1)"
