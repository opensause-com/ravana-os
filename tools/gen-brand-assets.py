#!/usr/bin/env python3
"""Generate Ravana OS brand assets (logo, wallpapers, boot splash) into system_files/.

    python3 tools/gen-brand-assets.py

Needs Pillow. Palette matches tools/gen-kde-colors.py.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent / "system_files"
RED, RED_DEEP, WHITE = (210, 31, 60), (165, 14, 37), (255, 255, 255)
NIGHT, PAPER = (12, 12, 14), (246, 246, 247)

SOURCE = Path(__file__).resolve().parent.parent / "assets/logo-source.jpg"
SOURCE_BG = (21, 21, 23)  # flat background colour of the source artwork


def _extract_crown() -> Image.Image:
    """Cut the crown out of the source artwork: background -> transparent.

    Only pixels brighter than the background become opaque (the dark outlines
    between shards stay see-through), with a soft ramp for anti-aliased edges.
    Colours are un-premultiplied so edges stay clean on any background.
    """
    src = Image.open(SOURCE).convert("RGB")
    out = Image.new("RGBA", src.size)
    sp, op = src.load(), out.load()
    bgm = max(SOURCE_BG)
    for y in range(src.height):
        for x in range(src.width):
            c = sp[x, y]
            a = min(1.0, max(0.0, (max(c) - bgm - 6) / 50))
            if a <= 0:
                op[x, y] = (0, 0, 0, 0)
                continue
            rgb = tuple(min(255, max(0, round((ci - b * (1 - a)) / a))) for ci, b in zip(c, SOURCE_BG))
            op[x, y] = rgb + (round(a * 255),)
    box = out.getbbox()
    crown = out.crop(box)
    side = max(crown.size)
    pad = round(side * 0.06)
    sq = Image.new("RGBA", (side + 2 * pad, side + 2 * pad), (0, 0, 0, 0))
    sq.paste(crown, ((sq.width - crown.width) // 2, (sq.height - crown.height) // 2), crown)
    return sq


_CROWN = None


def crown(size: int) -> Image.Image:
    """Transparent square crown mark."""
    global _CROWN
    if _CROWN is None:
        _CROWN = _extract_crown()
    return _CROWN.resize((size, size), Image.LANCZOS)


def tile(size: int) -> Image.Image:
    """App-icon style: crown on a near-black rounded tile (like the artwork)."""
    s = 4
    big = Image.new("RGBA", (size * s, size * s), (0, 0, 0, 0))
    ImageDraw.Draw(big).rounded_rectangle((0, 0, size * s - 1, size * s - 1),
                                          radius=round(size * s * 0.22), fill=(18, 18, 20, 255))
    c = crown(round(size * s * 0.92))
    big.paste(c, ((big.width - c.width) // 2, (big.height - c.height) // 2), c)
    return big.resize((size, size), Image.LANCZOS)


def silhouette(size: int, colour) -> Image.Image:
    c = crown(size)
    mono = Image.new("RGBA", c.size, colour + (255,))
    mono.putalpha(c.getchannel("A"))
    return mono


def wallpaper(w: int, h: int, dark: bool) -> Image.Image:
    base = NIGHT if dark else PAPER
    small = Image.new("RGB", (w // 10, h // 10), base)
    glow = Image.new("L", small.size, 0)
    g = ImageDraw.Draw(glow)
    sw, sh = small.size
    # one wide glow rising from the bottom, one softer from the top-right
    g.ellipse((int(sw * 0.10), int(sh * 0.55), int(sw * 0.90), int(sh * 1.45)), fill=255)
    g.ellipse((int(sw * 0.62), int(-sh * 0.45), int(sw * 1.25), int(sh * 0.35)), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=sw // 9))
    tint = Image.new("RGB", small.size, RED_DEEP if dark else (240, 170, 182))
    img = Image.composite(tint, small, glow.point(lambda v: int(v * (0.55 if dark else 0.5))))
    img = img.resize((w, h), Image.BICUBIC)
    # crown watermark, bottom-right, very subtle
    mark = silhouette(int(h * 0.12), WHITE if dark else RED)
    alpha = mark.getchannel("A").point(lambda v: int(v * (0.10 if dark else 0.08)))
    col = Image.new("RGB", mark.size, WHITE if dark else RED)
    img.paste(col, (w - mark.width - int(h * 0.06), h - mark.height - int(h * 0.06)), alpha)
    return img


def write(rel: str, data) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, str):
        p.write_text(data)
    elif isinstance(data, Image.Image):
        data.save(p, optimize=True)
    print("wrote", p.relative_to(ROOT.parent))


if __name__ == "__main__":
    for old in ("usr/share/icons/hicolor/scalable/apps/ravana-logo.svg",
                "usr/share/icons/hicolor/scalable/apps/ravana-logo-symbolic.svg"):
        (ROOT / old).unlink(missing_ok=True)
    for px in (16, 22, 24, 32, 48, 64, 128, 256, 512):
        write(f"usr/share/icons/hicolor/{px}x{px}/apps/ravana-logo.png", crown(px))
        write(f"usr/share/icons/hicolor/{px}x{px}/apps/ravana-os.png", tile(px))
    write("usr/share/pixmaps/ravana-logo.png", crown(256))
    write("usr/share/pixmaps/ravana-os.png", tile(256))
    write("usr/share/ravana/plymouth-watermark.png", crown(220))
    for name, dark in (("Ravana", True),):
        base = f"usr/share/wallpapers/{name}"
        write(f"{base}/contents/images/3840x2160.png", wallpaper(3840, 2160, dark))
        write(f"{base}/contents/screenshot.png", wallpaper(3840, 2160, dark).resize((400, 225), Image.LANCZOS))
        write(f"{base}/metadata.json", (
            '{\n  "KPlugin": {\n    "Authors": [{"Name": "Ravana OS"}],\n'
            f'    "Id": "{name}",\n    "License": "CC-BY-SA-4.0",\n'
            f'    "Name": "{"Ravana" if dark else "Ravana Light"}"\n  }}\n}}\n'))
