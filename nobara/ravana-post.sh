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
systemctl --global enable ravana-shell.service ravana-osd.service
systemctl --global mask plasma-plasmashell.service plasma-polkit-agent.service || true
rm -f /etc/xdg/autostart/ravana-look-update.desktop
f=/etc/xdg/autostart/polkit-kde-authentication-agent-1.desktop
[ -f "$f" ] && { grep -q '^Hidden=true' "$f" || echo 'Hidden=true' >> "$f"; }
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
bash /tmp/ravana-build/57-ravana-performance.sh || true

# --- the installer (Calamares) copies this live system to the disk. The live autologin must not
# come along: the installed system has no "liveuser". Calamares runs these in the new system.
cat >> /usr/share/calamares/modules/shellprocess.conf <<'CAL'
    - command: "rm -f /etc/sddm.conf /etc/sddm.conf.d/zzz-ravana-live.conf"
CAL
