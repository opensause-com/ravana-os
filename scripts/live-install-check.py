#!/usr/bin/env python3
"""Install the live ISO onto a blank virtual disk the way a user would, then boot it.

Usage: live-install-check.py <iso> <out-dir>

  1. boots the ISO in a VM (UEFI, internet access, a blank 64 GB disk),
  2. logs in on the serial console as the live user,
  3. runs the real Anaconda installer with a complete kickstart that includes the
     installer defaults baked into the ISO (so Ravana's own profile, offline image
     source and post-install scripts are what runs),
  4. boots the installed system from the disk and looks at it.

Everything is recorded: the installer's own logs, what the network carried (servers and
bytes) during the install and during the first boot, and screenshots of the first boot.
Needs: qemu-system-x86_64, qemu-img, OVMF, tshark, imagemagick (convert), xorriso, /dev/kvm.
"""
import os, pathlib, re, shutil, socket, subprocess, sys, time

ISO = os.path.abspath(sys.argv[1])
OUT = pathlib.Path(sys.argv[2]).resolve(); OUT.mkdir(parents=True, exist_ok=True)
RAM = os.environ.get("INSTALL_RAM_MB", "10240")
INSTALL_TIMEOUT = int(os.environ.get("INSTALL_TIMEOUT", "4500"))
FIRSTBOOT_SECS = int(os.environ.get("FIRSTBOOT_SECS", "300"))
REPORT = []


