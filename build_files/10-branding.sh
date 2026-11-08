#!/usr/bin/env bash
# Rebrand Bazzite DX as Ravana OS. ID stays "bazzite" (ID_LIKE=fedora) so
# upstream ujust recipes and update tooling keep working.
set -euxo pipefail
: "${IMAGE_NAME:?}" "${IMAGE_VENDOR:?}" "${IMAGE_VERSION:?}"
FLAVOR="${IMAGE_FLAVOR:-main}"
if [ "$FLAVOR" = dx ]; then EDITION="Gaming + Developer"; else EDITION="Gaming"; fi

OSR=/usr/lib/os-release
FEDORA_VER="$(. "$OSR"; echo "$VERSION_ID")"
setkv() { # setkv KEY VALUE  -> replace or append in os-release
    if grep -q "^$1=" "$OSR"; then sed -i "s|^$1=.*|$1=\"$2\"|" "$OSR"; else echo "$1=\"$2\"" >> "$OSR"; fi
}
setkv NAME        "Ravana OS"
setkv PRETTY_NAME "Ravana OS ${IMAGE_VERSION}"
setkv VARIANT     "$EDITION"
setkv VARIANT_ID  "${IMAGE_NAME}"
setkv IMAGE_VERSION "${IMAGE_VERSION}"
setkv DEFAULT_HOSTNAME "ravana"
setkv ANSI_COLOR "0;38;2;210;31;60"
setkv LOGO "ravana-os"
setkv HOME_URL "https://github.com/ravana-os/ravana-os"
setkv DOCUMENTATION_URL "https://github.com/ravana-os/ravana-os#readme"
setkv SUPPORT_URL "https://github.com/ravana-os/ravana-os/discussions"
setkv BUG_REPORT_URL "https://github.com/ravana-os/ravana-os/issues"
# Shown in the boot menu
BUILD="$(. "$OSR"; echo "${OSTREE_VERSION:-$FEDORA_VER}")"
setkv BOOTLOADER_NAME "Ravana OS ${IMAGE_VERSION} (${BUILD})"

# Image metadata read by Universal Blue tools (ujust, brh)
INFO=/usr/share/ublue-os/image-info.json
if [ -f "$INFO" ]; then
    sed -i 's|"image-name": [^,]*|"image-name": "'"$IMAGE_NAME"'"|' "$INFO"
    sed -i 's|"image-vendor": [^,]*|"image-vendor": "'"$IMAGE_VENDOR"'"|' "$INFO"
    # Signed with the Ravana key (see 35-signing.sh)
    sed -i 's|"image-ref": [^,]*|"image-ref": "ostree-image-signed:docker://ghcr.io/'"$IMAGE_VENDOR/$IMAGE_NAME"'"|' "$INFO"
fi

# KDE "About this System"
ABOUT=/etc/xdg/kcm-about-distrorc
if [ -f "$ABOUT" ]; then
    sed -i "s|^Name=.*|Name=Ravana OS|; s|^Variant=.*|Variant=${EDITION}|; s|^Website=.*|Website=https://github.com/ravana-os/ravana-os|" "$ABOUT"
    grep -q '^Name=' "$ABOUT" || sed -i '/^\[General\]/a Name=Ravana OS' "$ABOUT"
    # Show Ravana's version, not Fedora's (os-release keeps Fedora's for tools)
    sed -i '/^Version=/d; /^UseOSReleaseVersion=/d' "$ABOUT"
    sed -i "/^\[General\]/a Version=${IMAGE_VERSION}" "$ABOUT"
    grep -q '^Variant=' "$ABOUT" || sed -i "/^\[General\]/a Variant=${EDITION}" "$ABOUT"
    if grep -q '^LogoPath=' "$ABOUT"; then
        sed -i 's|^LogoPath=.*|LogoPath=/usr/share/pixmaps/ravana-os.png|' "$ABOUT"
    else
        sed -i '/^\[General\]/a LogoPath=/usr/share/pixmaps/ravana-os.png' "$ABOUT"
    fi
    cat "$ABOUT"
fi
