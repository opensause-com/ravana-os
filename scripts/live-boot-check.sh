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
ISO="$1"; OUT="$2"; SECS="${3:-420}"
mkdir -p "$OUT"
PCAP="$OUT/capture.pcap"; MON="$OUT/monitor.sock"
OVMF="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd 2>/dev/null | head -1)"
[ -e /dev/kvm ] || { echo "no /dev/kvm on this machine: boot check skipped" | tee "$OUT/network.md"; exit 0; }
[ -n "$OVMF" ] || { echo "no OVMF firmware: boot check skipped" | tee "$OUT/network.md"; exit 0; }

qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 8192 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF" \
    -cdrom "$ISO" -boot d \
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
    -object filter-dump,id=f0,netdev=n0,file="$PCAP" \
    -vga std -display none -monitor "unix:$MON,server,nowait" \
    -serial "file:$OUT/serial.log" &
QEMU=$!
sleep "$SECS"

python3 - "$MON" "$OUT/live.ppm" <<'PY' || true
import socket, sys, time
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); time.sleep(0.5)
s.sendall(("screendump %s\n" % sys.argv[2]).encode()); time.sleep(3)
s.sendall(b"quit\n"); time.sleep(1)
PY
sleep 2; kill "$QEMU" 2>/dev/null; wait "$QEMU" 2>/dev/null
command -v convert >/dev/null && convert "$OUT/live.ppm" "$OUT/live.png" 2>/dev/null && rm -f "$OUT/live.ppm"

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
} > "$OUT/network.md" 2>&1
cat "$OUT/network.md"
