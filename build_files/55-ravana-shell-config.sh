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

# Ravana Settings runs on Ravana Shell's engine, whose windows carry the app id
# org.quickshell. The engine's own launcher entry becomes "System Settings", so the
# Dock, menu bar and ⌘Tab show one Settings app with the right name and icon.
Q=/usr/share/applications/org.quickshell.desktop
cat > "$Q" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=System Settings
GenericName=Ravana Settings
Comment=Wi-Fi, Bluetooth, Sound, Appearance, Displays and more
Exec=ravana-settings
Icon=preferences-system
Categories=Settings;System;
Keywords=settings;preferences;control;wifi;bluetooth;sound;display;appearance;
StartupNotify=false
DESKTOP

# Lock and logout screens: Ravana design on Plasma's own (unchanged) session logic; Lanka wallpaper
/usr/libexec/ravana-session-style
$KW --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file:///usr/share/wallpapers/RavanaLanka/"

# First login: the Ravana Setup Assistant replaces KDE's Welcome Center
for f in /etc/xdg/autostart/org.kde.plasma-welcome.desktop /usr/share/autostart/org.kde.plasma-welcome.desktop; do
    [ -f "$f" ] && { grep -q '^Hidden=true' "$f" || echo "Hidden=true" >> "$f"; }
done
test -x /usr/libexec/ravana-setup

# Ravana sound theme (bronze bell family) for apps' event sounds, KDE and GTK alike
$KW --file /etc/xdg/kdeglobals --group Sounds --key Theme ravana
for g in /etc/xdg/gtk-3.0/settings.ini /etc/xdg/gtk-4.0/settings.ini; do
    $KW --file "$g" --group Settings --key gtk-sound-theme-name ravana
    $KW --file "$g" --group Settings --key gtk-enable-event-sounds 1
done
test -f /usr/share/sounds/ravana/index.theme
