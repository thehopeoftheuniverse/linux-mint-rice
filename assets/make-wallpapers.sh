#!/usr/bin/env bash
# Procedural wallpapers, one per palette + two Tokyo Night abstracts.
set -euo pipefail
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wallpapers"
mkdir -p "$OUT"
IM="$(command -v magick || command -v convert)"
[[ -n $IM ]] || { echo "imagemagick missing" >&2; exit 1; }
W=1920; H=1080

# ── palette mesh (python: float maths, no compositing seams) ────────────────
"$(dirname "${BASH_SOURCE[0]}")/make-wallpapers.py"

# ── perspective grid (tokyonight) ───────────────────────────────────────────
draw="$(python3 - <<'PY'
W, H = 1920, 1080
vx, vy = 960, 430
out = []
for i in range(-16, 17):
    x = 960 + i * 130
    out.append(f"line {vx},{vy} {x},{H}")
rows = []
y, step = vy, 6
while y < H:
    step *= 1.26
    y += step
    if y < H:
        rows.append(round(y))
for y in rows:
    out.append(f"line 0,{y} {W},{y}")
print(" ".join(out))
PY
)"
"$IM" -size ${W}x${H} xc:"#12131c" \
    -stroke "#7aa2f7" -strokewidth 1 -fill none -draw "$draw" \
    -blur 0x9 -fill "#7aa2f766" -colorize 0 \
    \( +clone -blur 0x2 \) -compose screen -composite \
    -depth 8 -attenuate 0.04 +noise Gaussian -blur 0x0.25 \
    -define png:compression-level=9 -strip -colorspace sRGB "$OUT/abstract-grid.png"
echo "  abstract-grid.png"

# ── flowing waves ───────────────────────────────────────────────────────────
draw="$(python3 - <<'PY'
W, H = 1920, 1080
paths = []
for k in range(26):
    amp = 26 + k * 3
    phase = k * 0.55
    y0 = 120 + k * 34
    pts = []
    for x in range(-20, W + 20, 12):
        import math
        y = y0 + math.sin(x / 190.0 + phase) * amp + math.sin(x / 61.0 + phase) * 6
        pts.append(f"{x},{round(y,1)}")
    paths.append("polyline " + " ".join(pts))
print(" ".join(paths))
PY
)"
"$IM" -size ${W}x${H} xc:"#12131c" \
    -stroke "#7dcfff55" -strokewidth 1 -fill none -draw "$draw" \
    -blur 0x0.6 \
    -fill none -stroke "#bb9af788" -strokewidth 2 -draw "polyline 0,760 960,300 1920,760" \
    -depth 8 -attenuate 0.02 +noise Gaussian -define png:compression-level=9 -strip \
    -colorspace sRGB "$OUT/abstract-waves.png"
echo "  abstract-waves.png"
