#!/usr/bin/env bash
# Boot the live ISO in a virtual machine and record what it does on the network.
#
# Usage: scripts/live-boot-check.sh <iso> <out-dir> [seconds]
#
# The live USB installs from itself, so an idle live session should use next to no
# data. This boots the ISO with internet access, leaves it alone, and writes:
#   <out>/network.md    total data used and every server it talked to
#   <out>/live.png      what was on screen at the end (did it reach the desktop?)
#   <out>/capture.pcap  the raw capture
# Needs: qemu-system-x86_64, OVMF, tshark, python3, /dev/kvm.
set -uo pipefail
if [ "${1:-}" = "--install-tools" ]; then   # on a CI machine (Ubuntu); retried, mirrors can hiccup
    for i in 1 2 3 4; do
        sudo apt-get update -qq >/dev/null 2>&1
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qemu-system-x86 qemu-utils ovmf tshark imagemagick xorriso >/dev/null && break
        echo "tool install failed, retrying ($i)"; sleep 20
    done
    sudo chmod 666 /dev/kvm 2>/dev/null || true
    command -v qemu-system-x86_64 tshark xorriso
    exit $?
fi
ISO="$1"; OUT="$2"; SECS="${3:-420}"
mkdir -p "$OUT"
PCAP="$OUT/capture.pcap"; MON="$OUT/monitor.sock"
OVMF="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd 2>/dev/null | head -1)"
[ -e /dev/kvm ] || { echo "no /dev/kvm on this machine: boot check skipped" | tee "$OUT/network.md"; exit 0; }
[ -n "$OVMF" ] || { echo "no OVMF firmware: boot check skipped" | tee "$OUT/network.md"; exit 0; }

# Boot the ISO's own kernel directly so the system log can be sent to a file (serial.log)
KARGS=()
if command -v xorriso >/dev/null \
   && xorriso -osirrox on -indev "$ISO" -extract /images/pxeboot/vmlinuz "$OUT/vmlinuz" -extract /images/pxeboot/initrd.img "$OUT/initrd.img" >/dev/null 2>&1; then
    LABEL="$(xorriso -indev "$ISO" -pvd_info 2>/dev/null | sed -n 's/^Volume Id *: *//p' | head -1)"
    chmod u+rw "$OUT/vmlinuz" "$OUT/initrd.img"
    KARGS=(-kernel "$OUT/vmlinuz" -initrd "$OUT/initrd.img" -append
           "root=live:CDLABEL=${LABEL:-RAVANA-OS} rd.live.image enforcing=0 console=tty0 console=ttyS0,115200 systemd.journald.forward_to_console=1 systemd.show_status=0 plymouth.enable=0")
fi

qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 8192 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF" \
    -cdrom "$ISO" -boot d "${KARGS[@]}" \
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
    -object filter-dump,id=f0,netdev=n0,file="$PCAP" \
    -vga std -display none -monitor "unix:$MON,server,nowait" \
    -serial "file:$OUT/serial.log" &
QEMU=$!
shot() {   # screenshot of the VM's screen: shot <name>
    python3 - "$MON" "$OUT/$1.ppm" <<'PY' || true
import socket, sys, time
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); time.sleep(0.5)
s.sendall(("screendump %s\n" % sys.argv[2]).encode()); time.sleep(3)
PY
    command -v convert >/dev/null && convert "$OUT/$1.ppm" "$OUT/$1.png" 2>/dev/null
}
# three looks at the screen: early, middle and end (shows a desktop that came up and went away)
sleep $(( SECS / 3 )); shot live-1
sleep $(( SECS / 3 )); shot live-2
sleep $(( SECS / 3 )); shot live
kill "$QEMU" 2>/dev/null; wait "$QEMU" 2>/dev/null
# raw screen dumps and the extracted kernel are not needed in the results
find "${OUT:?}" -maxdepth 1 \( -name '*.ppm' -o -name vmlinuz -o -name initrd.img \) -delete
# the parts of the system log about logging in and starting the desktop
tr -d '\000\r' < "$OUT/serial.log" 2>/dev/null | sed 's/\x1b\[[0-9;]*[A-Za-z]//g' \
    | grep -a -i -E 'sddm|autologin|pam_|livesys|liveuser|startplasma|kwin_wayland|quickshell|ravana-shell|plasma-workspace|session (opened|closed)|Failed|failed|segfault|dumped core' \
    | tail -150 > "$OUT/login-log.txt" || true

{
    echo "### Live session network use (idle for ${SECS}s after power-on)"
    echo
    if [ ! -s "$PCAP" ]; then echo "No capture was written."; exit 0; fi
    # everything that is not the VM's own local network (10.0.2.x is QEMU's built-in router)
    BYTES=$(tshark -r "$PCAP" -Y 'ip && !(ip.src==10.0.2.0/24 && ip.dst==10.0.2.0/24)' -T fields -e frame.len 2>/dev/null | awk '{s+=$1} END {printf "%d", s}')
    echo "Total data to and from the internet: **$(awk -v b="${BYTES:-0}" 'BEGIN {printf "%.2f MB", b/1e6}')**"
    echo
    echo "Servers contacted (encrypted connections, by name):"
    echo '```'
    tshark -r "$PCAP" -Y 'tls.handshake.extensions_server_name' -T fields -e tls.handshake.extensions_server_name 2>/dev/null | sort | uniq -c | sort -rn | head -40
    echo '```'
    echo "Names looked up:"
    echo '```'
    tshark -r "$PCAP" -Y 'dns.flags.response == 0' -T fields -e dns.qry.name 2>/dev/null | sort | uniq -c | sort -rn | head -40
    echo '```'
    echo "Data by remote address (bytes):"
    echo '```'
    tshark -r "$PCAP" -Y 'ip' -T fields -e ip.src -e ip.dst -e frame.len 2>/dev/null \
        | awk '{r = ($1 ~ /^10\.0\.2\./) ? $2 : $1; if (r !~ /^10\.0\.2\./) b[r] += $3} END {for (r in b) printf "%12d  %s\n", b[r], r}' | sort -rn | head -20
    echo '```'
    echo "Login and desktop start (from the system log, last lines):"
    echo '```'
    tail -60 "$OUT/login-log.txt" 2>/dev/null | cut -c1-220
    echo '```'
} > "$OUT/network.md" 2>&1
cat "$OUT/network.md"
