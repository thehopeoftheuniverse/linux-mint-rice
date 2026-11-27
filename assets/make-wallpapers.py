#!/usr/bin/env python3
"""Procedural r/unixporn-inspired wallpapers (1920x1080, fBm terrain + dithered).

Generates one signature landscape artwork per theme plus clean abstract
wallpapers using pure numpy + Pillow with multi-octave fractal ridges and
atmospheric depth.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
OUT = Path(__file__).resolve().parent / "wallpapers"
OUT.mkdir(exist_ok=True)


def hex2rgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def vertical_gradient(top: str, mid: str, bot: str, mid_pos: float = 0.55) -> np.ndarray:
    y = np.linspace(0.0, 1.0, H, dtype=np.float32)[:, None, None]
    c_top, c_mid, c_bot = hex2rgb(top), hex2rgb(mid), hex2rgb(bot)
    t1 = np.clip(y / mid_pos, 0.0, 1.0)
    t2 = np.clip((y - mid_pos) / (1.0 - mid_pos), 0.0, 1.0)
    upper = c_top * (1.0 - t1) + c_mid * t1
    lower = c_mid * (1.0 - t2) + c_bot * t2
    canvas = np.where(y < mid_pos, upper, lower)
    return np.broadcast_to(canvas, (H, W, 3)).copy()


def add_glow(img: np.ndarray, cx: float, cy: float, rx: float, ry: float, color: str, strength: float) -> np.ndarray:
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d2 = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    a = np.exp(-np.clip(d2, 0.0, 12.0) * 1.35) * strength
    return img * (1.0 - a[..., None]) + hex2rgb(color) * a[..., None]


def add_nebula(img: np.ndarray, seed: int, color: str, strength: float, max_y: int = 680) -> np.ndarray:
    """Soft tilted atmospheric sky wisps using 2D harmonic interference."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    nx, ny = xx / W, yy / H
    field = np.zeros((H, W), dtype=np.float32)
    for k in range(5):
        fx = float(rng.uniform(1.5, 4.5))
        fy = float(rng.uniform(2.0, 6.0))
        ph = float(rng.uniform(0.0, 6.28))
        field += np.sin(nx * fx * np.pi + ny * fy * np.pi + ph) * (0.55 ** k)
    field = np.clip((field - 0.1) * 0.5, 0.0, 1.0)
    vert_mask = np.exp(-((yy - max_y * 0.45) / (max_y * 0.42)) ** 2)
    alpha = field * vert_mask * strength
    return img * (1.0 - alpha[..., None]) + hex2rgb(color) * alpha[..., None]


def add_stars(img: np.ndarray, seed: int, count: int, color: str, max_y: int = 620) -> np.ndarray:
    rng = np.random.default_rng(seed)
    c = hex2rgb(color)
    for _ in range(count):
        x = int(rng.integers(20, W - 20))
        y = int(rng.integers(20, max_y))
        r = rng.choice([1, 1, 1, 2])
        alpha = float(rng.uniform(0.18, 0.78)) * (1.0 - y / (max_y * 1.15))
        if alpha <= 0:
            continue
        if r == 1:
            img[y, x] = img[y, x] * (1.0 - alpha) + c * alpha
        else:
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    w = alpha * (0.9 if dx == 0 and dy == 0 else 0.30)
                    img[y + dy, x + dx] = img[y + dy, x + dx] * (1.0 - w) + c * w
    return img


def fbm_ridge(x: np.ndarray, base_y: float, amp: float, seed: int, octaves: int = 6, ridged: bool = True) -> np.ndarray:
    """1D multi-octave fractal Brownian motion / ridged mountain silhouette."""
    rng = np.random.default_rng(seed)
    t = x / float(W)
    y = np.zeros_like(t, dtype=np.float32)
    cur_amp = amp
    freq = 2.4
    for _ in range(octaves):
        # Smooth value noise over random control knots
        n_knots = max(6, int(freq * 4) + 2)
        knots = rng.uniform(-1.0, 1.0, size=n_knots).astype(np.float32)
        u = np.linspace(0, n_knots - 1, W, dtype=np.float32)
        idx = np.clip(np.floor(u).astype(np.int32), 0, n_knots - 2)
        frac = u - idx
        # Quintic smoothstep interpolation
        s = frac * frac * frac * (frac * (frac * 6.0 - 15.0) + 10.0)
        val = knots[idx] * (1.0 - s) + knots[idx + 1] * s
        if ridged:
            val = 1.0 - np.abs(val) * 2.0
        y += val * cur_amp
        cur_amp *= 0.50
        freq *= 2.05
    return base_y - y


