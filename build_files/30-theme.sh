#!/usr/bin/env bash
# Ravana desktop defaults for new users: Ravana Global Theme (top bar + dock),
# Ravana Dark colors, fonts, icons and macOS-style window animations.
# The theme package lives in system_files/usr/share/plasma/look-and-feel/org.ravana.desktop
set -euxo pipefail
KW="$(command -v kwriteconfig6)"
LNF=/usr/share/plasma/look-and-feel/org.ravana.desktop
test -f /usr/share/color-schemes/RavanaDark.colors
test -f "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js"

# Show what the base ships (visible in the build log)
grep -E '^(\[|LookAndFeelPackage|ColorScheme)' /etc/xdg/kdeglobals || true

# --- Global theme + colors, fonts, icons (system-wide defaults) ---
$KW --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.ravana.desktop
$KW --file /etc/xdg/kdeglobals --group KDE --key widgetStyle Breeze
$KW --file /etc/xdg/kdeglobals --group KDE --key AnimationDurationFactor 0.8
$KW --file /etc/xdg/kdeglobals --group General --key ColorScheme RavanaDark
$KW --file /etc/xdg/kdeglobals --group General --key font "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
$KW --file /etc/xdg/kdeglobals --group General --key menuFont "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
$KW --file /etc/xdg/kdeglobals --group General --key fixed "JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
$KW --file /etc/xdg/kdeglobals --group Icons --key Theme Papirus-Dark
# Old Vapor (Steam Deck) global theme default must not win over ours
sed -i '/^LookAndFeelPackage=com.valve.vapor.desktop$/d' /etc/xdg/kdeglobals

# --- Window buttons on the left, macOS-style ---
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key theme Breeze
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""

# --- Animations and effects (GPU-cheap, no RAM cost) ---
$KW --file /etc/xdg/kwinrc --group Plugins --key magiclampEnabled true      # genie minimize
$KW --file /etc/xdg/kwinrc --group Plugins --key squashEnabled false
$KW --file /etc/xdg/kwinrc --group Plugins --key kwin4_effect_squashEnabled false
$KW --file /etc/xdg/kwinrc --group Plugins --key blurEnabled true           # translucent panels/menus
$KW --file /etc/xdg/kwinrc --group Plugins --key contrastEnabled true
$KW --file /etc/xdg/kwinrc --group Plugins --key overviewEnabled true       # Mission Control (Meta+W)
$KW --file /etc/xdg/kwinrc --group Plugins --key wobblywindowsEnabled false
$KW --file /etc/xdg/kwinrc --group Effect-blur --key BlurStrength 10
$KW --file /etc/xdg/kwinrc --group Effect-blur --key NoiseStrength 0
# Top-left hot corner opens Overview, like macOS Mission Control corners
$KW --file /etc/xdg/kwinrc --group Effect-overview --key BorderActivate 9 || true
$KW --file /etc/xdg/kwinrc --group ElectricBorders --key TopLeft Overview || true

# --- Dock: keep only launchers whose apps exist in this image ---
# (Firefox is a Flatpak installed on first boot, so it is always kept.)
LAYOUT="$LNF/contents/layouts/org.kde.plasma.desktop-layout.js"
# VS Code's launcher name varies by packaging; use whatever the code package ships
VSCODE_DESKTOP="$(rpm -ql code 2>/dev/null | grep -E '^/usr/share/applications/[^/]+\.desktop$' | grep -viE 'url-?handler' | head -1 || true)"
echo "VS Code launcher: ${VSCODE_DESKTOP:-none}"
if [ -n "$VSCODE_DESKTOP" ]; then
    sed -i "s|\"applications:code.desktop\"|\"applications:$(basename "$VSCODE_DESKTOP")\"|" "$LAYOUT"
fi
for app in org.kde.dolphin steam "$(basename "${VSCODE_DESKTOP:-code.desktop}" .desktop)" org.gnome.Ptyxis org.kde.konsole systemsettings; do
    if [ ! -f "/usr/share/applications/$app.desktop" ]; then
        echo "Dock: dropping missing launcher $app"
        sed -i "/\"applications:$app.desktop\",\?/d" "$LAYOUT"
    fi
done
# If both terminals exist, keep only one (Ptyxis is Bazzite's default)
if grep -q 'org.gnome.Ptyxis.desktop' "$LAYOUT"; then
    sed -i '/"applications:org.kde.konsole.desktop",\?/d' "$LAYOUT"
fi
# Fix a trailing comma left before the closing bracket
sed -i -z 's/,\n\(\s*\]\.join\)/\n\1/' "$LAYOUT"
sed -n '/launchers/,/join/p' "$LAYOUT"

grep -A6 '^\[KDE\]' /etc/xdg/kdeglobals

# --- Login splash (login -> desktop) ---
$KW --file /etc/xdg/ksplashrc --group KSplash --key Engine KSplashQML
$KW --file /etc/xdg/ksplashrc --group KSplash --key Theme org.ravana.desktop
test -f "$LNF/contents/splash/Splash.qml"

# --- Login screen (Plasma Login Manager): Ravana wallpaper + clock ---
# The greeter also uses the system-wide Ravana Dark colours, Inter and Papirus.
if [ -f /etc/plasmalogin.conf ]; then
    $KW --file /etc/plasmalogin.conf --group Greeter --key WallpaperPluginId org.kde.image
    $KW --file /etc/plasmalogin.conf --group Greeter --key ShowClock true
    $KW --file /etc/plasmalogin.conf --group Greeter --group Wallpaper --group org.kde.image --group General \
        --key Image "file:///usr/share/wallpapers/Ravana/"
    grep -A3 '^\[Greeter' /etc/plasmalogin.conf
fi

# --- Login screen (SDDM, main edition): Ravana wallpaper, font and cursor ---
if [ -d /usr/share/sddm/themes/breeze ]; then
    cat > /usr/share/sddm/themes/breeze/theme.conf.user <<'SDDM'
[General]
type=image
background=/usr/share/wallpapers/Ravana/contents/images/3840x2160.png
SDDM
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/10-ravana.conf <<'SDDM'
[Theme]
Current=breeze
CursorTheme=breeze_cursors
Font=Inter,10
SDDM
fi

# --- Wallpaper on the lock screen too ---
$KW --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file:///usr/share/wallpapers/Ravana/"

# Refresh the icon cache so ravana-logo resolves everywhere
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
