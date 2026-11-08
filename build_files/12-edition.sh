#!/usr/bin/env bash
# Edition setup. Both editions start from Bazzite DX. The main edition removes the
# developer stack; "Get Developer Tools" switches to the Developer edition, which
# shares the rest of the image, so only the difference is downloaded.
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

SIZE_BEFORE=$(du -sxm /usr | cut -f1)
DEV=(
    # Editor
    code
    # Docker (Podman + Distrobox stay)
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # Virtual machines
    qemu qemu-kvm qemu-kvm-core libvirt libvirt-daemon-kvm virt-manager virt-viewer
    edk2-ovmf guestfs-tools libguestfs incus incus-agent
    # ROCm GPU compute
    rocm-hip rocm-opencl rocm-clinfo rocm-smi hipcc rocm-llvm rocm-llvm-devel
    rocm-llvm-static rocm-llvm-libs rocm-comgr rocm-device-libs rocm-runtime
    # Profilers and dev utilities
    bcc bpftrace bpftop sysprof tiptop nicstat numactl flatpak-builder
    python3-ramalama android-tools podman-machine
)
PRESENT=()
for p in "${DEV[@]}"; do rpm -q "$p" >/dev/null 2>&1 && PRESENT+=("$p"); done
echo "Removing developer stack: ${PRESENT[*]}"
dnf5 remove -y --disablerepo='*' "${PRESENT[@]}"

# Services/sockets that belonged to the removed tools
for unit in docker.socket docker.service incus-workaround.service virtqemud.service \
            bazzite-dx-groups.service; do
    systemctl disable "$unit" 2>/dev/null || true
done
rm -f /etc/yum.repos.d/docker-ce.repo /etc/yum.repos.d/config.repo   # docker / vscode repos

echo "Developer stack removed: /usr ${SIZE_BEFORE} MB -> $(du -sxm /usr | cut -f1) MB"
