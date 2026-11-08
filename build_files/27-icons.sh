#!/usr/bin/env bash
# Colloid icons (modern, rounded; GPL-3.0, github.com/vinceliuice/Colloid-icon-theme),
# pinned and checksum-verified, with folders recoloured to Ravana red.
# Papirus-Dark fills in apps Colloid doesn't cover.
set -euxo pipefail
VER=2026-08-10
SHA=367c3ce3ab85721e41ca9aa4fccd1761ec236d1b8cd7daf65f5e9ec88c1a8a15
curl -fsSL -o /tmp/colloid.tar.gz "https://github.com/vinceliuice/Colloid-icon-theme/archive/refs/tags/${VER}.tar.gz"
echo "${SHA}  /tmp/colloid.tar.gz" | sha256sum -c -
tar xzf /tmp/colloid.tar.gz -C /tmp
cd "/tmp/Colloid-icon-theme-${VER}"
sed -i "s/theme_color='#F44336'/theme_color='#D21F3C'/" install.sh
./install.sh -d /usr/share/icons -t red >/dev/null
THEME=/usr/share/icons/Colloid-Red-Dark
test -f "$THEME/index.theme"
sed -i 's/^Inherits=.*/Inherits=Papirus-Dark,breeze-dark,hicolor/' "$THEME/index.theme"
grep -E '^(Name|Inherits)=' "$THEME/index.theme"
install -Dm644 LICENSE /usr/share/licenses/colloid-icon-theme/LICENSE
gtk-update-icon-cache -f "$THEME" || true
rm -rf "/tmp/Colloid-icon-theme-${VER}" /tmp/colloid.tar.gz
