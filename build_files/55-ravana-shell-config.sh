#!/usr/bin/env bash
# Ravana Shell desktop settings that are plain config (no packages). The image build
# runs this, and so does the fast-lane screenshot run on top of the last image.
set -euxo pipefail
KW="$(command -v kwriteconfig6)"

# ⌘Tab: Ravana switcher, one entry per app (⌘` walks the current app's windows)
$KW --file /etc/xdg/kwinrc --group TabBox --key LayoutName ravana
$KW --file /etc/xdg/kwinrc --group TabBox --key ApplicationsMode 1
$KW --file /etc/xdg/kwinrc --group TabBox --key HighlightWindows false
$KW --file /etc/xdg/kwinrc --group TabBoxAlternative --key LayoutName ravana

# Search: Ravana Spotlight owns ⌘Space / ⌥Space; KRunner keeps Alt+F2
K=/usr/share/applications/org.kde.krunner.desktop
[ -f "$K" ] && sed -i "s/^X-KDE-Shortcuts=.*/X-KDE-Shortcuts=Alt+F2,Search/" "$K"
S=/etc/skel/.config/kglobalshortcutsrc
if [ -f "$S" ]; then
    python3 - "$S" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("_launch=Meta+Space\tAlt+Space\tAlt+F2\tSearch", "_launch=Alt+F2\tSearch")
if "[services][org.ravana.spotlight.desktop]" not in s:
    s += "\n[services][org.ravana.spotlight.desktop]\n_launch=Meta+Space\tAlt+Space\n"
if "[services][org.ravana.launchpad.desktop]" not in s:
    s += "\n[services][org.ravana.launchpad.desktop]\n_launch=F4\tAlt+F1\n"
open(p, "w").write(s)
PY
fi

# Trackpad gestures (InputActions, built in the Containerfile): turn the plugin on if it's there
if ls /usr/lib64/qt6/plugins/kwin/*/*inputactions* /usr/lib64/qt6/plugins/kwin/*/*gestures* >/dev/null 2>&1; then
    $KW --file /etc/xdg/kwinrc --group Plugins --key kwin_gesturesEnabled true
    ls /usr/lib64/qt6/plugins/kwin/*/*inputactions* /usr/lib64/qt6/plugins/kwin/*/*gestures* 2>/dev/null
else
    echo "InputActions not in this image: KWin's built-in gestures stay"
fi

# Ravana Settings is "System Settings"; KDE's stays reachable from its Advanced… buttons
for f in /usr/share/applications/systemsettings.desktop /usr/share/applications/org.kde.kinfocenter.desktop; do
    [ -f "$f" ] && { grep -q '^NoDisplay=true' "$f" || sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "$f"; }
done
test -x /usr/bin/ravana-settings

# Ravana Settings runs on Ravana Shell's engine (app id org.quickshell): show it as
# "System Settings" with the settings icon in the menu bar and the Dock
$KW --file /etc/xdg/taskmanagerrulesrc --group Mapping --key org.quickshell org.ravana.settings
$KW --file /etc/xdg/taskmanagerrulesrc --group Mapping --key quickshell org.ravana.settings

# Lock screen: Ravana clock on Plasma's own (unchanged) unlock logic, Lanka wallpaper
/usr/libexec/ravana-lockscreen-style
$KW --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file:///usr/share/wallpapers/RavanaLanka/"
