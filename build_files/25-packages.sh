#!/usr/bin/env bash
# Ravana look-and-feel packages from Fedora: UI/code fonts and icon theme.
set -euxo pipefail
cp /run/context/build_files/fedora-build.repo /etc/yum.repos.d/ravana-build-fedora.repo
dnf5 install -y --setopt=install_weak_deps=False \
    --repo=ravana-build-fedora --repo=ravana-build-updates \
    rsms-inter-fonts \
    jetbrains-mono-fonts \
    papirus-icon-theme \
    papirus-icon-theme-dark
# Fedora ships Papirus-Dark separately; the desktop uses it, so it must be there
test -f /usr/share/icons/Papirus-Dark/index.theme
