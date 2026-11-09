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
$KW --file /etc/xdg/kdeglobals --group Icons --key Theme Colloid-Red-Dark
# Ravana Glass: frosted menu bar, dock and popups (system_files/.../desktoptheme/ravana-glass)
test -f /usr/share/plasma/desktoptheme/ravana-glass/metadata.json
$KW --file /etc/xdg/plasmarc --group Theme --key name ravana-glass
# Apps read the actual colours from kdeglobals' [Colors:*] groups, not from the
# scheme name, so copy Ravana Dark's colour groups in (replacing the base image's).
python3 - /usr/share/color-schemes/RavanaDark.colors /etc/xdg/kdeglobals <<'PY'
import re, sys
def sections(path):
    out, cur = [], None
    for line in open(path, encoding="utf-8").read().splitlines():
        if line.startswith("["):
            cur = [line, []]
            out.append(cur)
        elif cur is not None:
            cur[1].append(line)
        elif line.strip():
            out.append([None, [line]])
    return out
colour = re.compile(r"^\[(Colors:|ColorEffects:|WM\])")
scheme, globs = sections(sys.argv[1]), sections(sys.argv[2])
keep = [s for s in globs if not (s[0] and colour.match(s[0]))]
add = [s for s in scheme if s[0] and colour.match(s[0])]
with open(sys.argv[2], "w", encoding="utf-8") as f:
    for head, body in keep + add:
        if head:
            f.write(head + "\n")
        for line in body:
            if line.strip():
                f.write(line + "\n")
        f.write("\n")
print("kdeglobals colour groups:", [s[0] for s in add])
PY
grep -A2 '^\[Colors:View\]' /etc/xdg/kdeglobals
$KW --file /etc/xdg/kdeglobals --group KDE --key contrast 4
$KW --file /etc/xdg/kdeglobals --group General --key AccentColor "210,31,60"
# Old Vapor (Steam Deck) global theme default must not win over ours
sed -i '/^LookAndFeelPackage=com.valve.vapor.desktop$/d' /etc/xdg/kdeglobals

# --- Window buttons on the left, macOS-style ---
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key theme Breeze
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
$KW --file /etc/xdg/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""

# --- Animations and effects (GPU-cheap, no RAM cost) ---
# Ravana's own motion (usr/share/kwin/effects): Rise for open/close, Ember for minimize
test -f /usr/share/kwin/effects/ravana_rise/contents/code/main.js
test -f /usr/share/kwin/effects/ravana_ember/contents/code/main.js
$KW --file /etc/xdg/kwinrc --group Plugins --key ravana_riseEnabled true
$KW --file /etc/xdg/kwinrc --group Plugins --key ravana_emberEnabled true
for fx in scale glide fade magiclamp squash kwin4_effect_squash kwin4_effect_scale; do
    $KW --file /etc/xdg/kwinrc --group Plugins --key "${fx}Enabled" false
done
$KW --file /etc/xdg/kwinrc --group Plugins --key blurEnabled true           # translucent panels/menus
$KW --file /etc/xdg/kwinrc --group Plugins --key contrastEnabled true
$KW --file /etc/xdg/kwinrc --group Plugins --key overviewEnabled true       # Mission Control (Meta+W)
$KW --file /etc/xdg/kwinrc --group Plugins --key wobblywindowsEnabled false
$KW --file /etc/xdg/kwinrc --group Effect-blur --key BlurStrength 10
$KW --file /etc/xdg/kwinrc --group Effect-blur --key NoiseStrength 0
# No hot corners (macOS default): the top-left corner is the Ravana menu.
# Mission Control = Overview: Meta+W, or swipe up with four fingers.

# --- Spotlight: KRunner centered on screen, on Meta+Space as well ---
$KW --file /etc/xdg/krunnerrc --group General --key FreeFloating true
$KW --file /etc/xdg/krunnerrc --group General --key ActivateWhenTypingOnDesktop true
KRUNNER_DESKTOP=/usr/share/applications/org.kde.krunner.desktop
if [ -f "$KRUNNER_DESKTOP" ]; then
    sed -i 's/^X-KDE-Shortcuts=.*/X-KDE-Shortcuts=Meta+Space,Alt+Space,Alt+F2,Search/' "$KRUNNER_DESKTOP"
    grep '^X-KDE-Shortcuts' "$KRUNNER_DESKTOP"
fi

# --- Ravana top-bar widgets (menu + search) must be installed ---
for t in org.ravana.menubar org.ravana.dock; do
    test -f "/usr/share/plasma/layout-templates/$t/contents/layout.js"
done
for w in org.ravana.menu org.ravana.search org.ravana.appname org.ravana.launchpad org.ravana.dockapps org.ravana.controlcenter; do
    test -f "/usr/share/plasma/plasmoids/$w/contents/ui/main.qml"
done

# --- Dock: keep only launchers whose apps exist in this image ---
# (The browser slot is "preferred://browser": whatever browser the user has.)
LAYOUT=/usr/share/plasma/layout-templates/org.ravana.dock/contents/layout.js
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

# --- Wallpapers: Ravana only (Plasma's built-in default falls back to it too) ---
find /usr/share/wallpapers -mindepth 1 -maxdepth 1 ! -name 'Ravana*' -print -exec rm -rf {} +
ln -sfn Ravana /usr/share/wallpapers/Next
if [ -d /usr/share/backgrounds ]; then
    for f in default default-dark; do
        rm -f /usr/share/backgrounds/$f.{jxl,png,jpg,xml}
        ln -sf /usr/share/wallpapers/Ravana/contents/images/3840x2160.png /usr/share/backgrounds/$f.png
    done
fi
ls -la /usr/share/wallpapers

# --- Desktop stays clean: no "Return to Gaming Mode" icon on it ---
# (Gaming Mode itself stays available from the app menu.)
grep -rl -i 'Return to Gaming Mode' /etc/skel 2>/dev/null | while read -r f; do
    echo "Removing desktop icon: $f"
    rm -f "$f"
done
grep -rl -i 'Return to Gaming Mode' /usr/share/applications /usr/share/ublue-os 2>/dev/null || true

# --- Wallpaper on the lock screen too ---
$KW --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file:///usr/share/wallpapers/Ravana/"

# Refresh the icon cache so ravana-logo resolves everywhere
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

# Ravana UI kit (QML design system used by Ravana's own surfaces) must import
test -f /usr/lib64/qt6/qml/org/ravana/ui/qmldir
