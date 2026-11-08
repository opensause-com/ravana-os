#!/usr/bin/env python3
"""Generate Ravana OS boot (Plymouth) and login splash (KSplash) assets.

    python3 tools/gen-boot-assets.py

Uses the crown from tools/gen-brand-assets.py. Needs Pillow and a wordmark
font (Ubuntu Sans by default; rendered to PNG, the font is not shipped).
"""
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from importlib import import_module
brand = import_module("gen-brand-assets")

ROOT = Path(__file__).resolve().parent.parent / "system_files"
PLY = ROOT / "usr/share/plymouth/themes/ravana"
LNF = ROOT / "usr/share/plasma/look-and-feel/org.ravana.desktop/contents/splash"
RED = (210, 31, 60)
FONT = "/usr/share/fonts/truetype/ubuntu/UbuntuSans[wdth,wght].ttf"
FRAMES = 72


def wordmark(height: int, colour=(255, 255, 255), alpha=235) -> Image.Image:
    """Letter-spaced RAVANA wordmark."""
    font = ImageFont.truetype(FONT, height * 4)
    try:
        font.set_variation_by_axes([100, 300])  # width, weight (light)
    except Exception:
        pass
    letters = "RAVANA"
    gap = height * 4 * 0.55
    widths = [font.getbbox(c)[2] - font.getbbox(c)[0] for c in letters]
    total = int(sum(widths) + gap * (len(letters) - 1)) + 8
    img = Image.new("RGBA", (total, height * 5), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = 4
    for c, w in zip(letters, widths):
        d.text((x - font.getbbox(c)[0], height * 0.4), c, font=font, fill=colour + (alpha,))
        x += w + gap
    img = img.crop(img.getbbox())
    return img.resize((round(img.width / 4), round(img.height / 4)), Image.LANCZOS)


def glow(size: int) -> Image.Image:
    """Soft crimson glow shaped like the crown."""
    a = brand.crown(size).getchannel("A")
    pad = size // 2
    canvas = Image.new("L", (size + 2 * pad, size + 2 * pad), 0)
    canvas.paste(a, (pad, pad))
    canvas = canvas.filter(ImageFilter.GaussianBlur(size / 9)).filter(ImageFilter.GaussianBlur(size / 14))
    g = Image.new("RGBA", canvas.size, RED + (255,))
    g.putalpha(canvas.point(lambda v: min(255, int(v * 1.6))))
    return g


def throbber_frame(i: int, canvas=440, crown_px=230) -> Image.Image:
    t = i / FRAMES
    frame = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    # breathing glow
    breathe = 0.5 - 0.5 * math.cos(2 * math.pi * t)
    g = glow(crown_px)
    gs = round(g.width * (0.97 + 0.06 * breathe))
    g = g.resize((gs, gs), Image.LANCZOS)
    g.putalpha(g.getchannel("A").point(lambda v: int(v * (0.30 + 0.45 * breathe))))
    frame.alpha_composite(g, ((canvas - gs) // 2, (canvas - gs) // 2))
    # crown
    c = brand.crown(crown_px)
    pos = ((canvas - crown_px) // 2, (canvas - crown_px) // 2)
    frame.alpha_composite(c, pos)
    # light sweep across the crown during the first 40% of the loop
    if t < 0.40:
        p = t / 0.40
        band = Image.new("L", (crown_px, crown_px), 0)
        bd = ImageDraw.Draw(band)
        cx = -0.35 * crown_px + p * 1.7 * crown_px
        w = crown_px * 0.16
        bd.polygon([(cx, 0), (cx + w, 0), (cx + w - crown_px * 0.35, crown_px), (cx - crown_px * 0.35, crown_px)], fill=150)
        band = band.filter(ImageFilter.GaussianBlur(crown_px / 30))
        shine_alpha = Image.composite(band, Image.new("L", band.size, 0), c.getchannel("A"))
        shine = Image.new("RGBA", band.size, (255, 255, 255, 0))
        shine.putalpha(shine_alpha)
        frame.alpha_composite(shine, pos)
    return frame


def write(p: Path, img: Image.Image, palette=False) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    if palette:
        # Boot background is solid #0C0C0E, so bake it in and drop alpha; then a
        # dithered 256-colour palette stays smooth and is ~4x smaller.
        bg = Image.new("RGBA", img.size, (12, 12, 14, 255))
        bg.alpha_composite(img)
        img = bg.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT,
                                         dither=Image.Dither.FLOYDSTEINBERG)
    img.save(p, optimize=True)


if __name__ == "__main__":
    for old in PLY.glob("throbber-*.png"):
        old.unlink()
    for i in range(FRAMES):
        write(PLY / f"throbber-{i + 1:04d}.png", throbber_frame(i), palette=True)
    write(PLY / "watermark.png", wordmark(22, alpha=200))
    (PLY / "ravana.plymouth").write_text("""[Plymouth Theme]
Name=Ravana
Description=Ravana OS boot animation: crown with breathing glow and light sweep
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/ravana
HorizontalAlignment=.5
VerticalAlignment=.45
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.88
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x0c0c0e
BackgroundEndColor=0x0c0c0e
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false
UseFirmwareBackground=false

[shutdown]
UseEndAnimation=false
UseFirmwareBackground=false

[reboot]
UseEndAnimation=false
UseFirmwareBackground=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing updates...
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading Ravana OS...
SubTitle=Do not turn off your computer

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading firmware...
SubTitle=Do not turn off your computer
""")
    # KSplash (login -> desktop) images, 2x for HiDPI
    write(LNF / "images/crown.png", brand.crown(400))
    write(LNF / "images/glow.png", glow(400))
    write(LNF / "images/wordmark.png", wordmark(40))
    print("frames:", FRAMES, "->", PLY)
