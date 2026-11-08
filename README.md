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
- **Dev Mode.** A polished KDE Plasma desktop with VS Code, Docker, Podman, Distrobox,
  Homebrew, QEMU/KVM and GPU compute (ROCm / CUDA) ready on first boot.
- **Light by design.** Background indexing and other idle services are off by default.
- **Unbreakable updates.** Every update is a complete, tested system image. If one misbehaves,
  pick the previous version in the boot menu and you're back in seconds.
- **Every GPU.** Separate editions for AMD / Intel and NVIDIA, with drivers built in.
- **Small updates.** Only the parts that changed are downloaded.

## Editions

| Edition | For | Image |
|---|---|---|
| **Ravana OS** | AMD and Intel graphics | `ghcr.io/ravana-os/ravana-os:latest` |
| **Ravana OS NVIDIA** | NVIDIA graphics | `ghcr.io/ravana-os/ravana-os-nvidia:latest` |

## Install

### Try it first (live USB)

1. Download the **live ISO** from the
   [latest live ISO build](https://github.com/ravana-os/ravana-os/actions/workflows/build-live-iso.yml)
   (newest run, then *Artifacts*). Pick `ravana-os-nvidia` for NVIDIA graphics.
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
4. The installer downloads Ravana (about 5.5 GB), so stay connected to the internet.
5. Reboot. Pick **Ravana OS** or **Windows** in the boot menu, or from your PC's boot menu key.

If a Windows update ever skips the Ravana boot menu, boot the live USB and run
**Ravana OS Bootloader Restoring Tool**.

### Secure Boot

The live USB boots with Secure Boot on. During installation, Ravana adds the Universal Blue
signing key used by its kernel drivers. On the first reboot a blue **MOK Management** screen
appears: choose *Enroll MOK*, then *Continue*, enter the password **`universalblue`**, and
reboot. You only do this once.

### Already on Bazzite or another Fedora Atomic system?

Switch with one command and reboot:

```bash
sudo bootc switch ghcr.io/ravana-os/ravana-os:latest          # AMD / Intel
sudo bootc switch ghcr.io/ravana-os/ravana-os-nvidia:latest   # NVIDIA
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

## Look & feel

Ravana's identity is **crimson red on near-black or white**: red marks focus, selection and
action, while surfaces stay calm for long gaming and coding sessions. *Ravana Dark* and
*Ravana Light* color schemes ship by default, with the Ravana crown logo, wallpapers
and boot splash.

The desktop follows a familiar layout: a top bar with the app menu, clock and tray, a
floating dock at the bottom, window buttons on the left, genie-style minimize, translucent
blur, and Overview (Meta+W or the top-left corner) to see all your windows. Panels, the
dock, menus and the terminal are frosted glass over your wallpaper.

Boot is quiet end to end: the Ravana crown animation plays from firmware to the login
screen, then a matching splash carries you into the desktop. Changed the look and want it
back? Open **Reset Ravana Look** from the app menu.

| | Dark | Light |
|---|---|---|
| Ravana Red (accent) | `#D21F3C` | `#D21F3C` |
| Background | `#121214` | `#F4F4F5` |
| Text | `#F5F5F7` | `#18181B` |
| Links | `#FF5A66` | `#C8102E` |

## Roadmap

- [x] Gaming + dev base, AMD/Intel and NVIDIA editions, automatic cloud builds
- [x] Ravana branding and color schemes
- [x] Ravana logo, wallpapers, boot splash and boot menu name
- [x] macOS-style desktop: top bar with global menu, floating dock, genie minimize, blur, Overview
- [ ] Login screen theme
- [x] Debloat pass, measured: ROCm compiler libs, non-x86 emulators, Deck-only daemons, docs
- [x] Weekly auto-updates and a testing channel
- [ ] Small network-installer ISO
- [ ] Welcome app: choose Game Mode or Desktop, pick dev packs
- [x] Live ISO: try Ravana before installing, then install (dual boot friendly)

## Building Ravana yourself

Everything that makes Ravana lives in this repo:

| Path | What it is |
|---|---|
| `Containerfile` | The OS definition |
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
packages. Ravana OS is an independent project and is not affiliated with or endorsed by the
Fedora Project, Red Hat, or Universal Blue.
