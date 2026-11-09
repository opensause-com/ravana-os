#!/usr/bin/env python3
# Copyright (c) 2026 Ravana OS. All rights reserved.
"""White Ravana crown for dark surfaces: the red shapes become white, the dark-red
facets a softer white, and the logo's inner white becomes see-through so the crown's
cut-outs read on any background. Writes ravana-logo-white in every hicolor size."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "system_files"
src = Image.open(ROOT / "usr/share/icons/hicolor/512x512/apps/ravana-logo.png").convert("RGBA")

out = Image.new("RGBA", src.size)
sp, op = src.load(), out.load()
for y in range(src.height):
    for x in range(src.width):
        r, g, b, a = sp[x, y]
        if a == 0:
            continue
        whiteness = min(r, g, b) / 255            # 1 = the logo's white fill
        redness = max(0.0, (r - max(g, b)) / 255)  # red and dark-red facets
        dark = 1 - r / 255                         # dark-red facets are deeper
        solid = max(0.0, min(1.0, (0.78 - whiteness) / 0.28))   # crisp edge between fill and facets
        alpha = a * solid * (0.62 if dark > 0.35 and redness > 0.2 else 1.0)
        op[x, y] = (255, 255, 255, int(alpha))

for s in (16, 22, 24, 32, 48, 64, 128, 256, 512):
    d = ROOT / f"usr/share/icons/hicolor/{s}x{s}/apps"
    d.mkdir(parents=True, exist_ok=True)
    out.resize((s, s), Image.LANCZOS).save(d / "ravana-logo-white.png", optimize=True)

print("wrote ravana-logo-white")
