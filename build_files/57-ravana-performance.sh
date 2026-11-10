#!/usr/bin/env bash
# Ravana OS performance: less RAM and CPU in the background, faster network and login.
# Nothing here touches security settings or how games run.
set -euxo pipefail
KW="$(command -v kwriteconfig6)"

# File search: index file names only (Spotlight finds files), not their contents, which
# costs a lot of RAM and CPU on big home folders and game libraries
cat > /etc/xdg/baloofilerc <<'BALOO'
[General]
only basic indexing=true
exclude folders[$e]=$HOME/.local/share/Steam/,$HOME/.var/app/,$HOME/.cache/,$HOME/Games/
BALOO

# KDE background modules Ravana doesn't use (each one is RAM in every session)
for m in donationmessage browserintegrationreminder remotenotifier smbwatcher wpad_detector \
         kded_accounts plasma_accentcolor_service kameleon lookandfeelautoswitcher plasmavault; do
    $KW --file /etc/xdg/kded6rc --group "Module-$m" --key autoload false
done

# Autostart helpers Ravana replaces (updates come from Ravana's own updater)
for f in org.kde.discover.notifier.desktop org.kde.plasma-welcome.desktop; do
    a="/etc/xdg/autostart/$f"
    [ -f "$a" ] && { grep -q '^Hidden=true' "$a" || echo 'Hidden=true' >> "$a"; }
done

# Crash-report collectors (Fedora's ABRT) cost RAM and CPU after every crash; Ravana
# doesn't send crash reports
for unit in abrtd.service abrt-journal-core.service abrt-oops.service abrt-xorg.service \
            abrt-vmcore.service abrt-pstoreoops.service; do
    systemctl disable "$unit" 2>/dev/null || true
done

# Network module for BBR (loaded at boot; sysctl selects it)
test -f /usr/lib/modules-load.d/ravana-bbr.conf
test -f /usr/lib/sysctl.d/62-ravana-performance.conf
