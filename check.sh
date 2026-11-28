#!/usr/bin/env bash
# Repository sanity checks: bash syntax, python syntax, JSON/TOML parsing, symlink hygiene.
set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

ok()   { printf '  [ok]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAIL=1; }

echo "== Shell syntax =="
while IFS= read -r -d '' f; do
  rel="${f#"$REPO_DIR"/}"
  if bash -n "$f" 2>/dev/null; then
    ok "$rel"
  else
    fail "$rel"
  fi
done < <(find "$REPO_DIR" \( -path '*/.git' -o -path '*/__pycache__' -o -path '*/backups' -o -path '*/build' \) -prune -o -type f \( -name '*.sh' -o -name 'executable_*' \) ! -name '*.tmpl' ! -name '*.bak' ! -name '*.py' ! -name '*.pyc' -print0 | sort -z)

PY=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "import sys" >/dev/null 2>&1; then
    PY="$cand"
    break
  fi
done

echo
echo "== Python syntax =="
if [[ -n "$PY" ]]; then
  while IFS= read -r -d '' f; do
    rel="${f#"$REPO_DIR"/}"
    if "$PY" -c "import ast, sys; ast.parse(open(sys.argv[1], 'rb').read(), filename=sys.argv[1])" "$f" 2>/dev/null; then
      ok "$rel"
    else
      fail "$rel"
    fi
  done < <(find "$REPO_DIR" \( -path '*/.git' -o -path '*/backups' -o -path '*/build' \) -prune -o -type f -name '*.py' -print0 | sort -z)

  echo
  echo "== Config data files =="
  for jf in "$REPO_DIR/dot_config/rofi-web-search/config.json"; do
    [[ -f "$jf" ]] || continue
    if "$PY" -m json.tool "$jf" >/dev/null 2>&1; then
      ok "${jf#"$REPO_DIR"/}"
    else
      fail "${jf#"$REPO_DIR"/}"
    fi
  done
  if "$PY" -c "import tomllib, sys; [tomllib.load(open(p,'rb')) for p in sys.argv[1:]]" \
      "$REPO_DIR/.chezmoidata.toml" \
      "$REPO_DIR/.chezmoidata/dependencies.toml" \
      "$REPO_DIR/dot_config/starship/starship.toml" 2>/dev/null; then
    ok "TOML configs valid"
  else
    fail "TOML config parse error"
  fi
else
  echo "  [skip] working python interpreter not found"
fi

echo
echo "== Symlink hygiene =="
bad_links=$(find "$REPO_DIR" -path '*/.git' -prune -o -type f -name 'symlink_*' -exec grep -l '/home/brozi' {} + 2>/dev/null || true)
if [[ -z "$bad_links" ]]; then
  ok "No hardcoded /home/brozi symlinks"
else
  fail "Hardcoded /home/brozi in: $bad_links"
fi

echo
if (( FAIL )); then
  echo "Checks FAILED."
  exit 1
fi
echo "All checks passed."
