#!/usr/bin/env bash
# Turn the Ravana OS container image into a bootable disk or installer ISO.
# bootc-image-builder needs rootful podman, so run this with sudo:
#   sudo scripts/build-disk.sh iso     # installer ISO -> output/bootiso/install.iso
#   sudo scripts/build-disk.sh qcow2   # VM disk for QEMU testing -> output/qcow2/disk.qcow2
set -euo pipefail
TYPE="${1:-iso}"
IMAGE="${IMAGE:-localhost/ravana-os:latest}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }
BUILD_USER="${SUDO_USER:?run via sudo from your normal user}"

# Copy the image from the user's rootless storage into root's storage.
echo ">> Copying $IMAGE from $BUILD_USER's podman storage to root's"
sudo -u "$BUILD_USER" podman save --format oci-archive "$IMAGE" | podman load

case "$TYPE" in
    iso)   BIB_TYPE=anaconda-iso; EXTRA=() ;;
    qcow2) BIB_TYPE=qcow2; EXTRA=(-v "$REPO/config/qcow2-test.toml:/config.toml:ro") ;;
    *) echo "Unknown type $TYPE (iso|qcow2)"; exit 1 ;;
esac

mkdir -p "$REPO/output"
podman run --rm -it --privileged --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "$REPO/output:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    "${EXTRA[@]}" \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type "$BIB_TYPE" --rootfs btrfs --use-librepo=True "$IMAGE"
chown -R "$BUILD_USER": "$REPO/output"
echo ">> Done: $(ls "$REPO"/output/*/*.{iso,qcow2} 2>/dev/null)"