def draw_ridge_layer(
    img: np.ndarray,
    ys: np.ndarray,
    fill_top: str,
    fill_bot: str,
    rim_color: str | None = None,
    rim_alpha: float = 0.22,
    mist_color: str | None = None,
    mist_strength: float = 0.14,
) -> np.ndarray:
    yy = np.arange(H, dtype=np.float32)[:, None]
    ridge = ys[None, :]
    cov = np.clip((yy - ridge + 0.75) / 1.5, 0.0, 1.0)

    if mist_color:
        mist_dist = np.clip((ridge - yy) / 150.0, 0.0, 1.0)
        above = (yy < ridge).astype(np.float32)
        mist = np.exp(-mist_dist * 3.0) * above * mist_strength
        img = img * (1.0 - mist[..., None]) + hex2rgb(mist_color) * mist[..., None]

    depth = np.clip((yy - ridge) / max(130.0, H - float(np.min(ys))), 0.0, 1.0)
    c1, c2 = hex2rgb(fill_top), hex2rgb(fill_bot)
    fill = c1 * (1.0 - depth[..., None]) + c2 * depth[..., None]
    img = img * (1.0 - cov[..., None]) + fill * cov[..., None]

    if rim_color:
        rim = np.exp(-((yy - (ridge + 0.9)) / 1.6) ** 2) * rim_alpha
        img = img * (1.0 - rim[..., None]) + hex2rgb(rim_color) * rim[..., None]
    return img


def draw_textured_moon(
    img: np.ndarray, cx: float, cy: float, radius: float, light_col: str, shadow_col: str, halo_col: str, seed: int
) -> np.ndarray:
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dx, dy = xx - cx, yy - cy
    d = np.sqrt(dx * dx + dy * dy)
    moon = np.clip((radius - d) / 1.5, 0.0, 1.0)
    halo = np.exp(-np.clip((d - radius * 0.92) / (radius * 1.9), 0.0, 8.0) ** 1.45) * 0.25
    img = img * (1.0 - halo[..., None]) + hex2rgb(halo_col) * halo[..., None]

    # Subtle 3D spherical shading + mare texture
    nx = np.clip(dx / radius, -1.0, 1.0)
    ny = np.clip(dy / radius, -1.0, 1.0)
    shade = np.clip(0.62 + 0.38 * (-nx * 0.45 - ny * 0.35), 0.25, 1.0)
    rng = np.random.default_rng(seed)
    mare = np.sin(nx * 4.2 + 0.8) * np.cos(ny * 3.7 - 0.5) * 0.08 + rng.normal(0.0, 0.015, (H, W)).astype(np.float32)
    t = np.clip(shade + mare, 0.0, 1.0)[..., None]
    moon_col = hex2rgb(shadow_col) * (1.0 - t) + hex2rgb(light_col) * t
    return img * (1.0 - moon[..., None]) + moon_col * moon[..., None]


def finish(img: np.ndarray, path: Path, vignette: float = 0.26, grain: float = 0.80) -> None:
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    nx = (xx - W / 2.0) / (W / 2.0)
    ny = (yy - H / 2.0) / (H / 2.0)
    vig = 1.0 - vignette * np.clip((nx ** 2 + ny ** 2) / 2.0, 0.0, 1.0) ** 1.5
    img *= vig[..., None]
    rng = np.random.default_rng(42)
    img += rng.normal(0.0, grain, (H, W, 3)).astype(np.float32)
    arr = np.clip(img, 0, 255).astype(np.uint8)
    Image.fromarray(arr, "RGB").save(path, optimize=True)
    print(f"  {path.name}")


