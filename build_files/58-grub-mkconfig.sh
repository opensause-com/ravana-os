#!/usr/bin/env bash
# Installing next to another Linux (an old EFI/ubuntu/grub.cfg on the disk) makes libostree run
# grub2-mkconfig inside the new deployment, where /sysroot is an empty, unmounted folder. Fedora's
# grub2-mkconfig probes /sysroot, grub2-probe fails, and the whole install aborts. Probe / when
# /sysroot is not a mount point.
set -euo pipefail
f=/usr/bin/grub2-mkconfig
[ -f "$f" ] || exit 0
sed -i 's|^GRUB_DEVICE="`${grub_probe} --target=device /sysroot`"$|if mountpoint -q /sysroot 2>/dev/null; then GRUB_DEVICE="`${grub_probe} --target=device /sysroot`"; else GRUB_DEVICE="`${grub_probe} --target=device /`"; fi|' "$f"
grep -n '^if mountpoint -q /sysroot' "$f" || echo "grub2-mkconfig: expected line not found, left as shipped"
bash -n "$f"
