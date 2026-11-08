#!/usr/bin/env bash
# Edition setup. The main edition is built on Bazzite's Deck image (for Game Mode),
# which normally auto-boots into Game Mode like a Steam Deck. On a PC, Ravana shows
# the login screen instead, with Desktop as the default and Game Mode one click away.
set -euxo pipefail
FLAVOR="${IMAGE_FLAVOR:-main}"
echo "Ravana edition: $FLAVOR"

# App menu entry to add or remove the developer stack (see ravana-edition-switch)
if [ "$FLAVOR" = dx ]; then
    NAME="Remove Developer Tools"; COMMENT="Switch back to Ravana OS without VS Code, Docker, VMs and ROCm"
else
    NAME="Get Developer Tools"; COMMENT="Add VS Code, Docker, virtual machines and ROCm in one click"
fi
cat > /usr/share/applications/ravana-developer-tools.desktop <<DESK
[Desktop Entry]
Type=Application
Name=$NAME
GenericName=Ravana Developer Tools
Comment=$COMMENT
Icon=ravana-os
Exec=/usr/libexec/ravana-edition-switch
Terminal=false
Categories=Development;System;
Keywords=developer;vscode;docker;vm;rocm;edition;ravana;
DESK

[ "$FLAVOR" = main ] || exit 0

ls -la /etc/sddm.conf.d/ 2>/dev/null || true
# Deck-style auto-login into Game Mode and the handheld on-screen keyboard
rm -f /etc/sddm.conf.d/steamos.conf \
      /etc/sddm.conf.d/zz-steamos-autologin.conf \
      /etc/sddm.conf.d/virtualkbd.conf

# First boot: preselect the Plasma desktop session (SDDM remembers the last choice after)
mkdir -p /usr/lib/tmpfiles.d
cat > /usr/lib/tmpfiles.d/ravana-sddm.conf <<'TMP'
d /var/lib/sddm 0750 sddm sddm -
f /var/lib/sddm/state.conf 0644 sddm sddm - [Last]\nSession=/usr/share/wayland-sessions/plasma.desktop\n
TMP

test -f /usr/share/wayland-sessions/plasma.desktop
test -f /usr/share/wayland-sessions/gamescope-session-steam.desktop
