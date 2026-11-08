# Ravana OS — gaming + dev, built on Bazzite DX (Fedora Atomic, KDE Plasma)
#   AMD/Intel GPU : BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable          (default)
#   NVIDIA GPU    : BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx-nvidia:stable
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable

FROM scratch AS ctx
COPY system_files /files
COPY build_files /build_files

FROM ${BASE_IMAGE}

ARG IMAGE_NAME=ravana-os
ARG IMAGE_VENDOR=ravana-os
ARG IMAGE_VERSION=0.1

RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" IMAGE_VERSION="${IMAGE_VERSION}" \
    /run/context/build_files/build.sh

LABEL org.opencontainers.image.title="Ravana OS" \
      org.opencontainers.image.description="Lightweight gaming + developer OS based on Bazzite DX" \
      containers.bootc="1" \
      ostree.bootable="true"