def make_tokyonight() -> None:
    img = vertical_gradient("#0f101a", "#1a1b26", "#262b42", 0.62)
    img = add_nebula(img, seed=101, color="#7aa2f7", strength=0.09, max_y=640)
    img = add_nebula(img, seed=102, color="#bb9af7", strength=0.06, max_y=580)
    img = add_glow(img, 1380, 290, 480, 400, "#7aa2f7", 0.20)
    img = add_stars(img, seed=11, count=170, color="#c0caf5", max_y=560)
    img = draw_textured_moon(img, 1380, 290, 72.0, "#dce6ff", "#8aa8ee", "#7dcfff", seed=17)

    x = np.arange(W, dtype=np.float32)
    layers = [
        (fbm_ridge(x, 535, 115, seed=10, octaves=6), "#272c44", "#1a1b26", "#7aa2f7", 0.14, "#7aa2f7", 0.12),
        (fbm_ridge(x, 650, 95,  seed=21, octaves=6), "#202438", "#16161e", "#7dcfff", 0.16, "#bb9af7", 0.09),
        (fbm_ridge(x, 770, 78,  seed=32, octaves=6), "#1a1c2a", "#13141c", "#7aa2f7", 0.20, "#7aa2f7", 0.08),
        (fbm_ridge(x, 890, 56,  seed=43, octaves=5), "#15161f", "#0f1016", "#bb9af7", 0.15, None, 0.0),
    ]
    for ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s in layers:
        img = draw_ridge_layer(img, ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s)
    finish(img, OUT / "tokyonight.png", vignette=0.25)


def make_catppuccin() -> None:
    img = vertical_gradient("#11111b", "#181825", "#26273c", 0.65)
    img = add_nebula(img, seed=201, color="#cba6f7", strength=0.10, max_y=620)
    img = add_nebula(img, seed=202, color="#89b4fa", strength=0.07, max_y=650)
    img = add_glow(img, 510, 280, 500, 400, "#cba6f7", 0.20)
    img = add_stars(img, seed=22, count=155, color="#cdd6f4", max_y=580)

    # Textured pastel crescent moon
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d_outer = np.sqrt((xx - 510) ** 2 + (yy - 280) ** 2)
    d_inner = np.sqrt((xx - 546) ** 2 + (yy - 262) ** 2)
    crescent = np.clip(np.clip((68.0 - d_outer) / 1.5, 0.0, 1.0) - np.clip((58.0 - d_inner) / 1.5, 0.0, 1.0), 0.0, 1.0)
    halo = np.exp(-np.clip((d_outer - 50.0) / 135.0, 0.0, 8.0) ** 1.4) * 0.22
    img = img * (1.0 - halo[..., None]) + hex2rgb("#f5c2e7") * halo[..., None]
    shade = np.clip(0.82 + 0.18 * (-(xx - 510) / 68.0), 0.65, 1.0)[..., None]
    moon_col = hex2rgb("#cba6f7") * (1.0 - shade) + hex2rgb("#f5e0dc") * shade
    img = img * (1.0 - crescent[..., None]) + moon_col * crescent[..., None]

    x = np.arange(W, dtype=np.float32)
    layers = [
        (fbm_ridge(x, 560, 105, seed=51, octaves=6, ridged=False), "#2b2c40", "#1e1e2e", "#cba6f7", 0.18, "#cba6f7", 0.12),
        (fbm_ridge(x, 680, 88,  seed=62, octaves=6, ridged=True),  "#232336", "#181825", "#89b4fa", 0.20, "#89b4fa", 0.09),
        (fbm_ridge(x, 800, 68,  seed=73, octaves=5, ridged=False), "#1a1a29", "#13131f", "#94e2d5", 0.17, "#94e2d5", 0.06),
        (fbm_ridge(x, 910, 44,  seed=84, octaves=5, ridged=False), "#13131d", "#0e0e16", "#f5c2e7", 0.14, None, 0.0),
    ]
    for ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s in layers:
        img = draw_ridge_layer(img, ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s)
    finish(img, OUT / "catppuccin.png", vignette=0.24)


