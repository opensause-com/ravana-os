#!/usr/bin/env bash
# Boot Ravana OS in QEMU with UEFI (needs /dev/kvm for usable speed).
#   scripts/run-vm.sh            # boots output/qcow2/disk.qcow2
#   scripts/run-vm.sh iso        # boots the installer ISO onto a fresh 64G disk
set -euo pipefail
cd "$(dirname "$0")/.."
VARS=output/OVMF_VARS.fd
[ -f "$VARS" ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"
COMMON=(-enable-kvm -cpu host -smp 4 -m 6G -machine q35
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
        -drive if=pflash,format=raw,file="$VARS"
        -device virtio-vga-gl -display gtk,gl=on
        -nic user,model=virtio-net-pci -device qemu-xhci -device usb-tablet)
if [ "${1:-}" = iso ]; then
    [ -f output/install-disk.qcow2 ] || qemu-img create -f qcow2 output/install-disk.qcow2 64G
    exec qemu-system-x86_64 "${COMMON[@]}" -cdrom output/bootiso/install.iso \
        -drive file=output/install-disk.qcow2,if=virtio -boot d
else
    exec qemu-system-x86_64 "${COMMON[@]}" -drive file=output/qcow2/disk.qcow2,if=virtio
fi
