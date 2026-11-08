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

# Crown mark on a 512 grid: five points (Ravana, the king) over a solid band.
CROWN = [(104, 352), (104, 196), (180, 268), (256, 132), (332, 268), (408, 196), (408, 352)]
BAND = (104, 372, 408, 412)
TILE_R = 112  # tile corner radius on the 512 grid


def logo_svg() -> str:
    pts = " ".join(f"{x},{y}" for x, y in CROWN)
    x0, y0, x1, y1 = BAND
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <title>Ravana OS</title>
  <rect width="512" height="512" rx="{TILE_R}" fill="#D21F3C"/>
  <polygon points="{pts}" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="16" stroke-linejoin="round"/>
  <rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="12" fill="#FFFFFF"/>
</svg>
"""


def symbolic_svg() -> str:
    """Single-color crown for panels/menus (KDE recolors -symbolic icons)."""
    pts = " ".join(f"{x * 16 / 512:.2f},{y * 16 / 512:.2f}" for x, y in CROWN)
    x0, y0, x1, y1 = (v * 16 / 512 for v in BAND)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <polygon points="{pts}" fill="#232629" stroke="#232629" stroke-width="0.6" stroke-linejoin="round" class="ColorScheme-Text"/>
  <rect x="{x0:.2f}" y="{y0:.2f}" width="{x1 - x0:.2f}" height="{y1 - y0:.2f}" rx="0.4" fill="#232629" class="ColorScheme-Text"/>
</svg>
"""


def logo_png(size: int, tile=True) -> Image.Image:
    s = 4  # supersample for smooth edges
    big = Image.new("RGBA", (512 * s, 512 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    if tile:
        d.rounded_rectangle((0, 0, 512 * s - 1, 512 * s - 1), radius=TILE_R * s, fill=RED + (255,))
    fg = WHITE if tile else RED
    d.polygon([(x * s, y * s) for x, y in CROWN], fill=fg + (255,))
    d.line([(x * s, y * s) for x, y in CROWN] + [(CROWN[0][0] * s, CROWN[0][1] * s)],
           fill=fg + (255,), width=16 * s, joint="curve")
    d.rounded_rectangle([v * s for v in BAND], radius=12 * s, fill=fg + (255,))
    return big.resize((size, size), Image.LANCZOS)


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
    mark = logo_png(int(h * 0.09), tile=False)
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
    write("usr/share/icons/hicolor/scalable/apps/ravana-logo.svg", logo_svg())
    write("usr/share/icons/hicolor/scalable/apps/ravana-logo-symbolic.svg", symbolic_svg())
    for px in (48, 128, 256):
        write(f"usr/share/icons/hicolor/{px}x{px}/apps/ravana-logo.png", logo_png(px))
    write("usr/share/pixmaps/ravana-logo.png", logo_png(256))
    write("usr/share/ravana/plymouth-watermark.png", logo_png(160))
    for name, dark in (("Ravana", True), ("RavanaLight", False)):
        base = f"usr/share/wallpapers/{name}"
        write(f"{base}/contents/images/3840x2160.png", wallpaper(3840, 2160, dark))
        write(f"{base}/contents/screenshot.png", wallpaper(3840, 2160, dark).resize((400, 225), Image.LANCZOS))
        write(f"{base}/metadata.json", (
            '{\n  "KPlugin": {\n    "Authors": [{"Name": "Ravana OS"}],\n'
            f'    "Id": "{name}",\n    "License": "CC-BY-SA-4.0",\n'
            f'    "Name": "{"Ravana" if dark else "Ravana Light"}"\n  }}\n}}\n'))
