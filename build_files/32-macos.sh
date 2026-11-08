#!/usr/bin/env bash
# macOS-style behaviour: Mac keyboard shortcuts, red/yellow/green window buttons,
# glass menus, Finder-style file manager, app menus in the top bar.
set -euxo pipefail
KW="$(command -v kwriteconfig6)"

# --- Mac shortcuts, part 1: Cmd (Windows key) + letter -> app shortcut (keyd) ---
test -x /usr/bin/keyd
keyd check /etc/keyd/default.conf
systemctl enable keyd.service

# --- Mac shortcuts, part 2: desktop shortcuts (new users) ---
# kglobalaccel reads only the user's file, so the defaults go into /etc/skel.
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kglobalshortcutsrc <<'SC'
[kwin]
Walk Through Windows=Meta+Tab\tAlt+Tab,Alt+Tab,Walk Through Windows
Walk Through Windows (Reverse)=Meta+Shift+Tab\tAlt+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)
Walk Through Windows of Current Application=Meta+`\tAlt+`,Alt+`,Walk Through Windows of Current Application
Walk Through Windows of Current Application (Reverse)=Meta+~\tAlt+~,Alt+~,Walk Through Windows of Current Application (Reverse)
Cycle Overview=none,Meta+Tab,Cycle through Overview and Grid View
Cycle Overview Opposite=none,Meta+Shift+Tab,Cycle through Grid View and Overview
Overview=Ctrl+Up\tMeta+F3,Meta+W,Toggle Overview
ExposeClass=Ctrl+Down,Ctrl+F7,Toggle Present Windows (Window class)
Show Desktop=Meta+F11\tMeta+D,Meta+D,Peek at Desktop
Window Minimize=Meta+M\tMeta+H,Meta+PgDown,Minimize Window
Window Fullscreen=Meta+Ctrl+F,,Make Window Fullscreen
Window Maximize=Meta+Alt+Up\tMeta+PgUp,Meta+PgUp,Maximize Window
Window Quick Tile Left=Meta+Alt+Left,Meta+Left,Quick Tile Window to the Left
Window Quick Tile Right=Meta+Alt+Right,Meta+Right,Quick Tile Window to the Right
Window Quick Tile Bottom=Meta+Alt+Down,Meta+Down,Quick Tile Window to the Bottom
Window Quick Tile Top=none,Meta+Up,Quick Tile Window to the Top
Kill Window=Meta+Alt+Esc\tMeta+Ctrl+Esc,Meta+Ctrl+Esc,Kill Window
Switch One Desktop to the Left=Meta+Ctrl+Left,Meta+Ctrl+Left,Switch One Desktop to the Left
Switch One Desktop to the Right=Meta+Ctrl+Right,Meta+Ctrl+Right,Switch One Desktop to the Right

[ksmserver]
Lock Session=Meta+Ctrl+Q\tScreensaver,Meta+L\tScreensaver,Lock Session
Log Out=Meta+Shift+Q\tCtrl+Alt+Del,Ctrl+Alt+Del,Show Logout Prompt

[services][org.kde.krunner.desktop]
_launch=Meta+Space\tAlt+Space\tAlt+F2\tSearch

[services][org.kde.spectacle.desktop]
FullScreenScreenShot=Meta+Shift+3\tMeta+#\tShift+Print
RectangularRegionScreenShot=Meta+Shift+4\tMeta+$\tMeta+Shift+Print
_launch=Meta+Shift+5\tMeta+%\tPrint
ActiveWindowScreenShot=Meta+Print

[services][org.kde.plasma.emojier.desktop]
_launch=Meta+Ctrl+Space\tMeta+.

[services][org.kde.dolphin.desktop]
_launch=Meta+Alt+Space\tMeta+E
SC
# kconfig expects real tabs between multiple shortcuts
sed -i 's/\\t/\t/g' /etc/skel/.config/kglobalshortcutsrc
cat /etc/skel/.config/kglobalshortcutsrc | head -5

# --- Windows: Ravana frame with red / yellow / green buttons on the left ---
test -f /usr/share/aurorae/themes/Ravana/decoration.svg
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Ravana
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key BorderSize None
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
# Same choice in the Global Theme, so "reset look" keeps it
LNF=/usr/share/plasma/look-and-feel/org.ravana.desktop/contents/defaults
sed -i 's/^library=org.kde.breeze$/library=org.kde.kwin.aurorae/; s/^theme=Breeze$/theme=__aurorae__svg__Ravana/' "$LNF"
grep -A4 'kdecoration2' "$LNF"

# --- Glass: translucent menus and soft, large window shadows ---
$KW --file /etc/xdg/breezerc --group Style --key MenuOpacity 82
$KW --file /etc/xdg/breezerc --group Common --key ShadowSize ShadowVeryLarge

# --- App menus live in the top bar (like macOS) ---
$KW --file /etc/xdg/kdeglobals --group KDE --key ShowIconsInMenuItems false

# --- Finder-style file manager (Dolphin) ---
$KW --file /etc/xdg/dolphinrc --group General --key ShowFullPath false
$KW --file /etc/xdg/dolphinrc --group General --key ShowZoomSlider false
$KW --file /etc/xdg/dolphinrc --group General --key RememberOpenedTabs false
$KW --file /etc/xdg/dolphinrc --group General --key BrowseThroughArchives true
$KW --file /etc/xdg/dolphinrc --group General --key ShowSelectionToggle false
$KW --file /etc/xdg/dolphinrc --group IconsMode --key IconSize 64
$KW --file /etc/xdg/dolphinrc --group IconsMode --key PreviewSize 64
$KW --file /etc/xdg/dolphinrc --group KFileDialog\ Settings --key Places\ Icons\ Auto-resize false
# Menus go to the top bar instead of the window (global menu)
for app in dolphinrc konsolerc katerc okularrc gwenviewrc arkrc; do
    $KW --file "/etc/xdg/$app" --group MainWindow --key MenuBar Enabled
done
