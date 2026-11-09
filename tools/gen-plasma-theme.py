#!/usr/bin/env python3
"""Generate the Ravana Glass Plasma style (menu bar, dock, popups, tooltips).

Frosted glass: a dark translucent tint over KWin's blur, a fine light rim,
a hairline dark outline, large rounded corners and soft shadows.
Output: system_files/usr/share/plasma/desktoptheme/ravana-glass/
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "system_files/usr/share/plasma/desktoptheme/ravana-glass"

TINT = (22, 22, 26)          # popup glass tint (near-black, a touch of warmth)
BAR_TINT = (62, 60, 66)      # menu bar / dock glass: lighter see-through grey, like the macOS dock
RIM = 0.13                   # light rim opacity
OUTLINE = 0.45               # dark outline opacity


def rgba(rgb, a):
    return f"rgb({rgb[0]},{rgb[1]},{rgb[2]})", f"{a:.3f}"


def frame(prefix: str, R: int, alpha: float, ox: int = 0, oy: int = 0, tint=None) -> str:
    """Nine-slice rounded glass frame. Corners R x R, edges 1 px thick strips scaled by Plasma."""
    fill, fa = rgba(tint or TINT, alpha)
    pre = f"{prefix}-" if prefix else ""
    E = 4  # edge strip length (stretched)
    g = []

    def el(name, x, y, body):
        g.append(f'<g id="{pre}{name}" transform="translate({ox + x},{oy + y})">{body}</g>')

    rim = f'stroke="#ffffff" stroke-opacity="{RIM}" stroke-width="1" fill="none"'
    out = f'stroke="#000000" stroke-opacity="{OUTLINE}" stroke-width="1" fill="none"'
    a = R  # corner box size
    # corners: fill quarter disc + outline arc (r - 0.5) + rim arc (r - 1.5)
    q = {
        "topleft":     (f"M0,{a} A{a},{a} 0 0 1 {a},0 L{a},{a} Z",
                        f"M0.5,{a} A{a - .5},{a - .5} 0 0 1 {a},0.5",
                        f"M1.5,{a} A{a - 1.5},{a - 1.5} 0 0 1 {a},1.5"),
        "topright":    (f"M0,0 A{a},{a} 0 0 1 {a},{a} L0,{a} Z",
                        f"M0,0.5 A{a - .5},{a - .5} 0 0 1 {a - .5},{a}",
                        f"M0,1.5 A{a - 1.5},{a - 1.5} 0 0 1 {a - 1.5},{a}"),
        "bottomleft":  (f"M0,0 L{a},0 L{a},{a} A{a},{a} 0 0 1 0,0 Z",
                        f"M0.5,0 A{a - .5},{a - .5} 0 0 0 {a},{a - .5}",
                        f"M1.5,0 A{a - 1.5},{a - 1.5} 0 0 0 {a},{a - 1.5}"),
        "bottomright": (f"M0,0 L{a},0 A{a},{a} 0 0 1 0,{a} Z",
                        f"M{a - .5},0 A{a - .5},{a - .5} 0 0 1 0,{a - .5}",
                        f"M{a - 1.5},0 A{a - 1.5},{a - 1.5} 0 0 1 0,{a - 1.5}"),
    }
    pos = {"topleft": (0, 0), "topright": (a + E, 0), "bottomleft": (0, a + E), "bottomright": (a + E, a + E)}
    for name, (shape, o, r) in q.items():
        x, y = pos[name]
        el(name, x, y, f'<rect width="{a}" height="{a}" fill="none"/>'
                       f'<path d="{shape}" fill="{fill}" fill-opacity="{fa}"/>'
                       f'<path d="{o}" {out}/><path d="{r}" {rim}/>')
    # edges
    el("top", a, 0, f'<rect width="{E}" height="{a}" fill="{fill}" fill-opacity="{fa}"/>'
                    f'<rect width="{E}" height="1" fill="#000" fill-opacity="{OUTLINE}"/>'
                    f'<rect y="1" width="{E}" height="1" fill="#fff" fill-opacity="{RIM}"/>')
    el("bottom", a, a + E, f'<rect width="{E}" height="{a}" fill="{fill}" fill-opacity="{fa}"/>'
                           f'<rect y="{a - 1}" width="{E}" height="1" fill="#000" fill-opacity="{OUTLINE}"/>'
                           f'<rect y="{a - 2}" width="{E}" height="1" fill="#fff" fill-opacity="{RIM}"/>')
    el("left", 0, a, f'<rect width="{a}" height="{E}" fill="{fill}" fill-opacity="{fa}"/>'
                     f'<rect width="1" height="{E}" fill="#000" fill-opacity="{OUTLINE}"/>'
                     f'<rect x="1" width="1" height="{E}" fill="#fff" fill-opacity="{RIM}"/>')
    el("right", a + E, a, f'<rect width="{a}" height="{E}" fill="{fill}" fill-opacity="{fa}"/>'
                          f'<rect x="{a - 1}" width="1" height="{E}" fill="#000" fill-opacity="{OUTLINE}"/>'
                          f'<rect x="{a - 2}" width="1" height="{E}" fill="#fff" fill-opacity="{RIM}"/>')
    el("center", a, a, f'<rect width="{E}" height="{E}" fill="{fill}" fill-opacity="{fa}"/>')
    return "\n".join(g)


def soft(prefix: str, R: int, color: str, alpha: float, ox: int, oy: int, rim: float = 0.0) -> str:
    """Rounded translucent fill (dock highlights): nine-slice, no outline."""
    a, E = R, 4
    f = f'fill="{color}" fill-opacity="{alpha:.3f}"'
    g = []
    corners = {
        "topleft": (0, 0, f"M0,{a} A{a},{a} 0 0 1 {a},0 L{a},{a} Z"),
        "topright": (a + E, 0, f"M0,0 A{a},{a} 0 0 1 {a},{a} L0,{a} Z"),
        "bottomleft": (0, a + E, f"M0,0 L{a},0 L{a},{a} A{a},{a} 0 0 1 0,0 Z"),
        "bottomright": (a + E, a + E, f"M0,0 L{a},0 A{a},{a} 0 0 1 0,{a} Z"),
    }
    for n, (x, y, d) in corners.items():
        g.append(f'<g id="{prefix}-{n}" transform="translate({ox + x},{oy + y})"><rect width="{a}" height="{a}" fill="none"/><path d="{d}" {f}/></g>')
    for n, x, y, w, h in (("top", a, 0, E, a), ("bottom", a, a + E, E, a), ("left", 0, a, a, E),
                          ("right", a + E, a, a, E), ("center", a, a, E, E)):
        g.append(f'<rect id="{prefix}-{n}" x="{ox + x}" y="{oy + y}" width="{w}" height="{h}" {f}/>')
    if rim:
        g.append(f'<rect id="{prefix}-hint-top-margin" x="{ox + 60}" y="{oy}" width="4" height="4" fill="none"/>')
    return "\n".join(g)


def mask(R: int, ox: int, oy: int) -> str:
    """Blur/contrast region: same rounded shape, opaque."""
    a, E = R, 4
    g = []
    shapes = {
        "topleft": (0, 0, f"M0,{a} A{a},{a} 0 0 1 {a},0 L{a},{a} Z"),
        "topright": (a + E, 0, f"M0,0 A{a},{a} 0 0 1 {a},{a} L0,{a} Z"),
        "bottomleft": (0, a + E, f"M0,0 L{a},0 L{a},{a} A{a},{a} 0 0 1 0,0 Z"),
        "bottomright": (a + E, a + E, f"M0,0 L{a},0 A{a},{a} 0 0 1 0,{a} Z"),
    }
    for n, (x, y, d) in shapes.items():
        g.append(f'<g id="mask-{n}" transform="translate({ox + x},{oy + y})"><rect width="{a}" height="{a}" fill="none"/><path d="{d}" fill="#000"/></g>')
    for n, x, y, w, h in (("top", a, 0, E, a), ("bottom", a, a + E, E, a), ("left", 0, a, a, E),
                          ("right", a + E, a, a, E), ("center", a, a, E, E)):
        g.append(f'<rect id="mask-{n}" x="{ox + x}" y="{oy + y}" width="{w}" height="{h}" fill="#000"/>')
    return "\n".join(g)


def shadow(S: int, ox: int, oy: int, strength: float) -> str:
    """Soft drop shadow around the frame (used for floating panels and popups)."""
    g = [f'''<defs>
  <radialGradient id="sh-c" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000" stop-opacity="{strength}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
  <linearGradient id="sh-v" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="{strength}"/></linearGradient>
  <linearGradient id="sh-vb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="{strength}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
  <linearGradient id="sh-h" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="{strength}"/></linearGradient>
  <linearGradient id="sh-hr" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="{strength}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
</defs>''']
    E = 4
    # corners are quarter radial gradients: draw a full disc clipped by the element box
    def corner(name, x, y, cx, cy):
        g.append(f'<g id="shadow-{name}" transform="translate({ox + x},{oy + y})"><rect width="{S}" height="{S}" fill="none"/>'
                 f'<rect width="{S}" height="{S}" fill="url(#sh-{name})"/></g>')
        g[0] = g[0].replace("</defs>", f'<radialGradient id="sh-{name}" cx="{cx}" cy="{cy}" r="{S}" gradientUnits="userSpaceOnUse">'
                                       f'<stop offset="0" stop-color="#000" stop-opacity="{strength}"/>'
                                       f'<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient></defs>')
    corner("topleft", 0, 0, S, S)
    corner("topright", S + E, 0, 0, S)
    corner("bottomleft", 0, S + E, S, 0)
    corner("bottomright", S + E, S + E, 0, 0)
    g.append(f'<rect id="shadow-top" x="{ox + S}" y="{oy}" width="{E}" height="{S}" fill="url(#sh-v)"/>')
    g.append(f'<rect id="shadow-bottom" x="{ox + S}" y="{oy + S + E}" width="{E}" height="{S}" fill="url(#sh-vb)"/>')
    g.append(f'<rect id="shadow-left" x="{ox}" y="{oy + S}" width="{S}" height="{E}" fill="url(#sh-h)"/>')
    g.append(f'<rect id="shadow-right" x="{ox + S + E}" y="{oy + S}" width="{S}" height="{E}" fill="url(#sh-hr)"/>')
    g.append(f'<rect id="shadow-center" x="{ox + S}" y="{oy + S}" width="{E}" height="{E}" fill="#000" fill-opacity="0"/>')
    # how far the shadow reaches past each edge (top shorter, bottom longer: light from above)
    for side, v in (("top", S // 2), ("bottom", S), ("left", int(S * .75)), ("right", int(S * .75))):
        g.append(f'<rect id="shadow-hint-{side}-margin" x="{ox + 100}" y="{oy}" width="{v}" height="{v}" fill="none"/>')
    return "\n".join(g)


def hints(margins: dict, ox: int) -> str:
    out = []
    for side, v in margins.items():
        out.append(f'<rect id="hint-{side}-margin" x="{ox}" y="{300 + len(out) * 30}" width="{v}" height="{v}" fill="none"/>')
    return "\n".join(out)


def svg(body: str, w=500, h=500) -> str:
    # Stretch borders/centre instead of tiling the 4 px strips: tiling leaves faint seams
    # between pieces (a visible inner rectangle in translucent glass).
    hints = ('<rect id="hint-stretch-borders" x="480" y="480" width="1" height="1" fill="none"/>'
             '<rect id="mask-hint-stretch-borders" x="482" y="480" width="1" height="1" fill="none"/>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n{hints}\n</svg>\n'


def write(rel: str, text: str) -> None:
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)
    print("wrote", p.relative_to(OUT.parents[4]))


PANEL_R, DIALOG_R, TIP_R = 18, 14, 10

if __name__ == "__main__":
    # Panels: the full-width menu bar shows only its bottom edge; the floating dock is fully rounded.
    for sub, a in (("", 0.86), ("translucent/", 0.50), ("opaque/", 1.0)):
        bar_a = {"": 0.80, "translucent/": 0.36, "opaque/": 1.0}[sub]
        write(f"{sub}widgets/panel-background.svg", svg(
            frame("", PANEL_R, bar_a, tint=BAR_TINT) + "\n" + mask(PANEL_R, 0, 60) + "\n" + shadow(22, 0, 140, 0.38) + "\n"
            + hints({"top": 5, "bottom": 5, "left": 10, "right": 10}, 400)))
        write(f"{sub}dialogs/background.svg", svg(
            frame("", DIALOG_R, min(1.0, a + 0.12)) + "\n" + mask(DIALOG_R, 0, 60) + "\n" + shadow(26, 0, 140, 0.45) + "\n"
            + hints({"top": 10, "bottom": 10, "left": 10, "right": 10}, 400)))
        write(f"{sub}widgets/tooltip.svg", svg(
            frame("", TIP_R, min(1.0, a + 0.2)) + "\n" + mask(TIP_R, 0, 60) + "\n" + shadow(14, 0, 140, 0.35) + "\n"
            + hints({"top": 7, "bottom": 7, "left": 10, "right": 10}, 400)))
    # Dock: soft rounded glass behind open (normal) and focused apps instead of a solid block
    tasks = "\n".join([
        soft("normal", 12, "#ffffff", 0.05, 0, 0),
        soft("focus", 12, "#ffffff", 0.13, 60, 0),
        soft("hover", 12, "#ffffff", 0.18, 120, 0),
        soft("attention", 12, "#d21f3c", 0.45, 180, 0),
        soft("minimized", 12, "#ffffff", 0.03, 240, 0),
    ])
    write("widgets/tasks.svg", svg(tasks))
    # Search/text fields: rounded frosted pill; focus = soft Ravana-red glow, hover = brighter
    lineedit = "\n".join([
        soft("base", 11, "#ffffff", 0.09, 0, 0),
        soft("hover", 11, "#ffffff", 0.06, 60, 0),
        soft("focus", 11, "#d21f3c", 0.16, 120, 0),
        '<rect id="hint-top-margin" x="300" y="0" width="6" height="6" fill="none"/>',
        '<rect id="hint-bottom-margin" x="300" y="10" width="6" height="6" fill="none"/>',
        '<rect id="hint-left-margin" x="300" y="20" width="10" height="10" fill="none"/>',
        '<rect id="hint-right-margin" x="300" y="40" width="10" height="10" fill="none"/>',
    ])
    write("widgets/lineedit.svg", svg(lineedit))
    write("metadata.json", """{
    "KPackageStructure": "Plasma/Theme",
    "KPlugin": {
        "Authors": [{ "Name": "Ravana OS" }],
        "Description": "Frosted glass menu bar, dock and popups for Ravana OS",
        "Id": "ravana-glass",
        "License": "GPL-2.0-or-later",
        "Name": "Ravana Glass",
        "Version": "1.0",
        "Website": "https://github.com/ravana-os/ravana-os"
    },
    "X-Plasma-API": "5.0"
}
""")
    # Blur only: KWin applies the contrast/saturation boost to a rectangle, not the rounded
    # glass, which showed as a coloured square around the dock's corners
    write("plasmarc", """[ContrastEffect]
enabled=false

[BlurBehindEffect]
enabled=true

[AdaptiveTransparency]
enabled=true
""")