def make_gruvbox() -> None:
    img = vertical_gradient("#191b1c", "#282828", "#3c3836", 0.58)
    img = add_nebula(img, seed=301, color="#fe8019", strength=0.08, max_y=640)
    img = add_glow(img, 960, 420, 540, 380, "#fe8019", 0.26)
    img = add_glow(img, 960, 470, 760, 260, "#fabd2f", 0.14)

    # Warm dusk sun partially nestled behind far canyon mesa
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy, rad = 960.0, 430.0, 145.0
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    sun = np.clip((rad - d) / 1.6, 0.0, 1.0)
    t_sun = np.clip((yy - (cy - rad)) / (2.0 * rad), 0.0, 1.0)
    sun_col = hex2rgb("#fabd2f") * (1.0 - t_sun[..., None]) + hex2rgb("#cc241d") * t_sun[..., None]
    img = img * (1.0 - sun[..., None]) + sun_col * sun[..., None]

    x = np.arange(W, dtype=np.float32)
    layers = [
        (fbm_ridge(x, 545, 110, seed=91, octaves=6), "#423c39", "#282828", "#fabd2f", 0.22, "#fe8019", 0.13),
        (fbm_ridge(x, 675, 92,  seed=92, octaves=6), "#34312f", "#1d2021", "#fe8019", 0.24, "#fabd2f", 0.08),
        (fbm_ridge(x, 795, 70,  seed=93, octaves=5), "#282828", "#1d2021", "#d3869b", 0.15, None, 0.0),
        (fbm_ridge(x, 905, 48,  seed=94, octaves=5), "#1d2021", "#141617", "#8ec07c", 0.12, None, 0.0),
    ]
    for ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s in layers:
        img = draw_ridge_layer(img, ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s)
    finish(img, OUT / "gruvbox.png", vignette=0.28)


def make_kanagawa() -> None:
    img = vertical_gradient("#13131a", "#1f1f28", "#2a2a37", 0.60)
    img = add_nebula(img, seed=401, color="#7e9cd8", strength=0.07, max_y=580)
    img = add_glow(img, 1340, 280, 440, 360, "#e6c384", 0.18)
    img = add_glow(img, 740, 620, 660, 290, "#7e9cd8", 0.14)
    img = add_stars(img, seed=33, count=115, color="#dcd7ba", max_y=480)
    img = draw_textured_moon(img, 1340, 280, 78.0, "#f2dca8", "#c8a464", "#e6c384", seed=37)

    # Authentic concave volcanic Mt. Fuji profile + subtle snow cap
    x = np.arange(W, dtype=np.float32)
    dx = np.abs(x - 760.0)
    crater_flat = np.maximum(dx - 38.0, 0.0)
    fuji_y = 675.0 - 305.0 * np.exp(-((crater_flat / 225.0) ** 1.32))
    fuji_y += (np.sin(x * 0.045) * 2.0 + np.cos(x * 0.11) * 1.2) * np.clip(dx / 180.0, 0.0, 1.0)
    img = draw_ridge_layer(img, fuji_y, "#2e3144", "#1f1f28", "#7fb4ca", 0.20, "#7e9cd8", 0.10)

    # Snow cap highlight near summit
    yy, _ = np.mgrid[0:H, 0:W].astype(np.float32)
    snow_line = 455.0 + 18.0 * np.sin(x * 0.06) + 10.0 * np.cos(x * 0.14)
    snow_mask = np.clip((yy - fuji_y[None, :] + 0.5) / 1.5, 0.0, 1.0) * np.clip((snow_line[None, :] - yy) / 8.0, 0.0, 1.0)
    img = img * (1.0 - snow_mask[..., None] * 0.65) + hex2rgb("#dcd7ba") * (snow_mask[..., None] * 0.65)

    # Stylized Ukiyo-e ocean crests with asymmetric breaking swells
    def wave_curve(base_y, amp, phase, freq):
        s = np.sin(x * freq + phase)
        return base_y - amp * (s + 0.35 * np.sin(2.0 * x * freq + phase * 1.3))

    waves = [
        (wave_curve(645, 34, 0.4, 0.0034), "#223249", "#1a2538", "#7fb4ca", 0.36, "#7e9cd8", 0.08),
        (wave_curve(745, 38, 2.2, 0.0030), "#1e2a3d", "#161f2e", "#dcd7ba", 0.26, None, 0.0),
        (wave_curve(845, 30, 3.7, 0.0038), "#192233", "#16161d", "#7e9cd8", 0.28, None, 0.0),
        (wave_curve(935, 22, 1.1, 0.0044), "#16161d", "#101016", "#6a9589", 0.20, None, 0.0),
    ]
    for ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s in waves:
        img = draw_ridge_layer(img, ys, top_c, bot_c, rim_c, rim_a, mist_c, mist_s)
    finish(img, OUT / "kanagawa.png", vignette=0.26)


