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
