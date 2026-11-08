# Ravana OS (Fedora Atomic, KDE Plasma), two editions from one recipe:
# Both build on ghcr.io/ublue-os/bazzite-dx[-nvidia]:stable:
#   IMAGE_FLAVOR=main : gaming + desktop + Game Mode; dev stack removed (build_files/12-edition.sh)
#   IMAGE_FLAVOR=dx   : + VS Code, Docker, VMs, ROCm
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable

# keyd: tiny key-remapping daemon behind the Mac shortcuts (Cmd = Windows key).
# Not packaged in Fedora, so it is built from a pinned, checksum-verified release.
ARG FEDORA_VERSION=45
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS keyd
ARG KEYD_VERSION=2.6.0
ARG KEYD_SHA256=697089681915b89d9e98caf93d870dbd4abce768af8a647d54650a6a90744e26
RUN dnf -y install --setopt=install_weak_deps=False gcc make && \
    curl -fsSL -o /tmp/keyd.tar.gz "https://github.com/rvaiya/keyd/archive/refs/tags/v${KEYD_VERSION}.tar.gz" && \
    echo "${KEYD_SHA256}  /tmp/keyd.tar.gz" | sha256sum -c - && \
    tar xzf /tmp/keyd.tar.gz -C /tmp && cd "/tmp/keyd-${KEYD_VERSION}" && \
    make PREFIX=/usr COMMIT="v${KEYD_VERSION}" && \
    install -Dm755 bin/keyd /out/usr/bin/keyd && \
    install -d /out/usr/lib/systemd/system && \
    sed 's#@PREFIX@#/usr#' keyd.service.in > /out/usr/lib/systemd/system/keyd.service && \
    install -Dm644 data/sysusers.d /out/usr/lib/sysusers.d/keyd.conf && \
    install -Dm644 LICENSE /out/usr/share/licenses/keyd/LICENSE

FROM scratch AS ctx
COPY system_files /files
COPY build_files /build_files

FROM ${BASE_IMAGE}

ARG IMAGE_NAME=ravana-os
ARG IMAGE_VENDOR=ravana-os
ARG IMAGE_VERSION=0.1
ARG IMAGE_FLAVOR=main

COPY --from=keyd /out/ /

RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" IMAGE_VERSION="${IMAGE_VERSION}" IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /run/context/build_files/build.sh

LABEL org.opencontainers.image.title="Ravana OS" \
      org.opencontainers.image.description="Lightweight gaming + developer OS" \
      containers.bootc="1" \
      ostree.bootable="true"