def make_tokyonight_mesh() -> None:
    img = vertical_gradient("#13141d", "#1a1b26", "#16161e", 0.5)
    img = add_glow(img, 360, 220, 680, 560, "#7aa2f7", 0.34)
    img = add_glow(img, 1480, 360, 620, 540, "#bb9af7", 0.28)
    img = add_glow(img, 1180, 860, 580, 440, "#7dcfff", 0.20)

    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = 960, 540
    for r, col in [(240, (122, 162, 247, 38)), (380, (187, 154, 247, 28)), (540, (125, 207, 255, 22))]:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=2)
    pil = Image.alpha_composite(pil, overlay).convert("RGB")
    finish(np.array(pil, dtype=np.float32), OUT / "tokyonight-mesh.png", vignette=0.30)


def make_abstract_waves() -> None:
    img = vertical_gradient("#11121c", "#161724", "#1a1b26", 0.5)
    img = add_glow(img, 960, 540, 780, 420, "#292e42", 0.45)

    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    c1 = np.array([122, 162, 247], dtype=np.float32)
    c2 = np.array([187, 154, 247], dtype=np.float32)
    c3 = np.array([125, 207, 255], dtype=np.float32)
    n_lines = 34
    xs = list(range(-20, W + 30, 12))
    for k in range(n_lines):
        t = k / (n_lines - 1)
        if t < 0.5:
            col = c1 * (1.0 - 2 * t) + c2 * (2 * t)
        else:
            col = c2 * (2.0 - 2 * t) + c3 * (2 * t - 1.0)
        alpha = int(42 + 95 * np.sin(t * np.pi))
        rgba = (int(col[0]), int(col[1]), int(col[2]), alpha)
        amp = 45 + k * 2.8
        phase = k * 0.14
        y0 = 180 + k * 22
        pts = [(x, y0 + np.sin(x / 240.0 + phase) * amp + np.cos(x / 115.0 - phase * 0.7) * 24) for x in xs]
        draw.line(pts, fill=rgba, width=2)

    glow_layer = overlay.filter(ImageFilter.GaussianBlur(radius=6))
    pil = Image.alpha_composite(pil, glow_layer)
    pil = Image.alpha_composite(pil, overlay).convert("RGB")
    finish(np.array(pil, dtype=np.float32), OUT / "abstract-waves.png", vignette=0.30)


def make_abstract_grid() -> None:
    img = vertical_gradient("#10111a", "#171826", "#1a1b26", 0.42)
    horizon = 440
    img = add_glow(img, 960, horizon, 640, 210, "#7aa2f7", 0.30)
    img = add_glow(img, 960, horizon, 340, 140, "#bb9af7", 0.24)
    img = add_stars(img, seed=77, count=110, color="#c0caf5", max_y=horizon - 20)

    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    vx, vy = 960, horizon
    for i in range(-18, 19):
        bx = 960 + i * 135
        draw.line([(vx, vy), (bx, H)], fill=(122, 162, 247, 115), width=2)
    y = float(horizon)
    step = 6.0
    while y < H:
        step *= 1.24
        y += step
        if y < H:
            alpha = int(60 + 130 * ((y - horizon) / (H - horizon)))
            draw.line([(0, y), (W, y)], fill=(125, 207, 255, alpha), width=2)
    draw.line([(0, horizon), (W, horizon)], fill=(187, 154, 247, 180), width=3)

    glow = overlay.filter(ImageFilter.GaussianBlur(radius=5))
    pil = Image.alpha_composite(pil, glow)
    pil = Image.alpha_composite(pil, overlay).convert("RGB")
    finish(np.array(pil, dtype=np.float32), OUT / "abstract-grid.png", vignette=0.25)


def main() -> None:
    print("generating wallpapers:")
    make_tokyonight()
    make_catppuccin()
    make_gruvbox()
    make_kanagawa()
    make_tokyonight_mesh()
    make_abstract_waves()
    make_abstract_grid()


if __name__ == "__main__":
    main()
