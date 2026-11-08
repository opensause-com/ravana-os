#!/usr/bin/env bash
# Rebuild the initramfs so the Ravana boot splash is used at boot.
set -euxo pipefail
KVER="$(rpm -q --queryformat='%{evr}.%{arch}' kernel | tail -1)"
/usr/bin/dracut --no-hostonly --kver "$KVER" --reproducible --zstd --add ostree \
    -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
