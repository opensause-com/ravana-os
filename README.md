<div align="center">

# Ravana OS

**Built for gamers who code, and coders who game.**

A fast, lightweight Linux OS with a console-style Game Mode, a clean developer desktop,
and updates that can always be rolled back.

[![Build Ravana OS](https://github.com/ravana-os/ravana-os/actions/workflows/build.yml/badge.svg)](https://github.com/ravana-os/ravana-os/actions/workflows/build.yml)

</div>

---

## Why Ravana

- **Game Mode.** Boot straight into a controller-friendly, console-style Steam experience with no
  desktop running in the background, so your games get the RAM and GPU.
- **Dev Mode.** A polished KDE Plasma desktop with Podman, Distrobox and Homebrew built in,
  and VS Code, Docker, VMs and GPU compute one click away with **Get Developer Tools**.
- **Light by design.** Background indexing and other idle services are off by default.
- **Unbreakable updates.** Every update is a complete, tested system image. If one misbehaves,
  pick the previous version in the boot menu and you're back in seconds.
- **Every GPU.** Builds for AMD / Intel and NVIDIA, with drivers built in.
- **Small download.** The default edition stays lean; add the developer stack only if you want it.
- **Small updates.** Only the parts that changed are downloaded.

## Editions

| Edition | What's inside | Image |
|---|---|---|
| **Ravana OS** | Gaming, Game Mode, KDE desktop, Podman, Distrobox, Homebrew, Bazaar app store | `ghcr.io/ravana-os/ravana-os` |
| **Ravana OS Developer** | Everything above + VS Code, Docker, virtual machines (QEMU/KVM), ROCm GPU compute, profilers | `ghcr.io/ravana-os/ravana-os-dx` |

NVIDIA graphics: add `-nvidia` (`ravana-os-nvidia`, `ravana-os-dx-nvidia`).

Start small and add only what you need:

- **Apps:** the **Bazaar** app store (Discord, Spotify, OBS, Blender, launchers...)
- **CLI tools:** `brew install node go rust kubectl`
- **Linux environments:** **DistroShelf** for Ubuntu, Arch or Fedora containers
- **The full dev stack:** open **Get Developer Tools** from the app menu. It switches your
  system to Ravana OS Developer in one step (and **Remove Developer Tools** switches back).

## Install

### Try it first (live USB)

1. Download the **live ISO** from the [latest release](https://github.com/ravana-os/ravana-os/releases/latest)
   (pick `ravana-os-nvidia-live.iso` for NVIDIA graphics) and check it against `SHA256SUMS`
   (`sha256sum -c SHA256SUMS`). The list is signed with the key in [`cosign.pub`](cosign.pub) when
   `SHA256SUMS.sig` is attached to the release, so you can also check that the list itself is genuine:
   `cosign verify-blob --key cosign.pub --signature SHA256SUMS.sig SHA256SUMS`.
2. Write it to an 8 GB+ USB stick with [Fedora Media Writer](https://flathub.org/apps/org.fedoraproject.MediaWriter),
   [Ventoy](https://www.ventoy.net) or [Rufus](https://rufus.ie) (DD mode).
3. Boot from the USB (usually F12, F11, F8 or Esc at power-on) and choose **Try or Install Ravana OS**.

Ravana runs entirely from the USB. Nothing on your computer changes until you click
**Install Ravana OS**. Changes in the live session reset on reboot, and games or
benchmarks won't reflect the installed experience.

### Install next to Windows (dual boot)

1. **In Windows first:**
   - Back up anything important.
   - Turn off **BitLocker** for the drive, or Ravana's installer will warn you about it.
   - Turn off **Fast Startup** (Control Panel, Power Options, *Choose what the power buttons do*).
   - Make free space: *Disk Management*, right-click your drive, *Shrink Volume*.
     Give Ravana at least **80 GB**; 150 GB+ if you'll install games. A second drive is even simpler.
2. Boot the live USB and click **Install Ravana OS**.
3. Choose the free space (or the second drive). Don't select the Windows partition.
4. Ravana installs from the USB itself; no internet connection is needed.
5. Reboot. Pick **Ravana OS** or **Windows** in the boot menu, or from your PC's boot menu key.

If a Windows update ever skips the Ravana boot menu, boot the live USB and run
**Ravana OS Bootloader Restoring Tool**.

### Secure Boot

The live USB boots with Secure Boot on. During installation, Ravana adds the Universal Blue
signing key used by its kernel drivers. On the first reboot a blue **MOK Management** screen
appears: choose *Enroll MOK*, then *Continue*, enter the password **`universalblue`**, and
reboot. You only do this once.

### Already on Bazzite or another Fedora Atomic system?

Switch in two steps. The first boot of Ravana installs its signing key; the second step
turns on signature checking for all future updates.

```bash
sudo bootc switch ghcr.io/ravana-os/ravana-os:latest      # use ravana-os-nvidia for NVIDIA
systemctl reboot
```

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ravana-os/ravana-os:latest
```

## Updates

Ravana updates itself. Once a week (Sunday morning, or at the next boot) it downloads only
what changed and applies it on reboot. Your apps, files and settings stay.

Don't want to wait? Open **Update Ravana OS** from the app menu, or run:

```bash
ujust update                 # system, Flatpaks and Distrobox containers
sudo bootc upgrade           # just the system image; reboot to apply
bootc status                 # current and staged versions
```

If an update misbehaves, pick the previous version in the boot menu.

### Channels

| Channel | Image tag | Who it's for |
|---|---|---|
| Stable | `:latest` | Everyone. Built from `main`, plus a daily rebuild with upstream fixes |
| Testing | `:testing` | Test machines. Built from the `testing` branch |

```bash
sudo bootc switch ghcr.io/ravana-os/ravana-os:testing   # follow testing
sudo bootc switch ghcr.io/ravana-os/ravana-os:latest    # back to stable
```

New work lands on `testing` first, then merges to `main` once it's verified.

## Security

| Layer | What Ravana does |
|---|---|
| Read-only system | `/usr` can't be changed by apps or malware; updates replace the whole system image |
| Signed updates | Every image is signed with [cosign](https://github.com/sigstore/cosign); installed systems refuse unsigned or tampered updates |
| Rollback | A bad update is one reboot away from the previous version |
| Secure Boot | Works out of the box |
| SELinux | Enforcing, confines system services |
| Sandboxed apps | Store apps are Flatpaks with their own permissions |
| Firewall | Incoming connections blocked; only DHCPv6, local discovery (mDNS) and Steam Remote Play allowed |
| No remote login | SSH and remote printer discovery off unless you turn them on |
| Kernel hardening | Hidden kernel pointers and logs, restricted debugging (ptrace), no unprivileged eBPF, no kexec, network spoofing/redirect protection |
| Network privacy | Random Wi-Fi address while scanning, a different address per network, IPv6 privacy addresses, encrypted DNS when the server supports it |
| Password guessing | Account locks for 2 minutes after 10 wrong passwords |
| Screen lock | Locks after 10 minutes and on wake from sleep |
| Firmware | BIOS and device firmware updates through fwupd |
| No telemetry | Nothing is sent home |

Everything above is chosen so Steam, Proton anti-cheat, Docker, VMs and dev tools keep working.
Turn on disk encryption in the installer's storage step for protection if the PC is stolen.

Verify an image yourself:

```bash
cosign verify --key https://raw.githubusercontent.com/ravana-os/ravana-os/main/cosign.pub \
  ghcr.io/ravana-os/ravana-os:latest
```

## Look & feel

Ravana's identity is **crimson red on near-black**: red marks focus, selection and action,
while surfaces stay calm for long gaming and coding sessions.

The desktop works like a Mac:

- **Menu bar:** the Ravana crown menu (About, System Settings, App Store, Force Quit, Sleep,
  Restart, Shut Down, Lock, Log Out), the app's menus, status icons, Spotlight search, clock
- **Dock:** floating glass, Launchpad first and Trash last
- **Windows:** red, yellow and green buttons on the left, genie minimize, Mission Control (⌃↑)
- **Keyboard:** ⌘ is the Windows key: ⌘C, ⌘V, ⌘Q, ⌘Tab, ⌘Space, ⇧⌘4 and the rest
  ([full list](docs/macos-ui-plan.md))
- **Glass:** translucent, blurred menu bar, dock, menus, Spotlight and Launchpad

Boot is quiet end to end: the Ravana crown animation plays from firmware to the login
screen, then a matching splash carries you into the desktop. After an update that changes
the look, Ravana asks once whether to apply it. **Reset Ravana Look** in the app menu brings
it back any time.

| | Colour |
|---|---|
| Ravana Red (accent) | `#D21F3C` |
| Background | `#121214` |
| Text | `#F5F5F7` |
| Links | `#FF5A66` |

## Roadmap

- [x] Gaming + dev base, AMD/Intel and NVIDIA editions, automatic cloud builds
- [x] Ravana branding and color schemes
- [x] Ravana logo, wallpapers, boot splash and boot menu name
- [x] macOS-style desktop: top bar with global menu, floating dock, genie minimize, blur, Overview
- [ ] Login screen theme
- [x] Debloat pass, measured: ROCm compiler libs, non-x86 emulators, Deck-only daemons, docs
- [x] Weekly auto-updates and a testing channel
- [x] Signed images; automatic live ISOs and GitHub Releases from stable builds
- [ ] Small network-installer ISO
- [ ] Welcome app: choose Game Mode or Desktop, pick dev packs
- [x] Live ISO: try Ravana before installing, then install (dual boot friendly)

## Building Ravana yourself

Everything that makes Ravana lives in this repo:

| Path | What it is |
|---|---|
| `Containerfile` | The OS definition |
| `cosign.pub` | Public key that verifies every Ravana image |
| `build_files/` | Build steps run inside the image (branding, tuning, theme) |
| `system_files/` | Files shipped in the OS (configs, color schemes) |
| `tools/` | Generators, e.g. `gen-kde-colors.py` for the color schemes |
| `.github/workflows/` | Cloud builds: images on every push, live ISO and installer ISO on demand |
| `live/`, `Containerfile.live` | Live USB layer: live session, installer, branding (adapted from Titanoboa) |
| `scripts/` | Local build and VM test helpers |

Pushing to `main` builds both editions in GitHub Actions. To build locally (≈7 GB download), use
`scripts/build-image.sh`, then `sudo scripts/build-disk.sh iso`.

## Credits

Ravana OS stands on the shoulders of [Bazzite](https://bazzite.gg), [Titanoboa](https://github.com/ublue-os/titanoboa) and
[Universal Blue](https://universal-blue.org), built from [Fedora](https://fedoraproject.org)
packages. The look builds on [KDE Plasma](https://kde.org/plasma-desktop/) (Ravana Launchpad
is based on KDE's kicker dashboard), [Kvantum](https://github.com/tsujan/Kvantum) and its KvMojave
theme, [Colloid icons](https://github.com/vinceliuice/Colloid-icon-theme) and
[keyd](https://github.com/rvaiya/keyd). Ravana OS is an independent project and is not affiliated with or endorsed by the
Fedora Project, Red Hat, or Universal Blue.
