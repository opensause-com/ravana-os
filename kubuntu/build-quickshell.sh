#!/usr/bin/env bash
# Build Quickshell from its release tag inside an Ubuntu 26.04 container (it is not in Ubuntu's
# archive). Installs into a staging folder; the result is unpacked into the ISO's system.
# Usage: build-quickshell.sh <tag> <out-tar>
set -euxo pipefail
TAG="${1:?}"; OUT="${2:?}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    ca-certificates git build-essential cmake ninja-build pkg-config spirv-tools \
    qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev \
    qt6-shadertools-dev qt6-wayland-dev qt6-wayland-private-dev qt6-svg-dev qt6-tools-dev \
    wayland-protocols libwayland-dev libpipewire-0.3-dev libpam0g-dev libdrm-dev libgbm-dev \
    libegl-dev libgles-dev libjemalloc-dev libcli11-dev libpolkit-agent-1-dev libpolkit-gobject-1-dev \
    libglib2.0-dev libxcb1-dev libxcb-xinput-dev libx11-dev
git clone --depth 1 --branch "$TAG" https://github.com/quickshell-mirror/quickshell.git /src
cd /src
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_HANDLER=OFF -DDISTRIBUTOR="Ravana OS" -DINSTALL_QML_PREFIX=lib/x86_64-linux-gnu/qt6/qml
cmake --build build
DESTDIR=/stage cmake --install build
# runtime libraries the binary needs, so the ISO can install exactly those
ldd /stage/usr/bin/quickshell | awk '/=>/ {print $3}' | while read -r l; do dpkg -S "$l" 2>/dev/null | cut -d: -f1; done | sort -u > /stage/quickshell-runtime-packages.txt
cat /stage/quickshell-runtime-packages.txt
tar -C /stage -czf "$OUT" .
ls -lh "$OUT"
