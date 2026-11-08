#!/usr/bin/env bash
# Ravana debloat: drop what a gaming + dev desktop never uses, stop needless
# background work, and fail the build if anything core goes missing.
# Sizes are from the "Analyze image" workflow.
set -euxo pipefail

SIZE_BEFORE=$(du -sxm /usr | cut -f1)
SESSION_SWITCH="$(command -v steamos-session-select || true)"

# ---------- 1. Packages ----------
REMOVE=(
    # Non-x86 VM emulation + ARM VM firmware (~0.5 GB); x86 VMs (KVM/QEMU) stay
    edk2-aarch64 edk2-arm
    qemu-system-aarch64-core qemu-system-mips-core qemu-system-ppc-core
    qemu-system-riscv-core qemu-system-xtensa-core qemu-system-sparc-core
    qemu-system-s390x-core qemu-system-loongarch64-core qemu-system-m68k-core
    qemu-system-microblaze-core qemu-system-or1k-core qemu-system-sh4-core
    qemu-system-alpha-core qemu-system-arm-core qemu-system-hppa-core
    qemu-system-tricore-core qemu-system-rx-core qemu-system-avr-core
    # Stock KDE wallpapers (~0.3 GB); Ravana ships its own
    plasma-workspace-wallpapers
    # SystemTap (~0.26 GB); bpftrace/bcc cover tracing
    systemtap systemtap-devel systemtap-client systemtap-runtime
    # Steam Deck-only hardware daemons (fan, audio DSP, OLED calibration, power
    # button). jupiter-hw-support and steamdeck-kde-presets stay: they carry the
    # Game Mode <-> Desktop session switching.
    jupiter-fan-control steamdeck-dsp galileo-mura powerbuttond
    # Alternative gamepad UI; Steam Game Mode stays
    opengamepadui gamescope-session-ogui
)
PRESENT=()
for p in "${REMOVE[@]}"; do rpm -q "$p" >/dev/null 2>&1 && PRESENT+=("$p"); done
echo "Removing: ${PRESENT[*]}"
if [ ${#PRESENT[@]} -gt 0 ]; then
    dnf5 remove -y --disablerepo='*' --setopt=clean_requirements_on_remove=False "${PRESENT[@]}"
fi

# ROCm's static LLVM libraries (~2.2 GB). Packages stay installed because
# rocm-hip -> hipcc -> rocm-llvm-devel depend on them; only the .a archives go.
# They are used to link LLVM statically into compilers, never at runtime.
if rpm -q rocm-llvm-static >/dev/null 2>&1; then
    rpm -ql rocm-llvm-static | grep -E '\.a$' | xargs -r rm -f
fi

# Docs (~0.24 GB); man pages and licenses stay
find /usr/share/doc -mindepth 1 -maxdepth 1 -exec rm -rf {} +

# ---------- 2. Background services ----------
for unit in iscsi-onboot.service iscsi-starter.service iscsid.socket iscsiuio.socket \
            ModemManager.service; do
    systemctl disable "$unit" 2>/dev/null || true
done

# Autostart entries that cost RAM at every desktop login.
# Steam still launches in Game Mode and can be re-enabled in Steam's settings.
hide_autostart() {
    local f="/etc/xdg/autostart/$1"
    [ -f "$f" ] || return 0
    grep -q '^Hidden=true' "$f" || echo 'Hidden=true' >> "$f"
}
hide_autostart steam.desktop
hide_autostart org.kde.kdeconnect.daemon.desktop
hide_autostart geoclue-demo-agent.desktop

# ---------- 3. Safety net: core features must still be here ----------
MUST_HAVE=(
    kernel-core plasma-workspace plasma-desktop kwin steam
    gamescope-session-steam mesa-vulkan-drivers mesa-dri-drivers
    code docker-ce podman distrobox flatpak NetworkManager pipewire
    rocm-hip rocm-opencl qemu-kvm libvirt plasma-login-manager
)
MISSING=()
for p in "${MUST_HAVE[@]}"; do rpm -q "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: debloat removed core packages: ${MISSING[*]}" >&2
    exit 1
fi
test -f /usr/share/wayland-sessions/gamescope-session-steam.desktop
command -v gamescope   # Game Mode compositor (package name varies)
command -v hipcc       # ROCm HIP toolchain
test -f /usr/share/wayland-sessions/plasma.desktop
if [ -n "$SESSION_SWITCH" ]; then test -x "$SESSION_SWITCH"; fi

echo "Debloat: /usr went from ${SIZE_BEFORE} MB to $(du -sxm /usr | cut -f1) MB"
