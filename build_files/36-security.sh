#!/usr/bin/env bash
# Security defaults that keep gaming and development working.
# (Kernel/network settings: usr/lib/sysctl.d/60-ravana-hardening.conf,
#  Wi-Fi privacy: etc/NetworkManager/conf.d, encrypted DNS: resolved.conf.d)
set -euxo pipefail

# --- Firewall: block incoming connections, allow only what a desktop needs ---
if command -v firewall-offline-cmd >/dev/null; then
    systemctl enable firewalld.service
    firewall-offline-cmd --set-default-zone=public
    for svc in ssh cockpit samba-client; do
        firewall-offline-cmd --zone=public --remove-service="$svc" 2>/dev/null || true
    done
    # DHCPv6, local name discovery (printers, casting), Steam Remote Play / LAN transfers
    for svc in dhcpv6-client mdns steam-streaming; do
        firewall-offline-cmd --zone=public --add-service="$svc" 2>/dev/null || true
    done
    firewall-offline-cmd --zone=public --list-all
else
    echo "WARNING: firewalld not found"
fi

# --- No remote login or remote printer discovery unless the user turns them on ---
for unit in sshd.service sshd.socket cups-browsed.service cockpit.socket cockpit.service; do
    systemctl disable "$unit" 2>/dev/null || true
done

# --- Lock the account for 2 minutes after 10 wrong passwords (slows guessing) ---
if command -v authselect >/dev/null && authselect current >/dev/null 2>&1; then
    authselect enable-feature with-faillock || echo "WARNING: faillock not enabled"
    sed -i 's/^#\? *deny *=.*/deny = 10/; s/^#\? *unlock_time *=.*/unlock_time = 120/' /etc/security/faillock.conf
    grep -E '^(deny|unlock_time)' /etc/security/faillock.conf
fi

# --- Lock the screen when waking from sleep ---
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Daemon --key LockOnResume true
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Daemon --key Autolock true
kwriteconfig6 --file /etc/xdg/kscreenlockerrc --group Daemon --key Timeout 10

# --- Firmware security updates (BIOS, SSD, peripherals) through fwupd ---
systemctl enable fwupd-refresh.timer 2>/dev/null || true

# --- Sanity: SELinux stays enforcing ---
grep -q '^SELINUX=enforcing' /etc/selinux/config
