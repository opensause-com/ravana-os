#!/usr/bin/env bash
# GTK/libadwaita apps, Flatpaks, Firefox and Chrome get the same macOS-style look:
# WhiteSur (prebuilt GTK 3 themes + red-accent libadwaita styling, from the gtktheme stage) with the window
# buttons on the left (close, minimize, maximize) like everything else in Ravana.
set -euxo pipefail
DARK=WhiteSur-Dark
LIGHT=WhiteSur-Light
ls /usr/share/themes
test -d "/usr/share/themes/$DARK" && test -d "/usr/share/themes/$LIGHT"

# --- GTK 3 / 4 defaults (system-wide and for new users) ---
for v in 3.0 4.0; do
    install -d "/etc/xdg/gtk-$v" "/etc/skel/.config/gtk-$v"
    cat > "/etc/xdg/gtk-$v/settings.ini" <<INI
[Settings]
gtk-theme-name=$DARK
gtk-icon-theme-name=Colloid-Red-Dark
gtk-font-name=Inter 10
gtk-cursor-theme-name=breeze_cursors
gtk-application-prefer-dark-theme=true
gtk-decoration-layout=close,minimize,maximize:
gtk-primary-button-warps-slider=true
INI
    cp "/etc/xdg/gtk-$v/settings.ini" "/etc/skel/.config/gtk-$v/settings.ini"
done
# libadwaita apps ignore GTK themes; WhiteSur's libadwaita styling goes in the user's gtk-4.0
cp -r /usr/share/ravana/gtk-4.0/. /etc/skel/.config/gtk-4.0/

# KDE would otherwise rewrite the GTK settings with Breeze on every login
kwriteconfig6 --file /etc/xdg/kded6rc --group Module-gtkconfig --key autoload false

# --- Flatpak apps (Firefox, Chrome, Bazaar...) see the theme and settings too ---
# Themes copied into the user's data dir (Flatpaks can't read /usr/share/themes)
install -d /etc/skel/.local/share/themes
cp -r "/usr/share/themes/$DARK" "/usr/share/themes/$LIGHT" /etc/skel/.local/share/themes/
cat > /usr/lib/tmpfiles.d/ravana-flatpak-theme.conf <<'TMP'
# Flatpak apps: read the user's GTK settings and themes, use the Ravana GTK theme
d /var/lib/flatpak/overrides 0755 root root -
f /var/lib/flatpak/overrides/global 0644 root root - [Context]\nfilesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro;xdg-data/themes:ro;\n\n[Environment]\nGTK_THEME=WhiteSur-Dark\n
TMP

# --- Chrome / Chromium: use the GTK look (WhiteSur traffic-light buttons) from the first run ---
for d in /etc/skel/.config/google-chrome/Default /etc/skel/.config/chromium/Default \
         /etc/skel/.var/app/com.google.Chrome/config/google-chrome/Default \
         /etc/skel/.var/app/org.chromium.Chromium/config/chromium/Default; do
    install -d "$d"
    cat > "$d/Preferences" <<'JSON'
{"browser": {"custom_chrome_frame": true}, "extensions": {"theme": {"system_theme": 1}}}
JSON
done
