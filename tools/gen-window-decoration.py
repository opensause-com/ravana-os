#!/usr/bin/env python3
"""Generate the Ravana window decoration (Aurorae theme).

Dark title bar that blends into the app's toolbar, rounded top corners,
soft drop shadow, and red / yellow / green round buttons on the left.
Output: system_files/usr/share/aurorae/themes/Ravana/
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "system_files/usr/share/aurorae/themes/Ravana"

# Geometry (px)
P = 24      # shadow padding left/right
PT = 14     # shadow padding top
PB = 34     # shadow padding bottom
R = 18      # top corner radius (matches the rounded-corners effect)
TITLE_EDGE_TOP, TITLE_HEIGHT, TITLE_EDGE_BOTTOM = 5, 24, 5   # 34 px title bar
BTN = 14    # button box (12 px circle + 1 px margin)

ACTIVE = dict(bar="#0e0e10", top_hl=0.10, shadow=0.55, line="#26262b")
INACTIVE = dict(bar="#151518", top_hl=0.05, shadow=0.30, line="#202024")


def frame(prefix: str, s: dict) -> str:
    """Nine-slice frame for one state. Corner/side sizes: left/right = P+R, top = PT+R, bottom = PB."""
    bar, sh, hl = s["bar"], s["shadow"], s["top_hl"]
    W, H = P + R, PT + R          # corner size (top)
    BW, BH = P + R, PB            # corner size (bottom)
    g = []
    ids = lambda n: f'{prefix}-{n}'
    # defs: gradients
    g.append(f'''<defs>
  <linearGradient id="{prefix}-gl" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="{sh * 0.55:.3f}"/>
  </linearGradient>
  <linearGradient id="{prefix}-gr" x1="1" y1="0" x2="0" y2="0">
    <stop offset="0" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="{sh * 0.55:.3f}"/>
  </linearGradient>
  <linearGradient id="{prefix}-gt" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="{sh * 0.30:.3f}"/>
  </linearGradient>
  <linearGradient id="{prefix}-gb" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#000" stop-opacity="{sh * 0.75:.3f}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </linearGradient>
  <radialGradient id="{prefix}-gtl" cx="{W}" cy="{H}" r="{R + P}" gradientUnits="userSpaceOnUse">
    <stop offset="{R / (R + P):.3f}" stop-color="#000" stop-opacity="{sh * 0.45:.3f}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="{prefix}-gtr" cx="0" cy="{H}" r="{R + P}" gradientUnits="userSpaceOnUse">
    <stop offset="{R / (R + P):.3f}" stop-color="#000" stop-opacity="{sh * 0.45:.3f}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="{prefix}-gbl" cx="{P}" cy="0" r="{PB}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#000" stop-opacity="{sh * 0.65:.3f}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="{prefix}-gbr" cx="{R}" cy="0" r="{PB}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#000" stop-opacity="{sh * 0.65:.3f}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
</defs>''')
    # Each element sits in its own region of the canvas; ids are what Aurorae reads.
    ox = {"tl": 0, "t": 100, "tr": 200, "l": 0, "c": 100, "r": 200, "bl": 0, "b": 100, "br": 200}
    oy = {"tl": 0, "t": 0, "tr": 0, "l": 100, "c": 100, "r": 100, "bl": 200, "b": 200, "br": 200}

    def at(k, body, w, h, name):
        return (f'<g id="{ids(name)}" transform="translate({ox[k]},{oy[k]})">'
                f'<rect width="{w}" height="{h}" fill="none"/>{body}</g>')

    # top-left: shadow quarter + rounded bar corner
    tl = (f'<rect width="{W}" height="{H}" fill="url(#{prefix}-gtl)"/>'
          f'<path d="M{P},{H} L{P},{PT + R} A{R},{R} 0 0 1 {P + R},{PT} L{W},{PT} L{W},{H} Z" fill="{bar}"/>'
          f'<path d="M{P + 0.5},{H} L{P + 0.5},{PT + R} A{R - 0.5},{R - 0.5} 0 0 1 {P + R},{PT + 0.5} L{W},{PT + 0.5}" '
          f'fill="none" stroke="#fff" stroke-opacity="{hl}"/>')
    tr = (f'<rect width="{W}" height="{H}" fill="url(#{prefix}-gtr)"/>'
          f'<path d="M0,{H} L0,{PT} A{R},{R} 0 0 1 {R},{PT + R} L{R},{H} Z" fill="{bar}"/>'
          f'<path d="M0,{PT + 0.5} A{R - 0.5},{R - 0.5} 0 0 1 {R - 0.5},{PT + R} L{R - 0.5},{H}" '
          f'fill="none" stroke="#fff" stroke-opacity="{hl}"/>')
    t = (f'<rect width="10" height="{PT}" fill="url(#{prefix}-gt)"/>'
         f'<rect y="{PT}" width="10" height="{R}" fill="{bar}"/>'
         f'<rect y="{PT}" width="10" height="1" fill="#fff" fill-opacity="{hl}"/>')
    l = (f'<rect width="{P}" height="10" fill="url(#{prefix}-gl)"/>'
         f'<rect x="{P}" width="{R}" height="10" fill="{bar}"/>')
    r = (f'<rect width="{R}" height="10" fill="{bar}"/>'
         f'<rect x="{R}" width="{P}" height="10" fill="url(#{prefix}-gr)"/>')
    c = f'<rect width="10" height="10" fill="{bar}"/>'
    bl = (f'<rect width="{P}" height="{BH}" fill="url(#{prefix}-gbl)"/>'
          f'<rect x="{P}" width="{R}" height="{BH}" fill="url(#{prefix}-gb)"/>')
    b = f'<rect width="10" height="{BH}" fill="url(#{prefix}-gb)"/>'
    br = (f'<rect width="{R}" height="{BH}" fill="url(#{prefix}-gb)"/>'
          f'<rect x="{R}" width="{P}" height="{BH}" fill="url(#{prefix}-gbr)"/>')
    g += [at("tl", tl, W, H, "topleft"), at("t", t, 10, H, "top"), at("tr", tr, W, H, "topright"),
          at("l", l, BW, 10, "left"), at("c", c, 10, 10, "center"), at("r", r, BW, 10, "right"),
          at("bl", bl, BW, BH, "bottomleft"), at("b", b, 10, BH, "bottom"), at("br", br, BW, BH, "bottomright")]
    return "\n".join(g)


def decoration_svg() -> str:
    body = [frame("decoration", ACTIVE), frame("decoration-inactive", INACTIVE)]
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300">\n'
            + "\n".join(body) + "\n</svg>\n")


def button_svg(color: str, ring: str, glyph: str) -> str:
    c = BTN / 2
    rr = 6

    def state(prefix, fill, stroke, show_glyph, x):
        gl = f'<g transform="translate({x},0)" stroke="#4d0000" stroke-opacity="0.75" stroke-width="1.3" stroke-linecap="round" fill="none">{glyph}</g>' if show_glyph else ""
        return (f'<g id="{prefix}-center"><rect x="{x}" width="{BTN}" height="{BTN}" fill="none"/>'
                f'<circle cx="{x + c}" cy="{c}" r="{rr}" fill="{fill}" stroke="{stroke}" stroke-width="0.6"/>{gl}</g>')

    parts = [
        state("active", color, ring, False, 0),
        state("hover", color, ring, True, 20),
        state("pressed", ring, ring, True, 40),
        state("inactive", "#3c3c42", "#4a4a50", False, 60),
        state("hover-inactive", color, ring, True, 80),
        state("deactivated", "#3c3c42", "#4a4a50", False, 100),
    ]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="120" height="{BTN}" viewBox="0 0 120 {BTN}">\n'
            + "\n".join(parts) + "\n</svg>\n")


GLYPH_X = 'M4.5,4.5 L9.5,9.5 M9.5,4.5 L4.5,9.5'
GLYPH_MIN = 'M4,7 L10,7'
GLYPH_MAX = 'M4,7 L10,7 M7,4 L7,10'
GLYPH_RESTORE = 'M4.6,7 L9.4,7'


def rc() -> str:
    return f"""[General]
