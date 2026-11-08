#!/usr/bin/env python3
"""Generate Ravana OS installer (Anaconda) artwork into live/branding/pixmaps.

    python3 tools/gen-installer-assets.py
"""
import sys
from importlib import import_module
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
brand = import_module("gen-brand-assets")
boot = import_module("gen-boot-assets")
OUT = Path(__file__).resolve().parent.parent / "live/branding/pixmaps"
NIGHT, RED, RED_DEEP = (18, 18, 20), (210, 31, 60), (110, 10, 26)


def vgradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    # Sidebar: night -> deep crimson, crown + wordmark near the top
    side = vgradient(300, 1200, NIGHT, RED_DEEP).convert("RGBA")
    side.save(OUT / "sidebar-bg.png")
    logo = Image.new("RGBA", (300, 260), (0, 0, 0, 0))
    c = brand.crown(200)
    logo.alpha_composite(c, ((300 - 200) // 2, 0))
    w = boot.wordmark(20)
    logo.alpha_composite(w, ((300 - w.width) // 2, 205))
    logo.save(OUT / "sidebar-logo.png")
    # Top bar: night with a thin crimson line at the bottom
    top = Image.new("RGB", (64, 64), NIGHT)
    ImageDraw.Draw(top).rectangle((0, 61, 63, 63), fill=RED)
    top.save(OUT / "topbar-bg.png")
    (OUT / "ravana.css").write_text("""/* Ravana OS installer theme (GTK Anaconda) */
.logo-sidebar {
    background-image: url('/usr/share/anaconda/pixmaps/sidebar-bg.png');
    background-color: #121214;
    background-size: cover;
}
.logo {
    background-image: url('/usr/share/anaconda/pixmaps/sidebar-logo.png');
    background-position: 50% 24px;
    background-repeat: no-repeat;
    background-color: transparent;
}
AnacondaSpokeWindow #nav-box {
    background-color: #121214;
    background-image: url('/usr/share/anaconda/pixmaps/topbar-bg.png');
    background-repeat: repeat;
    color: #F5F5F7;
}
""")
    for f in sorted(OUT.iterdir()):
        print("wrote", f.relative_to(OUT.parent.parent.parent))
