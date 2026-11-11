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

test -f /usr/share/kglobalaccel/org.ravana.spotlight.desktop
test -f /usr/share/kwin/tabbox/ravana/contents/ui/main.qml

# HUDs: KDE's volume/brightness keys report to Plasma's OSD service; Ravana answers it
python3 -c 'import dbus, gi; from gi.repository import GLib' || \
    dnf5 install -y --setopt=install_weak_deps=False python3-dbus python3-gobject-base
systemctl --global enable ravana-osd.service

# Gesture plugin runtime libraries (the plugin itself is built in the Containerfile)
dnf5 install -y --setopt=install_weak_deps=False yaml-cpp libevdev || true

# Brightness for external monitors too (DDC/CI over the cable): KDE's brightness service
# uses ddcutil; i2c-dev gives it the monitor's control channel, ddcutil's udev rule the access
dnf5 install -y --setopt=install_weak_deps=False ddcutil || true
echo i2c-dev > /usr/lib/modules-load.d/ravana-ddc.conf

# Login screen: Ravana's own design needs a themable login manager. Plasma Login Manager
# compiles its design in, so Ravana uses SDDM (KDE's long-standing one) with the Ravana
# theme. If the theme ever failed to load, SDDM falls back to its built-in theme.
dnf5 install -y --setopt=install_weak_deps=False sddm sddm-wayland-plasma
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
# Bazzite's Steam Deck autologin helper writes SDDM files that log the first user in
# without a password, into a Game Mode session Ravana doesn't ship (and it overrides
# any other autologin setting). It was inert while Bazzite's login manager was in use;
# with SDDM back it would act, so it is switched off for good.
systemctl disable bazzite-autologin.service 2>/dev/null || true
systemctl mask bazzite-autologin.service
rm -f /etc/sddm.conf.d/zz-bazzite-autologin.conf /etc/sddm.conf.d/zz-holo-autologin.conf \
      /etc/sddm.conf.d/zz-steamos-autologin.conf /etc/sddm.conf.d/steamos.conf
ls -la /etc/systemd/system/display-manager.service

# Administrator password sheet: Ravana Shell is the Polkit agent. KDE's agent is switched
# off (only one agent can register); Ravana Shell starts it itself if its own can't register.
systemctl --global mask plasma-polkit-agent.service 2>/dev/null || true
for f in /etc/xdg/autostart/polkit-kde-authentication-agent-1.desktop; do
    [ -f "$f" ] && { grep -q '^Hidden=true' "$f" || echo 'Hidden=true' >> "$f"; }
done
ls /usr/libexec/kf6/polkit-kde-authentication-agent-1 /usr/libexec/polkit-kde-authentication-agent-1 2>/dev/null || true
