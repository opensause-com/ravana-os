#!/usr/bin/env bash
# Ravana boot splash: Fedora's "spinner" Plymouth theme with the Ravana crown.
set -euxo pipefail
echo "Current Plymouth theme: $(plymouth-set-default-theme 2>/dev/null || echo unknown)"
THEME=/usr/share/plymouth/themes/spinner
if [ ! -d "$THEME" ]; then
    echo "spinner theme not present; leaving boot splash unchanged"
    exit 0
fi
install -m 0644 /usr/share/ravana/plymouth-watermark.png "$THEME/watermark.png"
plymouth-set-default-theme spinner
