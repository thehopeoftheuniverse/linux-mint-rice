#!/usr/bin/env python3
"""Render @TOKEN@ templates with a palette file.

usage: render.py <theme-file> <templates-dir> <out-dir>
Every regular file under templates/ is rendered, preserving sub-directories,
plus a copy of the palette itself at <out>/palette.env.
"""
import re, shutil, sys
from pathlib import Path

TOKEN = re.compile(r"@([A-Z0-9_]+)@")

# Nerd Font glyphs are emitted from codepoints: the literal characters do not
# survive every editor/tool round-trip, codepoints always do.
GLYPHS = {
    "GLYPH_CPU":     chr(0xF2DB),  # microchip
    "GLYPH_MEM":     chr(0xF1C0),  # database
    "GLYPH_DISK":    chr(0xF0A0),  # hard drive
    "GLYPH_VOL_UP":  chr(0xF028),
    "GLYPH_VOL_DOWN": chr(0xF027),
    "GLYPH_VOL_MUTE": chr(0xF026),
    "GLYPH_NET":     chr(0xF0AC),  # globe
    "GLYPH_WIFI":    chr(0xF1EB),
    "GLYPH_DATE":    chr(0xF073),  # calendar
    "GLYPH_POWER":   chr(0xF011),
    "GLYPH_LOCK":    chr(0xF023),
    "GLYPH_LOGOUT":  chr(0xF2F5),
    "GLYPH_MOON":    chr(0xF186),
    "GLYPH_SYNC":    chr(0xF021),
    "GLYPH_TERM":    chr(0xF120),
    "GLYPH_FOLDER":  chr(0xF07B),
    "GLYPH_GIT":     chr(0xF0AA2),
    "GLYPH_PICTURE": chr(0xF03E),
    "GLYPH_MUSIC":   chr(0xF001),
    "GLYPH_PLAY":    chr(0xF04B),
    "GLYPH_PAUSE":   chr(0xF04C),
    "GLYPH_NEXT":    chr(0xF051),
    "GLYPH_SEARCH":  chr(0xF002),
    "GLYPH_BELL":    chr(0xF0F3),
    "GLYPH_WEB":     chr(0xF0AC),  # globe
    "GLYPH_CODE":    chr(0xF121),
    "GLYPH_MAIL":    chr(0xF0E0),
    "GLYPH_BOOK":    chr(0xF02D),
    "GLYPH_COGS":    chr(0xF085),
    "GLYPH_BARS":    chr(0xF0C9),
    "GLYPH_CLIP":    chr(0xF0EA),
    "GLYPH_DOWNLOAD": chr(0xF0ED),
    "GLYPH_UPDATE":  chr(0xF0AA),  # arrow-circle-up
}

def main() -> int:
    theme_file, tpl_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    palette = {}
    for line in theme_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        palette[k.strip()] = v.strip().strip('"')
    palette.update(GLYPHS)
    palette.setdefault("ACCENT", palette.get("BLUE", "#7aa2f7"))
    palette.setdefault("ACCENT_ALT", palette.get("PURPLE", palette["ACCENT"]))

    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    unknown = set()
    def sub(m):
        key = m.group(1)
        if key not in palette:
            unknown.add(key)
            return m.group(0)
        return palette[key]

    for src in sorted(tpl_dir.rglob("*")):
        if src.is_dir():
            continue
        rel = src.relative_to(tpl_dir)
        dst = out_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            text = src.read_text()
        except UnicodeDecodeError:
            shutil.copy2(src, dst)
            continue
        dst.write_text(TOKEN.sub(sub, text))
        shutil.copymode(src, dst)

    def shq(val: str) -> str:
        if val.startswith("#") and len(val) in (4, 7, 9):
            return val  # hex colours are safe unquoted
        return "'" + val.replace("'", "'\\''") + "'"

    (out_dir / "palette.env").write_text(
        "\n".join(f"{k}={shq(v)}" for k, v in palette.items() if k not in GLYPHS) + "\n"
    )
    if unknown:
        print(f"render: WARNING unknown tokens: {', '.join(sorted(unknown))}", file=sys.stderr)
    print(f"render: {theme_file.name} -> {out_dir} ({len(palette)} tokens)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