ActiveTextColor=235,235,240
InactiveTextColor=130,130,138
UseTextShadow=false
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=120
Shadow=true
DecorationPosition=0

[Layout]
BorderLeft=0
BorderRight=0
BorderBottom=0
BorderTop=0
TitleEdgeTop={TITLE_EDGE_TOP}
TitleEdgeBottom={TITLE_EDGE_BOTTOM}
TitleEdgeLeft=12
TitleEdgeRight=12
TitleEdgeTopMaximized={TITLE_EDGE_TOP}
TitleEdgeBottomMaximized={TITLE_EDGE_BOTTOM}
TitleEdgeLeftMaximized=12
TitleEdgeRightMaximized=12
TitleBorderLeft=12
TitleBorderRight=12
TitleHeight={TITLE_HEIGHT}
ButtonWidth={BTN}
ButtonHeight={BTN}
ButtonSpacing=6
ButtonMarginTop={(TITLE_HEIGHT - BTN) // 2}
ButtonMarginTopMaximized={(TITLE_HEIGHT - BTN) // 2}
ExplicitButtonSpacer=10
PaddingLeft={P}
PaddingRight={P}
PaddingTop={PT}
PaddingBottom={PB}
"""


METADATA = """[Desktop Entry]
Name=Ravana
Comment=Ravana OS window frame: dark, rounded, red / yellow / green buttons
X-KDE-PluginInfo-Author=Ravana OS
X-KDE-PluginInfo-Name=Ravana
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
"""


def write(name: str, text: str) -> None:
    p = OUT / name
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)
    print("wrote", p.relative_to(OUT.parents[5]))


if __name__ == "__main__":
    write("decoration.svg", decoration_svg())
    write("close.svg", button_svg("#ff5f57", "#e0443e", f'<path d="{GLYPH_X}"/>'))
    write("minimize.svg", button_svg("#febc2e", "#dea123", f'<path d="{GLYPH_MIN}"/>'))
    write("maximize.svg", button_svg("#28c840", "#1aab29", f'<path d="{GLYPH_MAX}"/>'))
    write("restore.svg", button_svg("#28c840", "#1aab29", f'<path d="{GLYPH_RESTORE}"/>'))
    write("Ravanarc", rc())
    write("metadata.desktop", METADATA)
