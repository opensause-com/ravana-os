#!/usr/bin/env bash
# Runs inside the Kubuntu system being remixed (chroot). Ravana's files are already copied in.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive LC_ALL=C

# --- package sources: the live image points apt at its own CD; use the real archive while building
ls -la /etc/apt/sources.list.d/ /etc/apt/sources.list 2>&1 || true
mkdir -p /root/apt-keep
for f in /etc/apt/sources.list.d/cdrom.sources /etc/apt/sources.list; do
    [ -f "$f" ] && mv "$f" "/root/apt-keep/$(basename "$f")"
done
if ! ls /etc/apt/sources.list.d/*.sources >/dev/null 2>&1; then
cat > /etc/apt/sources.list.d/ubuntu.sources <<'SRC'
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SRC
fi
for f in /etc/apt/sources.list.d/*.sources; do
    sed -i -E 's/^Components:.*/Components: main restricted universe multiverse/' "$f"
done
dpkg --add-architecture i386
apt-get update -qq

echo "steam steam/question select I AGREE" | debconf-set-selections
echo "steam steam/license note" | debconf-set-selections

optional() { for p in "$@"; do apt-get install -y -qq --no-install-recommends "$p" || echo "::warning::optional package $p not installed"; done; }

# --- what Ravana Shell needs
apt-get install -y -qq --no-install-recommends python3-dbus python3-gi fonts-inter os-prober ddcutil
xargs -a /tmp/quickshell-runtime-packages.txt apt-get install -y -qq --no-install-recommends

# --- gaming
apt-get install -y -qq steam-installer
optional gamemode mangohud gamescope vulkan-tools mesa-vulkan-drivers:i386 libvulkan1:i386 libgl1:i386 \
         protontricks lutris winetricks

# --- identity: the name changes, the ID stays "ubuntu" so Ubuntu tools keep working
for OSR in /usr/lib/os-release; do
    sed -i -E 's/^NAME=.*/NAME="Ravana OS"/; s/^PRETTY_NAME=.*/PRETTY_NAME="Ravana OS (Ubuntu 26.04 base)"/' "$OSR"
    grep -q '^LOGO=' "$OSR" && sed -i 's/^LOGO=.*/LOGO=ravana-os/' "$OSR" || echo 'LOGO=ravana-os' >> "$OSR"
done

# --- Ravana Shell: installed next to Plasma's own shell; a per-user setting picks one (default: classic Plasma)
test -x /usr/bin/quickshell
test -f /usr/share/ravana/shell/shell.qml
systemctl --global enable ravana-shell.service ravana-osd.service
rm -f /etc/xdg/autostart/ravana-look-update.desktop
test -x /usr/bin/ravana-ui && test -f /etc/ravana/ui
echo i2c-dev > /usr/lib/modules-load.d/ravana-ddc.conf
mkdir -p /etc/sddm.conf.d
# (the login theme only applies when the theme files are there)
if [ -f /usr/share/sddm/themes/ravana/Main.qml ]; then
cat > /etc/sddm.conf.d/10-ravana.conf <<'SDDM'
[Theme]
Current=ravana
CursorTheme=breeze_cursors
Font=Inter,10
SDDM
fi
bash /tmp/ravana-build/55-ravana-shell-config.sh || true
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBox --key LayoutName org.kde.breeze.desktop
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBox --key ApplicationsMode 0
kwriteconfig6 --file /etc/xdg/kwinrc --group TabBoxAlternative --key LayoutName org.kde.breeze.desktop

# --- installing next to another Linux
# Own boot-loader folder on the shared EFI partition (Kubuntu's default "ubuntu" would collide with
# an existing Ubuntu's), and GRUB lists the other systems it finds.
sed -i 's/^efiBootloaderId:.*/efiBootloaderId: "ravana"/' /etc/calamares/modules/bootloader.conf
mkdir -p /etc/default/grub.d
cat > /etc/default/grub.d/90-ravana.cfg <<'GRUBD'
GRUB_DISABLE_OS_PROBER=false
GRUB_DISTRIBUTOR="Ravana OS"
GRUBD

# --- tidy
[ -f /root/apt-keep/cdrom.sources ] && mv /root/apt-keep/cdrom.sources /etc/apt/sources.list.d/cdrom.sources
[ -f /root/apt-keep/sources.list ] && mv /root/apt-keep/sources.list /etc/apt/sources.list
rm -rf /root/apt-keep
apt-get clean
rm -f /quickshell-runtime-packages.txt
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
