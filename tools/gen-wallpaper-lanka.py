#!/usr/bin/env python3
# Copyright (c) 2026 Ravana OS. All rights reserved.
"""Ravana · Lanka wallpaper (dark default): the Lanka artwork upscaled to 4K with the
Ravana crown as a faint white watermark, bottom-right, like the other Ravana wallpapers."""
from pathlib import Path
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent / "system_files"
OUT = ROOT / "usr/share/wallpapers/RavanaLanka/contents/images/3840x2160.png"

im = Image.open(HERE / "assets/lanka-source.webp").convert("RGB")
w, h = im.size
th = round(w * 9 / 16)
im = im.crop((0, (h - th) // 2, w, (h - th) // 2 + th))
wp = im.resize((3840, 2160), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=3)).convert("RGBA")

# faint crown watermark, bottom-right: same size and place as the other Ravana wallpapers
logo = Image.open(ROOT / "usr/share/icons/hicolor/512x512/apps/ravana-logo-white.png").convert("RGBA")
SIZE = 300
mark = logo.resize((SIZE, SIZE), Image.LANCZOS)
mark.putalpha(mark.getchannel("A").point(lambda v: int(v * 0.16)))
wp.alpha_composite(mark, (3840 - SIZE - 140, 2160 - SIZE - 130))

wp = wp.convert("RGB")
wp.save(OUT, optimize=True)
wp.resize((400, 225), Image.LANCZOS).save(OUT.parent.parent / "screenshot.png")
print("wrote", OUT.relative_to(HERE.parent), f"{OUT.stat().st_size // 1024} KB")
