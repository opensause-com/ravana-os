#!/usr/bin/env bash
# Remix the official Kubuntu ISO: add Ravana's files, Quickshell and the gaming stack to its system,
# then rebuild the ISO with the same boot setup.
# Usage (root): remix.sh <kubuntu.iso> <quickshell.tar.gz> <out.iso>
set -euxo pipefail
SRC_ISO="$(realpath "$1")"; QS="$(realpath "$2")"; OUT="$(realpath -m "$3")"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
W="${WORKDIR:-/mnt/remix}"; mkdir -p "$W"; cd "$W"

# 1. unpack the ISO and its system
xorriso -osirrox on -indev "$SRC_ISO" -extract / iso >/dev/null 2>&1
chmod -R u+w iso
unsquashfs -f -d rootfs iso/casper/filesystem.squashfs >/dev/null

# 2. Ravana's files (whitelist: the Fedora image's other files do not apply here)
OV="$REPO/system_files"
cp_into() { [ -e "$OV/$1" ] && { mkdir -p "rootfs/$(dirname "${2:-$1}")"; cp -a "$OV/$1" "rootfs/${2:-$1}"; } || echo "missing in overlay: $1"; }
for d in usr/share/ravana usr/share/sddm usr/share/wallpapers usr/share/plymouth usr/share/icons usr/share/kwin \
         usr/share/kglobalaccel usr/share/aurorae usr/share/color-schemes usr/share/konsole usr/share/plasma \
         usr/share/applications usr/share/sounds usr/share/pixmaps etc/ravana; do cp_into "$d"; done
mkdir -p rootfs/usr/lib/x86_64-linux-gnu/qt6/qml/org
cp -a "$OV/usr/lib64/qt6/qml/org/ravana" rootfs/usr/lib/x86_64-linux-gnu/qt6/qml/org/
for f in usr/bin/ravana-settings usr/bin/ravana-ui usr/libexec/ravana-ui-enabled usr/libexec/ravana-osd \
         etc/xdg/autostart/ravana-setup.desktop; do cp_into "$f"; done
for f in ravana-shell.service ravana-osd.service; do cp_into "usr/lib/systemd/user/$f"; done
for d in ravana-shell.service.d ravana-osd.service.d plasma-plasmashell.service.d plasma-polkit-agent.service.d; do
    cp_into "usr/lib/systemd/user/$d"; done
tar -C rootfs -xzf "$QS"                       # Quickshell, built for this release
mkdir -p rootfs/tmp/ravana-build
cp "$REPO"/build_files/55-ravana-shell-config.sh rootfs/tmp/ravana-build/
tar -xzOf "$QS" ./quickshell-runtime-packages.txt > rootfs/tmp/quickshell-runtime-packages.txt
cp "$REPO/kubuntu/chroot-setup.sh" rootfs/tmp/chroot-setup.sh

# 3. run the setup inside the system
mount --bind /dev rootfs/dev; mount -t proc proc rootfs/proc; mount -t sysfs sys rootfs/sys; mount --bind /run rootfs/run
cp /etc/resolv.conf rootfs/etc/resolv.conf.host; mv rootfs/etc/resolv.conf rootfs/etc/resolv.conf.orig 2>/dev/null || true
cp /etc/resolv.conf rootfs/etc/resolv.conf
trap 'umount -R rootfs/dev rootfs/proc rootfs/sys rootfs/run 2>/dev/null || true' EXIT
chroot rootfs bash /tmp/chroot-setup.sh
umount -R rootfs/dev rootfs/proc rootfs/sys rootfs/run; trap - EXIT
rm -f rootfs/etc/resolv.conf rootfs/etc/resolv.conf.host
[ -e rootfs/etc/resolv.conf.orig ] && mv rootfs/etc/resolv.conf.orig rootfs/etc/resolv.conf || ln -s ../run/systemd/resolve/stub-resolv.conf rootfs/etc/resolv.conf
rm -rf rootfs/tmp/*

# 4. pack the system again
mksquashfs rootfs new.squashfs -comp xz -b 1M -Xbcj x86 -noappend -no-progress
cp new.squashfs iso/casper/filesystem.squashfs
printf '%s' "$(du -sx --block-size=1 rootfs | cut -f1)" > iso/casper/filesystem.size 2>/dev/null || true
( cd iso && find . -type f ! -name md5sum.txt ! -path './boot.catalog' -print0 | xargs -0 md5sum > md5sum.txt ) || true

# 5. rebuild the ISO with the original's boot setup (BIOS + UEFI, hybrid)
dd if="$SRC_ISO" of=mbr.bin bs=1 count=432 status=none
EFI_START=$(xorriso -indev "$SRC_ISO" -report_el_torito as_mkisofs 2>/dev/null | sed -n "s/.*appended_partition_2_start_\([0-9]*\)s_size_\([0-9]*\)d.*/\1 \2/p" | head -1)
read -r ES EZ <<< "$EFI_START"
dd if="$SRC_ISO" of=efi.img bs=512 skip=$((ES * 4)) count="$EZ" status=none
LABEL="$(xorriso -indev "$SRC_ISO" -pvd_info 2>/dev/null | sed -n 's/^Volume Id *: *//p' | head -1)"
xorriso -as mkisofs -r -V "$LABEL" -o "$OUT" -J -joliet-long -cache-inodes \
    --grub2-mbr mbr.bin --protective-msdos-label -partition_offset 16 -partition_cyl_align off \
    --mbr-force-bootable -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b efi.img -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c /boot.catalog -b /boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot -e '--interval:appended_partition_2:all::' -no-emul-boot \
    iso
ls -lh "$OUT"
