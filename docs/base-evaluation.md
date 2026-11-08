# Ravana OS — Base Selection

_Updated: 2026-11-08 · Status: decided_

## Goal

A gaming + developer desktop OS with the lowest practical RAM use, that runs Steam/Proton,
NVIDIA/AMD/Intel GPUs and mainstream dev tools, and that a small team can maintain.

## Decision

**Ravana OS is a bootc image layered on Bazzite DX** (Fedora Atomic, KDE Plasma 6), built in
GitHub Actions and published to GHCR.

- **Game Mode:** gamescope + Steam Big Picture with no desktop running (~0.5–0.7 GB system RAM).
- **Desktop Mode (dev):** KDE Plasma 6, trimmed (file indexing off, unused services disabled).
- **Dev tooling** comes from Bazzite DX: VS Code, Podman/Docker, Distrobox.
- **Updates** are atomic with rollback. CI rechunks images so updates download only changed packages.

## Options considered

| Option | Verdict | Why |
|---|---|---|
| Buildroot (musl, BusyBox) | Rejected | Built for appliances. Can't run Steam/Proton (glibc + 32-bit runtime), no package manager, no realistic KDE/GNOME. Tried first; dropped once the goal became gaming + dev. |
| Yocto | Rejected | Same limits as Buildroot, with much heavier builds. |
| Debian live-build | Rejected | Debian stable's kernel and Mesa lag 1–2 years, which hurts new GPUs and games. |
| RHEL / Rocky / Alma | Rejected | Server focus, old packages, strict trademark rules. |
| Arch + archiso (CachyOS/SteamOS style) | Runner-up | Newest packages, but more maintenance and no built-in rollback. |
| Plain Fedora Kinoite + own gaming stack | Rejected | Saves ~2 GB of download but loses Bazzite's gaming kernel, drivers and tuning. |
| **Bazzite DX + Ravana layer** | **Chosen** | Mature gaming stack, NVIDIA support, rollback, dev tools included, low maintenance. |

## Desktop choice

| | KDE Plasma 6 (chosen) | Hyprland | GNOME |
|---|---|---|---|
| HDR | Stable | Experimental | Basic |
| VRR / tearing control | Mature | Works | Newer, no tearing option |
| Idle RAM | ~0.9–1.1 GB trimmed | ~0.4–0.6 GB | ~1.3–1.8 GB |
| Maintenance | Low | High | Low |

## Build and data costs

| Where | Data used on your own connection |
|---|---|
| Image build (GitHub Actions) | None. GitHub's runners download the ~7 GB base. |
| Installer ISO | ~8 GB, downloaded once per install |
| Updates on an installed PC | Only changed chunks, typically ~0.3–2 GB |
