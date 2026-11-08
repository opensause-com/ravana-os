# Ravana OS

A lightweight gaming + developer OS. Ravana OS is a custom [bootc](https://containers.github.io/bootc/)
image layered on **Bazzite DX** (Fedora Atomic, KDE Plasma 6), so it inherits Bazzite's gaming
stack (Steam, Proton, gamescope, MangoHud, GameMode, NVIDIA/AMD/Intel drivers, gaming kernel)
and its dev tooling (VS Code, Podman/Docker, Distrobox), then adds Ravana branding and lower idle RAM.

The whole OS is defined by the files in this repo. Updates are atomic, and the previous
version stays selectable in the boot menu if one goes wrong.

## Layout

| Path | Purpose |
|---|---|
| `Containerfile` | The OS definition: `FROM` Bazzite DX + Ravana build steps |
| `build_files/NN-*.sh` | Build scripts run inside the image, in numeric order |
| `system_files/` | Files copied over `/` in the image (configs, branding) |
| `scripts/` | Host-side helpers: build image, build ISO/VM disk, run VM |
| `config/qcow2-test.toml` | Test-only VM login (`ravana` / `ravana`), not used by the ISO |

## Cloud builds (GitHub Actions)

- `.github/workflows/build.yml` builds `ravana-os` (AMD/Intel) and `ravana-os-nvidia` on every
  push to `main` and daily. It pushes them to `ghcr.io/<owner>/`.
- `.github/workflows/build-iso.yml` is manual (Actions tab → *Run workflow*). It produces an
  installer ISO as a downloadable artifact, kept for 7 days.

## Local build

Needs `podman` (and `qemu-system-x86` + OVMF to test). Pulling the base the first time is ~7 GB.

```bash
scripts/build-image.sh               # AMD / Intel GPU
GPU=nvidia scripts/build-image.sh    # NVIDIA GPU
```

Make something bootable (needs sudo; bootc-image-builder runs rootful):

```bash
sudo scripts/build-disk.sh qcow2     # VM disk for testing
sudo scripts/build-disk.sh iso       # installer ISO
```

Test in QEMU:

```bash
scripts/run-vm.sh                    # boot the qcow2
scripts/run-vm.sh iso                # run the installer ISO
```

## Switching an existing Bazzite / Fedora Atomic PC to Ravana

Once the image is pushed to a registry (e.g. GHCR via CI):

```bash
sudo bootc switch ghcr.io/<you>/ravana-os:latest
```
