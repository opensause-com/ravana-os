#!/usr/bin/env bash
# Ravana Shell replaces Plasma's shell: KWin stays as the window engine, but the
# desktop you see (wallpaper, menu bar, dock, Launchpad, Control Center) is Ravana's.
set -euxo pipefail
dnf5 install -y --setopt=install_weak_deps=False \
    --repo=ravana-build-fedora --repo=ravana-build-updates quickshell
test -x /usr/bin/quickshell
test -f /usr/share/ravana/shell/shell.qml

# Session: Ravana Shell in, Plasma's shell out
cat /usr/lib/systemd/user/plasma-workspace.target || true
systemctl --global enable ravana-shell.service
systemctl --global mask plasma-plasmashell.service

# The Plasma look updater only knows Plasma panels
rm -f /etc/xdg/autostart/ravana-look-update.desktop

# Search: Ravana Spotlight takes Meta+Space / Alt+Space; KRunner keeps Alt+F2
K=/usr/share/applications/org.kde.krunner.desktop; [ -f "$K" ] && sed -i "s/^X-KDE-Shortcuts=.*/X-KDE-Shortcuts=Alt+F2,Search/" "$K"
test -f /usr/share/kglobalaccel/org.ravana.spotlight.desktop

# HUDs: KDE's volume/brightness keys report to Plasma's OSD service; Ravana answers it
python3 -c 'import dbus, gi; from gi.repository import GLib' || \
    dnf5 install -y --setopt=install_weak_deps=False python3-dbus python3-gobject-base
systemctl --global enable ravana-osd.service
