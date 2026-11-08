#!/usr/bin/env bash
# Runs inside the throwaway ISO payload image (see .github/workflows/build-iso.yml).
# Bazzite ships without the Fedora base repos and keys; bootc-image-builder needs
# both to resolve and verify the installer's packages.
set -euo pipefail
VER="$(rpm -E %fedora)"
ARCH="$(uname -m)"
KEYDIR=/etc/pki/rpm-gpg
KEY="$KEYDIR/RPM-GPG-KEY-fedora-$VER-$ARCH"
mkdir -p "$KEYDIR"

echo "Fedora $VER/$ARCH; packages: $(rpm -q fedora-gpg-keys fedora-repos 2>&1 | tr '\n' ' ')"
if [ ! -s "$KEY" ]; then
    SRC="$(find /usr /etc -name "RPM-GPG-KEY-fedora-$VER-primary" 2>/dev/null | head -1)"
    if [ -n "$SRC" ]; then
        echo "Using key from image: $SRC"
        cp "$SRC" "$KEY"
    else
        URL="https://src.fedoraproject.org/rpms/fedora-repos/raw/f$VER/f/RPM-GPG-KEY-fedora-$VER-primary"
        echo "Fetching key: $URL"
        curl -fsSL --retry 3 "$URL" -o "$KEY"
    fi
fi
grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$KEY"
cp /var/tmp/fedora-base.repo /etc/yum.repos.d/fedora-base.repo
echo "Fedora repos and key ready: $KEY"
