#!/usr/bin/env bash
# Keep Launchpad and Spotlight clean, like macOS: hide developer/diagnostic tools,
# duplicates and leftover Bazzite links. Hidden apps stay installed and runnable.
set -euxo pipefail
HIDE=(
    "KDebugSettings" "Menu Editor" "Journald Browser" "KWalletManager"
    "KRDC" "Krfb" "KDE Connect SMS" "KWrite" "KFind"
    "Nested Desktop" "Nested Steam Gamemode" "Force Restart Waydroid"
    "Bazzite Updater" "Discourse" "Documentation" "Bold Brew"
    "Kvantum Manager"
)
for f in /usr/share/applications/*.desktop; do
    name="$(sed -n 's/^Name=//p' "$f" | head -1)"
    for h in "${HIDE[@]}"; do
        if [ "$name" = "$h" ] || { [[ "$h" == Nested* ]] && [[ "$name" == Nested* ]]; }; then
            sed -i '/^NoDisplay=/d' "$f"
            sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' "$f"
            echo "Hidden: $name ($(basename "$f"))"
        fi
    done
done
