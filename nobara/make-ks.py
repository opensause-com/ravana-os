#!/usr/bin/env python3
"""Turn Nobara's published KDE live-ISO kickstart into Ravana's.

Usage: make-ks.py <nobara-kickstart> <output-kickstart>

Nobara's kickstart (github.com/Nobara-Project/nobara-images) is the base: its repositories, kernel,
NVIDIA and gaming packages, and Calamares installer are used as published. This script only
  - drops packages Ravana does not ship (video editors, office suite, database server, ...),
  - swaps Plasma Login Manager for SDDM (Ravana's login theme),
  - adds the Ravana packages (quickshell and what the shell needs),
  - adds two steps that put Ravana's files and settings on top (nobara/ravana-post.sh).
Nothing else is changed, so a newer Nobara kickstart can be dropped in unchanged.
"""
import re, sys

src, dst = sys.argv[1], sys.argv[2]
ks = open(src).read()

DROP = {
    "blender", "kdenlive", "obs-studio", "libreoffice", "inkscape", "okular", "mariadb-server",
    "mariadb-embedded", "mariadb-connector-c", "akonadi-server-mysql", "nobara-resolve-wizard",
    "nobara-resolve-runtime", "nobara-welcome", "plasma-login-manager", "neofetch", "vapoursynth-tools",
    "python3-vapoursynth", "ghc-mountpoints", "kdenlive", "krdp", "kwebkitpart",
}
ADD = ["quickshell", "sddm", "sddm-wayland-plasma", "python3-dbus", "python3-gobject-base",
       "yaml-cpp", "libevdev", "ddcutil", "rsms-inter-fonts", "git"]

head, sep, rest = ks.partition("%packages")
pkgs, end, tail = rest.partition("\n%end")
lines = []
for line in pkgs.splitlines():
    if line.strip() in DROP:
        continue
    lines.append(line)
lines += ADD
pkgs = "\n".join(lines)

# login manager: SDDM, not Plasma Login Manager; the live user logs in by itself
head = head.replace("plasmalogin", "sddm")
head = head.replace('hostnamectl set-hostname "nobara-live"', 'hostnamectl set-hostname "ravana-live"')

ravana_steps = r"""
# ---- Ravana: files and settings on top of the Nobara base --------------------------------------
%post --nochroot --erroronfail
set -eux
root="${ANA_INSTALL_PATH:-/mnt/sysimage}"
: "${RAVANA_SRC:?RAVANA_SRC (the repository checkout) must be set}"
cp -a "$RAVANA_SRC/system_files/." "$root/"
mkdir -p "$root/tmp/ravana-build"
cp -a "$RAVANA_SRC/build_files/." "$root/tmp/ravana-build/"
cp -a "$RAVANA_SRC/nobara/ravana-post.sh" "$root/tmp/ravana-build/"
%end

%post --erroronfail
set -eux
bash /tmp/ravana-build/ravana-post.sh
rm -rf /tmp/ravana-build
%end
"""

out = head + "%packages" + pkgs + end + "\n" + tail
# the Ravana steps run after Nobara's own %post sections (kickstart order), so put them last
out = out.rstrip("\n") + "\n" + ravana_steps
open(dst, "w").write(out)
print(f"wrote {dst}: {len(lines)} package lines, dropped {len(DROP)} names")
