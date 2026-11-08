#!/usr/bin/env bash
# Remove or rename Bazzite-branded touchpoints users see.
set -euxo pipefail
# Terminal greeting with the Bazzite logo, launch announcement and portal popups
rm -f /etc/profile.d/bazzite-neofetch.sh \
      /etc/xdg/autostart/bazzite-announcement.desktop \
      /etc/skel/.config/autostart/bazzite-portal.desktop
# Terminal tips / message of the day
for f in /usr/share/ublue-os/motd/template.md /usr/share/ublue-os/motd/tips/*.md; do
    [ -f "$f" ] && sed -i 's/Bazzite/Ravana OS/g' "$f"
done
# Gaming news hook names the distro in notifications
[ -f /etc/gamemode-news-hook.conf ] && sed -i 's/Bazzite/Ravana OS/g' /etc/gamemode-news-hook.conf
grep -rIl 'Bazzite' /etc/xdg/autostart /etc/profile.d /usr/share/ublue-os/motd 2>/dev/null || echo "no Bazzite left in autostart/profile/motd"
