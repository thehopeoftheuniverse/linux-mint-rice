#!/usr/bin/python3
"""Procedural mesh wallpapers — smooth Gaussian colour fields, no compositing seams.

Rendering in float and dithering on the way down to 8-bit avoids the banding and
rectangular layer edges you get from compositing radial gradients.
"""
import numpy as np
from PIL import Image
from pathlib import Path

W, H = 1920, 1080
OUT = Path(__file__).resolve().parent / "wallpapers"
OUT.mkdir(exist_ok=True)


def hex2rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def mesh(name, bg, blobs, grain=1.0, vignette=0.35):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    img = np.ones((H, W, 3), dtype=np.float32) * hex2rgb(bg)

    for cx, cy, radius, colour, strength in blobs:
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
        a = np.exp(-np.clip(d, 0, 4) ** 2 * 1.6) * strength
        a = a[..., None]
        img = img * (1.0 - a) + hex2rgb(colour) * a

    # vignette: darken the corners a touch so the composition reads as intentional
    nx = (xx - W / 2) / (W / 2)
    ny = (yy - H / 2) / (H / 2)
    vig = 1.0 - vignette * np.clip((nx ** 2 + ny ** 2) / 2.0, 0, 1) ** 1.4
    img *= vig[..., None]

    # grain first, then quantise — the noise acts as dither
    rng = np.random.default_rng(7)
    img += rng.normal(0.0, grain, (H, W, 3)).astype(np.float32)

    img = np.clip(img, 0, 255).astype(np.uint8)
    Image.fromarray(img, "RGB").save(OUT / f"{name}.png", optimize=True)
    print(f"  {name}.png")


PAL = {
    "tokyonight": ("#12131c", [(300, 120, 900, "#7aa2f7", 0.55),
                               (1500, 380, 780, "#bb9af7", 0.42),
                               (1350, 900, 700, "#7dcfff", 0.30),
                               (760, 980, 620, "#9d7cd8", 0.18)]),
    "catppuccin": ("#181825", [(260, 180, 880, "#89b4fa", 0.55),
                               (1520, 420, 800, "#cba6f7", 0.45),
                               (1200, 950, 700, "#94e2d5", 0.28),
                               (700, 1000, 600, "#f5c2e7", 0.16)]),
    "gruvbox": ("#1d2021", [(320, 160, 900, "#fe8019", 0.40),
                            (1450, 400, 820, "#d3869b", 0.40),
                            (1250, 950, 720, "#fabd2f", 0.28),
                            (620, 980, 640, "#83a598", 0.20)]),
    "kanagawa": ("#16161d", [(340, 200, 900, "#7e9cd8", 0.52),
                             (1480, 360, 800, "#957fb8", 0.42),
                             (1300, 920, 700, "#7fb4ca", 0.30),
                             (700, 1010, 620, "#d27e99", 0.15)]),
}

print("mesh wallpapers:")
for name, (bg, blobs) in PAL.items():
    mesh(name, bg, blobs)
