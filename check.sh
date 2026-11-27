#!/usr/bin/env bash
# ============================================================================
#  Sanity checks — run before committing or after editing a template.
#  Renders every palette and validates the result. No root, no display.
# ============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
note() { printf '%-46s %s\n' "$1" "$2"; }
bad()  { FAIL=1; printf '%-46s %sFAIL%s\n' "$1" "$(printf '\e[31m')" "$(printf '\e[0m')"; }

echo "── shell syntax"
for f in "$REPO_DIR"/*.sh "$REPO_DIR"/lib/*.sh "$REPO_DIR"/assets/*.sh \
         "$REPO_DIR"/templates/*/scripts/*.sh; do
    [[ -f $f ]] || continue
    if bash -n "$f" 2>/dev/null; then note "  ${f#"$REPO_DIR"/}" "ok"; else bad "  ${f#"$REPO_DIR"/}"; fi
done

echo
echo "── python syntax"
for f in "$REPO_DIR"/lib/*.py "$REPO_DIR"/assets/*.py; do
    [[ -f $f ]] || continue
    if python3 -m py_compile "$f" 2>/dev/null; then note "  ${f#"$REPO_DIR"/}" "ok"; else bad "  ${f#"$REPO_DIR"/}"; fi
done

echo
echo "── templates"
for theme_file in "$REPO_DIR"/themes/*.theme; do
    theme="$(basename "$theme_file" .theme)"
    out="/tmp/rice-check-$theme"
    rm -rf "$out"
    if ! python3 "$REPO_DIR/lib/render.py" "$theme_file" "$REPO_DIR/templates" "$out" >/dev/null; then
        bad "  render $theme"; continue
    fi

    if command -v i3 >/dev/null; then
        if i3 -C -c "$out/i3/config" >/dev/null 2>&1; then note "  $theme · i3 config" "ok"; else bad "  $theme · i3 config"; fi
    fi

    unresolved="$(grep -rho '@[A-Z0-9_]\{3,\}@' "$out" | sort -u | head -5)"
    if [[ -z $unresolved ]]; then note "  $theme · tokens resolved" "ok"; else bad "  $theme · unresolved: $unresolved"; fi

    if grep -rq '##[0-9a-fA-F]\{6\}' "$out" 2>/dev/null; then
        bad "  $theme · double-hex colour: $(grep -rl '##[0-9a-fA-F]\{6\}' "$out" | head -2 | tr '\n' ' ')"
    else
        note "  $theme · colours" "ok"
    fi

    rm -rf "$out"
done

echo
echo "── polybar config"
dupes="$(python3 - "$REPO_DIR/build/tokyonight/polybar/config.ini" <<'PY'
import sys, re
try:
    text = open(sys.argv[1]).read()
except OSError:
    sys.exit(0)
section, seen, out = None, {}, []
for line in text.splitlines():
    m = re.match(r"\[([^]]+)\]", line.strip())
    if m:
        section = m.group(1); seen[section] = set(); continue
    if "=" in line and not line.strip().startswith(";"):
        key = line.split("=", 1)[0].strip()
        if section and key in seen[section]:
            out.append(f"{section}.{key}")
        seen.setdefault(section, set()).add(key)
print(", ".join(sorted(set(out))))
PY
)"
if [[ -z $dupes ]]; then note "  no duplicate keys" "ok"; else bad "  duplicate keys: $dupes"; fi

echo
echo "── package lists"
for f in debian fedora arch; do
    if [[ -s "$REPO_DIR/packages/$f.txt" ]]; then
        note "  packages/$f.txt ($(grep -vcE '^\s*(#|$)' "$REPO_DIR/packages/$f.txt") entries)" "ok"
    else
        bad "  packages/$f.txt"
    fi
done

echo
if (( FAIL )); then
    printf '\e[31m%s\e[0m\n' "checks failed"
    exit 1
fi
printf '\e[32m%s\e[0m\n' "all checks passed"
