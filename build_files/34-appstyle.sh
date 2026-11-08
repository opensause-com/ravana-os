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