def say(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def run(cmd, **kw):
    return subprocess.run(cmd, text=True, capture_output=True, **kw)


def find_workdir():
    for base in (os.environ.get("INSTALL_WORKDIR"), "/mnt/install-check", str(OUT / "work")):
        if not base:
            continue
        try:
            run(["sudo", "mkdir", "-p", base]); run(["sudo", "chown", f"{os.getuid()}:{os.getgid()}", base])
            p = pathlib.Path(base)
            if os.access(p, os.W_OK):
                return p
        except Exception:
            pass
    raise SystemExit("no writable work folder")


WORK = find_workdir()
CODE = next((p for p in ("/usr/share/OVMF/OVMF_CODE_4M.fd", "/usr/share/OVMF/OVMF_CODE.fd") if os.path.exists(p)), None)
VARS_SRC = next((p for p in ("/usr/share/OVMF/OVMF_VARS_4M.fd", "/usr/share/OVMF/OVMF_VARS.fd") if os.path.exists(p)), None)
if not (os.path.exists("/dev/kvm") and CODE and VARS_SRC):
    msg = "no /dev/kvm or no OVMF firmware on this machine: install check skipped"
    say(msg); (OUT / "report.md").write_text(msg + "\n"); sys.exit(0)

DISK = WORK / "disk.qcow2"
VARS = WORK / "vars.fd"
shutil.copy(VARS_SRC, VARS)
run(["qemu-img", "create", "-f", "qcow2", str(DISK), "64G"], check=True)

# ---------------------------------------------------------------- what runs inside the live system
KS = r"""# complete kickstart for an unattended test install
%include /usr/share/anaconda/interactive-defaults.ks
lang en_US.UTF-8
keyboard us
timezone UTC --utc
rootpw --lock
user --name=tester --password=tester --plaintext --groups=wheel
ignoredisk --only-use=vda
zerombr
clearpart --all --initlabel --drives=vda
autopart --type=btrfs
bootloader --location=mbr --boot-drive=vda
shutdown
"""
RUN_SH = r"""#!/bin/bash
set -x
cp /mnt/cfg/ks.cfg /tmp/ks.cfg
echo "== live system"; free -m; df -h / /var/tmp; lsblk
grep -E '^(ID|VARIANT_ID|PRETTY_NAME)=' /etc/os-release
ls /etc/anaconda/profile.d/
podman images
echo "== starting the installer"
yes '' | timeout 4200 anaconda --liveinst --cmdline --kickstart /tmp/ks.cfg > /tmp/anaconda-stdout.log 2>&1
rc=$?
echo "ANACONDA-EXIT $rc"
set +x
echo "== installer output (last 80 lines)"; tail -n 80 /tmp/anaconda-stdout.log
for f in /tmp/anaconda.log /tmp/program.log /tmp/storage.log /tmp/packaging.log /tmp/syslog /tmp/anacoda_custom_logs/*; do
  [ -f "$f" ] || continue
  echo "== $f (last 120 lines)"; tail -n 120 "$f"
done
echo "== errors anywhere in the installer logs"
grep -h -i -E 'error|traceback|failed|exception' /tmp/anaconda.log /tmp/program.log /tmp/storage.log 2>/dev/null | tail -n 60
sync
exit $rc
"""


class Console:
    """The VM's serial console over a unix socket."""

    def __init__(self, path, logfile):
        self.buf = ""
        self.log = open(logfile, "a")
        self.s = socket.socket(socket.AF_UNIX)
        for _ in range(120):
            try:
                self.s.connect(path); break
            except OSError:
                time.sleep(0.5)
        else:
            raise SystemExit("could not connect to the VM's serial console")

    def _read(self, timeout):
        self.s.settimeout(timeout)
        try:
            d = self.s.recv(65536)
        except socket.timeout:
            return False
        if not d:
            raise EOFError("console closed")
        t = d.decode(errors="replace")
        self.buf += t; self.log.write(t); self.log.flush()
        self.buf = self.buf[-200000:]
        return True

    def wait(self, pattern, timeout, beat=None):
        rx = re.compile(pattern); end = time.time() + timeout; last = time.time()
        while time.time() < end:
            m = rx.search(self.buf)
            if m:
                self.buf = self.buf[m.end():]
                return m
            try:
                self._read(min(5, max(0.1, end - time.time())))
            except EOFError:
                return None
            if beat and time.time() - last > 300:
                last = time.time(); say(beat)
        return None

    def send(self, text):
        self.s.sendall(text.encode())


def monitor_shot(sock_path, png):
    ppm = str(png) + ".ppm"
    try:
        s = socket.socket(socket.AF_UNIX); s.connect(sock_path); time.sleep(0.5)
        s.sendall(f"screendump {ppm}\n".encode()); time.sleep(3); s.close()
        run(["convert", ppm, str(png)])
    except Exception as e:
        say(f"screenshot failed: {e}")
    pathlib.Path(ppm).unlink(missing_ok=True)


def qemu(phase, with_iso, extra=()):
    mon = str(WORK / f"{phase}.mon"); ser = str(WORK / f"{phase}.ser")
    for p in (mon, ser):
        pathlib.Path(p).unlink(missing_ok=True)
    cmd = ["qemu-system-x86_64", "-enable-kvm", "-cpu", "host", "-smp", "4", "-m", RAM,
           "-drive", f"if=pflash,format=raw,readonly=on,file={CODE}",
           "-drive", f"if=pflash,format=raw,file={VARS}",
           # every disk is an explicit virtio device, created in this order: the target disk is
           # always vda, then (install phase only) the config disk and the ISO itself
           "-drive", f"if=none,id=target,file={DISK},format=qcow2,cache=unsafe",
           "-device", "virtio-blk-pci,drive=target,bootindex=1",
           "-netdev", "user,id=n0", "-device", "virtio-net-pci,netdev=n0",
           "-object", f"filter-dump,id=f0,netdev=n0,file={OUT}/{phase}.pcap",
           "-vga", "std", "-display", "none", "-monitor", f"unix:{mon},server,nowait",
           "-serial", f"unix:{ser},server=on,wait=off"]
    if with_iso:
        # The live system finds its ISO by label on whatever block device holds it, and the
        # kickstart/script disk by the label CIDATA (IDE CD drives were not detected in CI).
        cmd += ["-drive", f"if=none,id=cfg,file={WORK}/cfg.iso,format=raw,readonly=on",
                "-device", "virtio-blk-pci,drive=cfg",
                "-drive", f"if=none,id=iso,file={ISO},format=raw,readonly=on",
                "-device", "virtio-blk-pci,drive=iso", *extra]
    p = subprocess.Popen(cmd)
    return p, mon, ser


def net_summary(pcap, title):
    if not pathlib.Path(pcap).exists() or pathlib.Path(pcap).stat().st_size == 0:
        return f"### {title}\nNo capture was written.\n"
    q = lambda flt, *f: run(["tshark", "-r", pcap, "-Y", flt, "-T", "fields", *[x for fld in f for x in ("-e", fld)]]).stdout
    total = sum(int(x) for x in q("ip && !(ip.src==10.0.2.0/24 && ip.dst==10.0.2.0/24)", "frame.len").split() if x.isdigit())
    names = {}
    for n in q("dns.flags.response == 0", "dns.qry.name").split():
        if "arpa" not in n and not n.endswith(".local"):
            names[n] = names.get(n, 0) + 1
    sni = {}
    for n in q("tls.handshake.extensions_server_name", "tls.handshake.extensions_server_name").split():
        sni[n] = sni.get(n, 0) + 1
    per = {}
    for line in q("ip", "ip.src", "ip.dst", "frame.len").splitlines():
        a = line.split()
        if len(a) == 3 and a[2].isdigit():
            r = a[1] if a[0].startswith("10.0.2.") else a[0]
            if not r.startswith("10.0.2.") and not r.startswith("224.") and r != "255.255.255.255":
                per[r] = per.get(r, 0) + int(a[2])
    top = sorted(per.items(), key=lambda kv: -kv[1])[:8]
    s = f"### {title}\nData to and from the internet: **{total / 1e6:.2f} MB**\n\n"
    s += "Names looked up:\n```\n" + "\n".join(f"{c:4d} {n}" for n, c in sorted(names.items(), key=lambda kv: -kv[1])[:30]) + "\n```\n"
    s += "Servers by name (encrypted connections):\n```\n" + "\n".join(f"{c:4d} {n}" for n, c in sorted(sni.items(), key=lambda kv: -kv[1])[:30]) + "\n```\n"
    s += "Biggest remote addresses (bytes):\n```\n" + "\n".join(f"{b:12d}  {r}" for r, b in top) + "\n```\n"
    return s


# ---------------------------------------------------------------- phase 1: install
cfg = WORK / "cfg"; cfg.mkdir(exist_ok=True)
(cfg / "ks.cfg").write_text(KS); (cfg / "run.sh").write_text(RUN_SH)
run(["xorriso", "-as", "mkisofs", "-V", "CIDATA", "-o", str(WORK / "cfg.iso"), str(cfg)], check=True)

kargs = []
if run(["xorriso", "-osirrox", "on", "-indev", ISO, "-extract", "/images/pxeboot/vmlinuz", str(WORK / "vmlinuz"),
        "-extract", "/images/pxeboot/initrd.img", str(WORK / "initrd.img")]).returncode == 0:
    label = re.search(r"Volume Id\s*:\s*(\S+)", run(["xorriso", "-indev", ISO, "-pvd_info"]).stdout)
    run(["chmod", "u+rw", str(WORK / "vmlinuz"), str(WORK / "initrd.img")])
    kargs = ["-kernel", str(WORK / "vmlinuz"), "-initrd", str(WORK / "initrd.img"), "-append",
             f"root=live:CDLABEL={label.group(1) if label else 'RAVANA-OS'} rd.live.image enforcing=0 "
             "console=tty0 console=ttyS0,115200 plymouth.enable=0"]

say("phase 1: booting the live ISO")
vm, mon, ser = qemu("install", True, kargs)
time.sleep(2)
con = Console(ser, OUT / "install-console.log")
install_rc = None
try:
    if not con.wait(r"login: ", 420):
        raise RuntimeError("the live system never reached a login prompt (see install-console.log)")
    say("live system is up; logging in")
    con.send("liveuser\r")
    m = con.wait(r"(Password: |\$ )", 60)
    if m and m.group(1).startswith("Password"):
        con.send("\r")
    time.sleep(2)
    con.send("echo RV-READY\r")
    if not con.wait(r"\nRV-READY", 60):
        raise RuntimeError("could not log in on the serial console")
    monitor_shot(mon, OUT / "install-live-desktop.png")
    say("running the real installer (this takes a while)")
    con.send("sudo -n bash -c 'mkdir -p /mnt/cfg && mount -L CIDATA /mnt/cfg && bash /mnt/cfg/run.sh'; echo RV-DONE-$?\r")
    m = con.wait(r"RV-DONE-(\d+)", INSTALL_TIMEOUT, beat="installer still running")
    if not m:
        raise RuntimeError(f"the installer did not finish within {INSTALL_TIMEOUT}s")
    install_rc = int(m.group(1))
    say(f"installer finished with exit code {install_rc}")
    time.sleep(3)
    con.send("sudo -n poweroff\r")
except Exception as e:
    REPORT.append(f"**Install harness problem:** {e}\n")
    say(f"problem: {e}")
    monitor_shot(mon, OUT / "install-problem.png")
finally:
    try:
        vm.wait(timeout=120)
    except subprocess.TimeoutExpired:
        vm.kill(); vm.wait()

REPORT.insert(0, "## Real installer test\n\n" + (
    f"The installer **{'finished successfully' if install_rc == 0 else 'FAILED'}** (exit code {install_rc}).\n"
    if install_rc is not None else "The installer did not run to the end (see below).\n"))
REPORT.append(net_summary(OUT / "install.pcap", "Network use while installing"))
text = (OUT / "install-console.log").read_text(errors="replace") if (OUT / "install-console.log").exists() else ""
text = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text).replace("\r", "")
i = text.find("ANACONDA-EXIT")
REPORT.append("### Installer log (from the live system)\n```\n" + (text[i:][-9000:] if i >= 0 else text[-4000:]) + "\n```\n")

# ---------------------------------------------------------------- phase 2: boot what was installed
if install_rc == 0:
    say("phase 2: booting the installed system")
    vm2, mon2, ser2 = qemu("firstboot", False)
    third = FIRSTBOOT_SECS // 3
    for n in (1, 2, 3):
        time.sleep(third)
        monitor_shot(mon2, OUT / (f"firstboot-{n}.png"))
    vm2.kill(); vm2.wait()
    REPORT.append(net_summary(OUT / "firstboot.pcap", f"Network use during the first {FIRSTBOOT_SECS}s after install"))
    REPORT.append("First-boot screenshots: `firstboot-1.png`, `firstboot-2.png`, `firstboot-3.png`.\n")

(OUT / "report.md").write_text("\n".join(REPORT))
print("\n".join(REPORT))
for f in ("vmlinuz", "initrd.img"):
    (WORK / f).unlink(missing_ok=True)
sys.exit(0)
