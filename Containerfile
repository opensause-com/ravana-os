# Ravana OS (Fedora Atomic, KDE Plasma), two editions from one recipe:
# Both build on ghcr.io/ublue-os/bazzite-dx[-nvidia]:stable:
#   IMAGE_FLAVOR=main : gaming + desktop + Game Mode; dev stack removed (build_files/12-edition.sh)
#   IMAGE_FLAVOR=dx   : + VS Code, Docker, VMs, ROCm
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable

FROM scratch AS ctx
COPY system_files /files
COPY build_files /build_files

FROM ${BASE_IMAGE}

ARG IMAGE_NAME=ravana-os
ARG IMAGE_VENDOR=ravana-os
ARG IMAGE_VERSION=0.1
ARG IMAGE_FLAVOR=main

RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" IMAGE_VERSION="${IMAGE_VERSION}" IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /run/context/build_files/build.sh

LABEL org.opencontainers.image.title="Ravana OS" \
      org.opencontainers.image.description="Lightweight gaming + developer OS" \
      containers.bootc="1" \
      ostree.bootable="true"
