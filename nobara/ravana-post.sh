#!/usr/bin/env bash
# Runs inside the new system at the end of the Ravana ISO build (see make-ks.py).
# By now system_files/ is copied over the Nobara base; this wires Ravana Shell in.
set -euxo pipefail

# --- identity
OSR=/usr/lib/os-release
setkv() { if grep -q "^$1=" "$OSR"; then sed -i "s|^$1=.*|$1=\"$2\"|" "$OSR"; else echo "$1=\"$2\"" >> "$OSR"; fi; }
setkv NAME        "Ravana OS"
setkv PRETTY_NAME "Ravana OS"
setkv DEFAULT_HOSTNAME "ravana"
setkv ANSI_COLOR "0;38;2;210;31;60"
setkv LOGO "ravana-os"
setkv HOME_URL "https://github.com/ravana-os/ravana-os"
setkv BUG_REPORT_URL "https://github.com/ravana-os/ravana-os/issues"
setkv SUPPORT_URL "https://github.com/ravana-os/ravana-os/discussions"

# --- the shell: Ravana Shell replaces Plasma's shell; KWin stays the window engine
test -x /usr/bin/quickshell
test -f /usr/share/ravana/shell/shell.qml
# On/off switch (see /usr/libexec/ravana-ui-enabled): both desktops are installed, and each
# starts only when the user's setting says so. Default is OFF (classic Plasma) while Ravana
# Shell is not stable: `ravana-ui on` switches it on, `ravana-ui off` back. Nothing is masked.
systemctl --global enable ravana-shell.service ravana-osd.service
rm -f /etc/xdg/autostart/ravana-look-update.desktop
test -x /usr/bin/ravana-ui && test -f /etc/ravana/ui
echo i2c-dev > /usr/lib/modules-load.d/ravana-ddc.conf

# --- login screen: SDDM with the Ravana theme
test -f /usr/share/sddm/themes/ravana/Main.qml
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-ravana.conf <<'SDDM'
[General]
DisplayServer=wayland
InputMethod=

[Theme]
Current=ravana
CursorTheme=breeze_cursors
Font=Inter,10
SDDM
systemctl disable plasmalogin.service 2>/dev/null || true
systemctl enable sddm.service
# the live session logs in by itself; an installed system never does (Calamares removes this)
cat > /etc/sddm.conf.d/zzz-ravana-live.conf <<'LIVE'
[Autologin]
User=liveuser
Session=plasma.desktop
Relogin=false
LIVE

# --- desktop settings (plain config: shortcuts, switcher, settings app)
bash /tmp/ravana-build/55-ravana-shell-config.sh
# the Ravana ⌘Tab switcher belongs to the Ravana UI: classic Plasma keeps its own until `ravana-ui on`
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBox --key LayoutName org.kde.breeze.desktop
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBox --key ApplicationsMode 0
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBoxAlternative --key LayoutName org.kde.breeze.desktop
bash /tmp/ravana-build/57-ravana-performance.sh || true

# --- the installer (Calamares) copies this live system to the disk. The live autologin must not
# come along: the installed system has no "liveuser". Calamares runs these in the new system.
cat >> /usr/share/calamares/modules/shellprocess.conf <<'CAL'
    - command: "rm -f /etc/sddm.conf /etc/sddm.conf.d/zzz-ravana-live.conf"
CAL
