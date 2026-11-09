#!/usr/bin/env bash
# Ravana Glass app style: rounded macOS-like controls (Kvantum, based on its KvMojave
# theme) in Ravana colours, with translucent, blurred menus and popups.
set -euxo pipefail
dnf5 install -y --setopt=install_weak_deps=False \
    --repo=ravana-build-fedora --repo=ravana-build-updates kvantum

build_theme() {   # build_theme <Kvantum base> <Ravana name> <dark|light>
SRC="/usr/share/Kvantum/$1"
DST="/usr/share/Kvantum/$2"
MODE="$3"
test -f "$SRC/$1.kvconfig"
install -d "$DST"
cp "$SRC/$1.svg" "$DST/$2.svg"
cp "$SRC/$1.kvconfig" "$DST/$2.kvconfig"
# KvMojave's blue accents -> Ravana red at the same lightness
sed -i -e 's/#245fc4/#b81a33/gI' -e 's/#2664d0/#c41c37/gI' -e 's/#286adc/#d21f3c/gI' \
       -e 's/#295e9f/#9e1e33/gI' -e 's/#3273c3/#c3283f/gI' -e 's/#31a7e8/#e8455c/gI' \
       -e 's/#3daee9/#ec4a60/gI' -e 's/#436e99/#99303f/gI' -e 's/#4478ac/#ac3445/gI' \
       -e 's/#81c0ff/#ff8a99/gI' -e 's/#000356/#350008/gI' -e 's/#b74aff/#ff5a66/gI' \
       "$DST/$2.svg" "$DST/$2.kvconfig"
! grep -qiE '#(2664d0|286adc|3273c3)' "$DST/$2.svg" || echo "note: some base blues remain in $2"
# Light-grey selections read badly with white text: selected items use Ravana red
# (like macOS uses the accent colour), toggled/pressed toolbar buttons a dark grey.
sed -i -e '/id="itemview-toggled/ s/#\(9e9ea0\|b1b1b3\|c3c3c6\)/#a51d34/gI' \
       -e '/id="itemview-pressed/ s/#\(9e9ea0\|b1b1b3\|c3c3c6\)/#c3283f/gI' \
       -e '/id="tbutton-\(toggled\|pressed\)/ s/#\(9e9ea0\|b1b1b3\|c3c3c6\)/#3d3d44/gI' \
       "$DST/$2.svg"
grep -c 'a51d34' "$DST/$2.svg" || true

python3 - "$DST/$2.kvconfig" "$MODE" <<'PY'
import re, sys
path = sys.argv[1]
light = sys.argv[2] == "light"
text = open(path, encoding="utf-8").read().splitlines()
LIGHT_COLORS = {
        "window.color": "#f2f1f4", "base.color": "#ffffff", "alt.base.color": "#f7f6f8",
        "button.color": "#ffffff", "light.color": "#ffffff", "mid.light.color": "#ecebef",
        "dark.color": "#c9c7ce", "mid.color": "#dedce2",
        "highlight.color": "#d21f3c", "inactive.highlight.color": "#e7a3ae",
        "text.color": "#1d1d1f", "window.text.color": "#1d1d1f", "button.text.color": "#1d1d1f",
        "disabled.text.color": "#a1a1a8", "tooltip.text.color": "#1d1d1f",
        "highlight.text.color": "#ffffff", "link.color": "#c8102e", "link.visited.color": "#8e4bab",
        "progress.indicator.text.color": "#ffffff",
        "inactive.window.color": "#f2f1f4", "inactive.base.color": "#ffffff",
        "inactive.alt.base.color": "#f7f6f8", "inactive.text.color": "#3a3a3c",
        "inactive.window.text.color": "#3a3a3c", "inactive.highlight.text.color": "#ffffff",
        "tooltip.base.color": "#ffffff",
}
want = {
    "%General": {
        "author": "Ravana OS (based on KvMojave)",
        "comment": "Ravana Glass: rounded controls, translucent menus, Ravana red",
        "composite": "true",
        "translucent_windows": "false",
        "blurring": "true",
        "popup_blurring": "true",
        "reduce_menu_opacity": "18",
        "menu_blur_radius": "14",
        "tooltip_blur_radius": "10",
        "menu_shadow_depth": "10",
        "animate_states": "true",
        "scroll_arrows": "false",
        "transient_scrollbar": "true",
        "scrollbar_in_view": "true",
        "tooltip_delay": "350",
    },
    "GeneralColors": LIGHT_COLORS if light else {
        "window.color": "#1b1b1e",
        "base.color": "#151518",
        "alt.base.color": "#1e1e22",
        "button.color": "#2a2a2f",
        "light.color": "#3a3a40",
        "mid.light.color": "#303035",
        "dark.color": "#0e0e10",
        "mid.color": "#222226",
        "highlight.color": "#d21f3c",
        "inactive.highlight.color": "#6a1c28",
        "text.color": "#f5f5f7",
        "window.text.color": "#f5f5f7",
        "button.text.color": "#f5f5f7",
        "disabled.text.color": "#6e6e76",
        "tooltip.text.color": "#f5f5f7",
        "highlight.text.color": "#ffffff",
        "link.color": "#ff5a66",
        "link.visited.color": "#d48ad8",
        "progress.indicator.text.color": "#ffffff",
        "inactive.window.color": "#1b1b1e",
        "inactive.base.color": "#151518",
        "inactive.alt.base.color": "#1e1e22",
        "inactive.text.color": "#e4e4e8",
        "inactive.window.text.color": "#e4e4e8",
        "inactive.highlight.text.color": "#ffffff",
        "tooltip.base.color": "#1e1e22",
    },
}
out, section, seen = [], None, {}
def flush(sec):
    for k, v in want.get(sec, {}).items():
        if k not in seen.get(sec, set()):
            out.append(f"{k}={v}")
for line in text:
    m = re.match(r"^\[(.+)\]\s*$", line)
    if m:
        if section is not None:
            flush(section)
        section = m.group(1)
        seen.setdefault(section, set())
        out.append(line)
        continue
    m = re.match(r"^([A-Za-z0-9_.%-]+)\s*=", line)
    if section in want and m and m.group(1) in want[section]:
        k = m.group(1)
        out.append(f"{k}={want[section][k]}")
        seen[section].add(k)
        continue
    out.append(line)
if section is not None:
    flush(section)
for sec in want:
    if sec not in seen:
        out.append(f"[{sec}]")
        out += [f"{k}={v}" for k, v in want[sec].items()]
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
grep -E '^(highlight.color|window.color|popup_blurring|reduce_menu_opacity)=' "$DST/$2.kvconfig"

# --- Rounded selection pills in lists and sidebars (macOS System Settings style) ---
# Kvantum draws selections from 9-slice SVG elements; replace KvMojave's square ones
# (renamed out of the way) with rounded ones drawn off to the side of the canvas.
python3 - "$DST/$2.svg" "$MODE" <<'PY'
import re, sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
R = 7          # corner radius
E = 4          # edge strip length
states = {"toggled": "#a51d34", "pressed": "#c3283f", "focused": "#2e2e34"}   # focused = hover
if len(sys.argv) > 2 and sys.argv[2] == "light":
    states = {"toggled": "#d21f3c", "pressed": "#b81a33", "focused": "#e6e4ea"}
s = re.sub(r'id="(itemview-(?:toggled|pressed|focused)(?:-[a-z]+)?)"', r'id="old-\1"', s)
out = []
for n, (state, col) in enumerate(states.items()):
    ox, oy = 4000 + n * 40, 4000
    f = f'fill="{col}"'
    pid = f"itemview-{state}"
    corners = {
        "topleft": (0, 0, f"M0,{R} A{R},{R} 0 0 1 {R},0 L{R},{R} Z"),
        "topright": (R + E, 0, f"M0,0 A{R},{R} 0 0 1 {R},{R} L0,{R} Z"),
        "bottomleft": (0, R + E, f"M0,0 L{R},0 L{R},{R} A{R},{R} 0 0 1 0,0 Z"),
        "bottomright": (R + E, R + E, f"M0,0 L{R},0 A{R},{R} 0 0 1 0,{R} Z"),
    }
    for part, (x, y, d) in corners.items():
        out.append(f'<path id="{pid}-{part}" transform="translate({ox + x},{oy + y})" d="{d}" {f}/>')
    for part, x, y, w, h in (("top", R, 0, E, R), ("bottom", R, R + E, E, R), ("left", 0, R, R, E),
                             ("right", R + E, R, R, E)):
        out.append(f'<rect id="{pid}-{part}" x="{ox + x}" y="{oy + y}" width="{w}" height="{h}" {f}/>')
    out.append(f'<rect id="{pid}" x="{ox + R}" y="{oy + R}" width="{E}" height="{E}" {f}/>')
s = s.replace("</svg>", "<g id=\"ravana-pills\">\n" + "\n".join(out) + "\n</g>\n</svg>")
open(path, "w", encoding="utf-8").write(s)
print("rounded itemview selections:", len(out), "elements")
PY
# The frame border sizes must match the new corner size
python3 - "$DST/$2.kvconfig" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()
out, sec, done = [], None, set()
want = {"frame.top": "7", "frame.bottom": "7", "frame.left": "7", "frame.right": "7"}
for line in lines:
    m = re.match(r"^\[(.+)\]$", line)
    if m:
        if sec == "ItemView":
            out += [f"{k}={v}" for k, v in want.items() if k not in done]
        sec = m.group(1)
    elif sec == "ItemView":
        k = line.split("=", 1)[0].strip()
        if k in want:
            line = f"{k}={want[k]}"; done.add(k)
    out.append(line)
if sec == "ItemView":
    out += [f"{k}={v}" for k, v in want.items() if k not in done]
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
grep -A12 '^\[ItemView\]' "$DST/$2.kvconfig" | head -14
}

build_theme KvMojave RavanaGlass dark
build_theme KvMojaveLight RavanaGlassLight light

# Use it system-wide (Qt/KDE apps)
install -d /etc/xdg/Kvantum
printf '[General]\ntheme=RavanaGlass\n' > /etc/xdg/Kvantum/kvantum.kvconfig
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key widgetStyle kvantum
sed -i 's/^widgetStyle=Breeze$/widgetStyle=kvantum/' \
    /usr/share/plasma/look-and-feel/org.ravana.desktop/contents/defaults
test -f /usr/lib64/qt6/plugins/styles/libkvantum.so || test -f /usr/lib/qt6/plugins/styles/libkvantum.so
sed -i "/^\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/kvantummanager.desktop 2>/dev/null || true

