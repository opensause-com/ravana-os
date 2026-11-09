#!/usr/bin/env python3
"""Ravana light wallpaper: porcelain and rose silk.

Three flowing silk layers sweep across a warm porcelain background; each layer has
soft shading across its body, a bright sheen along its edge and a faint shadow below,
with a thin Ravana-red glint on the front layer and a faint crown watermark.
Rendered at 1280x720 in pure Python, then upscaled to 3840x2160.
Output: system_files/usr/share/wallpapers/Ravana/contents/images_light/3840x2160.png
"""
import math
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent / "system_files"
OUT = ROOT / "usr/share/wallpapers/Ravana/contents/images_light/3840x2160.png"
W, H = 1280, 720

def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

def smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)

BG_A, BG_B = (248, 245, 243), (238, 229, 231)            # porcelain -> warm blush
# (base height, amplitude, frequency, phase, tilt, body colour, depth colour)
LAYERS = [
    (0.42, 0.10, 1.15, 0.6, -0.20, (236, 222, 226), (214, 196, 204)),   # back: pale rose
    (0.58, 0.12, 0.95, 2.1, -0.28, (226, 214, 224), (198, 186, 204)),   # middle: lilac grey
    (0.74, 0.11, 1.30, 4.0, -0.34, (240, 206, 212), (214, 150, 164)),   # front: rose silk
]
RED = (210, 31, 60)

def edge(x, layer):
    base, amp, freq, phase, tilt, _, _ = layer
    u = x / W
    return H * (base + tilt * (u - 0.5) + amp * math.sin(freq * math.pi * u * 2 + phase)
                + 0.03 * math.sin(5.3 * u + phase * 1.7))

img = Image.new("RGB", (W, H))
px = img.load()
edges = [[edge(x, L) for x in range(W)] for L in LAYERS]
for y in range(H):
    for x in range(W):
        t = (x / W) * 0.45 + (y / H) * 0.55
        c = mix(BG_A, BG_B, t)
        for li, L in enumerate(LAYERS):
            e = edges[li][x]
            d = y - e                          # >0: inside the layer (below its edge)
            if d < -40:
                continue
            # soft shadow just above the edge of the next layer down
            if d < 0:
                sh = (1 - smooth(-40, 0, d)) * 0.0 + smooth(-40, 0, d) * 0.10
                c = mix(c, (150, 120, 130), sh * 0.6)
                continue
            body = mix(L[5], L[6], smooth(0, H * 0.45, d))
            alpha = smooth(0, 2.2, d)          # anti-aliased edge
            c = mix(c, body, alpha)
            sheen = math.exp(-d / 5.0) * 0.85  # bright sheen along the edge
            c = mix(c, (255, 255, 255), sheen)
            if li == len(LAYERS) - 1:          # thin Ravana-red glint on the front layer
                glint = math.exp(-((d - 7) ** 2) / 6.0) * 0.22 * (0.5 + 0.5 * math.sin(x / W * math.pi))
                c = mix(c, RED, glint)
        px[x, y] = tuple(int(max(0, min(255, v))) for v in c)

img = img.filter(ImageFilter.GaussianBlur(0.6)).resize((3840, 2160), Image.LANCZOS)

# faint crown watermark, bottom-right (from the brand mark used on the dark wallpaper)
crown = ROOT / "usr/share/icons/hicolor/512x512/apps/ravana-logo.png"
if crown.exists():
    mark = Image.open(crown).convert("RGBA").resize((300, 300), Image.LANCZOS)
    a = mark.getchannel("A").point(lambda v: int(v * 0.10))
    img.paste(Image.new("RGB", mark.size, RED), (3840 - 300 - 140, 2160 - 300 - 130), a)

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT, optimize=True)
img.resize((400, 225), Image.LANCZOS).save(OUT.parent.parent / "screenshot_light.png")
print("wrote", OUT.relative_to(ROOT.parent), f"{OUT.stat().st_size // 1024} KB")
