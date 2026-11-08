#!/usr/bin/env bash
# Build the Ravana OS bootc container image (rootless, no sudo needed).
#   scripts/build-image.sh            # AMD / Intel GPU
#   GPU=nvidia scripts/build-image.sh # NVIDIA GPU
set -euo pipefail
cd "$(dirname "$0")/.."
BASE=ghcr.io/ublue-os/bazzite-dx:stable
TAG=localhost/ravana-os:latest
if [ "${GPU:-}" = nvidia ]; then
    BASE=ghcr.io/ublue-os/bazzite-dx-nvidia:stable
    TAG=localhost/ravana-os-nvidia:latest
fi
podman build --pull=newer --build-arg BASE_IMAGE="$BASE" -t "$TAG" -f Containerfile .
echo "Built $TAG"
