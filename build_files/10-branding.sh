#!/usr/bin/env bash
# Rebrand Bazzite DX as Ravana OS. ID stays "bazzite" (ID_LIKE=fedora) so
# upstream ujust recipes and update tooling keep working.
set -euxo pipefail
: "${IMAGE_NAME:?}" "${IMAGE_VENDOR:?}" "${IMAGE_VERSION:?}"

OSR=/usr/lib/os-release
FEDORA_VER="$(. "$OSR"; echo "$VERSION_ID")"
setkv() { # setkv KEY VALUE  -> replace or append in os-release
    if grep -q "^$1=" "$OSR"; then sed -i "s|^$1=.*|$1=\"$2\"|" "$OSR"; else echo "$1=\"$2\"" >> "$OSR"; fi
}
setkv NAME        "Ravana OS"
setkv PRETTY_NAME "Ravana OS ${IMAGE_VERSION} (Fedora ${FEDORA_VER}, Bazzite DX)"
setkv VARIANT     "Gaming + Dev"
setkv VARIANT_ID  "${IMAGE_NAME}"
setkv IMAGE_VERSION "${IMAGE_VERSION}"
setkv DEFAULT_HOSTNAME "ravana"

# Image metadata read by Universal Blue tools (ujust, brh)
INFO=/usr/share/ublue-os/image-info.json
if [ -f "$INFO" ]; then
    sed -i 's|"image-name": [^,]*|"image-name": "'"$IMAGE_NAME"'"|' "$INFO"
    sed -i 's|"image-vendor": [^,]*|"image-vendor": "'"$IMAGE_VENDOR"'"|' "$INFO"
    # Unsigned until cosign signing is set up in CI
    sed -i 's|"image-ref": [^,]*|"image-ref": "ostree-unverified-registry:ghcr.io/'"$IMAGE_VENDOR/$IMAGE_NAME"'"|' "$INFO"
fi

# KDE "About this System"
ABOUT=/etc/xdg/kcm-about-distrorc
if [ -f "$ABOUT" ]; then
    sed -i "s|^Name=.*|Name=Ravana OS|; s|^Variant=.*|Variant=Gaming + Dev ${IMAGE_VERSION}|" "$ABOUT"
    grep -q '^Name=' "$ABOUT" || sed -i '/^\[General\]/a Name=Ravana OS' "$ABOUT"
fi
