#!/usr/bin/env bash
# Ravana Glass app style: rounded macOS-like controls (Kvantum, based on its KvMojave
# theme) in Ravana colours, with translucent, blurred menus and popups.
set -euxo pipefail
dnf5 install -y --setopt=install_weak_deps=False \
    --repo=ravana-build-fedora --repo=ravana-build-updates kvantum
SRC=/usr/share/Kvantum/KvMojave
DST=/usr/share/Kvantum/RavanaGlass
test -f "$SRC/KvMojave.kvconfig"
install -d "$DST"
cp "$SRC/KvMojave.svg" "$DST/RavanaGlass.svg"
cp "$SRC/KvMojave.kvconfig" "$DST/RavanaGlass.kvconfig"
# KvMojave's blue accents -> Ravana red at the same lightness
sed -i -e 's/#245fc4/#b81a33/gI' -e 's/#2664d0/#c41c37/gI' -e 's/#286adc/#d21f3c/gI' \
       -e 's/#295e9f/#9e1e33/gI' -e 's/#3273c3/#c3283f/gI' -e 's/#31a7e8/#e8455c/gI' \
       -e 's/#3daee9/#ec4a60/gI' -e 's/#436e99/#99303f/gI' -e 's/#4478ac/#ac3445/gI' \
       -e 's/#81c0ff/#ff8a99/gI' -e 's/#000356/#350008/gI' -e 's/#b74aff/#ff5a66/gI' \
       "$DST/RavanaGlass.svg" "$DST/RavanaGlass.kvconfig"
! grep -qiE '#(245fc4|2664d0|286adc|295e9f|3273c3|3daee9)' "$DST/RavanaGlass.svg"

python3 - "$DST/RavanaGlass.kvconfig" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read().splitlines()
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
    "GeneralColors": {
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
grep -E '^(highlight.color|window.color|popup_blurring|reduce_menu_opacity)=' "$DST/RavanaGlass.kvconfig"

# Use it system-wide (Qt/KDE apps)
install -d /etc/xdg/Kvantum
printf '[General]\ntheme=RavanaGlass\n' > /etc/xdg/Kvantum/kvantum.kvconfig
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key widgetStyle kvantum
sed -i 's/^widgetStyle=Breeze$/widgetStyle=kvantum/' \
    /usr/share/plasma/look-and-feel/org.ravana.desktop/contents/defaults
test -f /usr/lib64/qt6/plugins/styles/libkvantum.so || test -f /usr/lib/qt6/plugins/styles/libkvantum.so
sed -i "/^\[Desktop Entry\]/a NoDisplay=true" /usr/share/applications/kvantummanager.desktop 2>/dev/null || true
