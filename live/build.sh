#!/usr/bin/bash
# Ravana OS live ISO layer. Adapted from ublue-os/titanoboa examples/bazzite (Apache-2.0).

set -exo pipefail

{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; } 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# bwrap tries to write /proc/sys/user/max_user_namespaces which is mounted as ro
# so we need to remount it as rw
mount -o remount,rw /proc/sys

# Install flatpaks
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
xargs -r flatpak install -y --noninteractive <"$SCRIPT_DIR/flatpaks"

# Embed the OS the installer writes to disk, so installing needs no internet.
# It sits in the live system's container storage; mksquashfs stores files that are
# identical to the live system only once, so the ISO grows far less than the image size.
: "${RAVANA_IMAGE:?}" "${RAVANA_TAG:?}"
export RAVANA_IMAGE RAVANA_TAG
for i in 1 2 3; do
    podman pull "$RAVANA_IMAGE:$RAVANA_TAG" && break
    echo "pull failed, retrying ($i)"; sleep 10
done
podman images

# Fedora base repos for live-only packages (Bazzite ships without them)
cp "$SCRIPT_DIR/fedora-live.repo" /etc/yum.repos.d/fedora-live.repo

# Run the preinitramfs hook
"$SCRIPT_DIR/titanoboa_hook_preinitramfs.sh"

# Install dracut-live and regenerate the initramfs
dnf install -y dracut-live
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# Install livesys-scripts and configure them
dnf install -y livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=kde/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# Run the postrootfs hook
"$SCRIPT_DIR/titanoboa_hook_postrootfs.sh"

# image-builder needs gcdx64.efi
dnf install -y grub2-efi-x64-cdboot

# image-builder expects the EFI directory to be in /boot/efi
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/

# Remove fallback efi
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi # NOTE: remove this line if breaks bootloader

# needed for image-builder's buildroot
dnf install -y xorriso isomd5sum

# Set the timezone to UTC
rm -f /etc/localtime
systemd-firstboot --timezone UTC

# / in a booted live ISO is an overlayfs with upperdir pointed somewhere under /run
# This means that /var/tmp is also technically under /run.
# /run is of course a tmpfs, but set with quite a small size.
# ostree needs quite a lot of space on /var/tmp for temporary files so /run is not enough.
# Mount a larger tmpfs to /var/tmp at boot time to avoid this issue.
rm -rf /var/tmp || :
mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

# Copy in the iso config for image-builder
mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

# Clean up dnf cache to save space
dnf clean all || :

# The installer's /var/home step fails on this live system with
#   "Path '/mnt/sysroot/var/home' is not under root '/var/mnt/sysroot', refusing SELinux label fix"
# (systemd-tmpfiles exit code 73, which aborts the install). In the live system /mnt is a
# symlink to /var/mnt, the installer names the target root through the symlink, and
# systemd 262 now refuses that. Give tmpfiles the real path of --root. Live system only:
# the installed system's files come from the image, not from this layer. Done last so
# nothing above can put the original back.
mv /usr/bin/systemd-tmpfiles /usr/libexec/systemd-tmpfiles.real
cat > /usr/bin/systemd-tmpfiles <<'TMPF'
#!/bin/bash
args=()
for a in "$@"; do
    case "$a" in
        --root=*) args+=("--root=$(realpath -m -- "${a#--root=}")") ;;
        *) args+=("$a") ;;
    esac
done
exec /usr/libexec/systemd-tmpfiles.real "${args[@]}"
TMPF
chmod 0755 /usr/bin/systemd-tmpfiles
/usr/bin/systemd-tmpfiles --version | head -1
