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

# macOS-style GTK theme for GTK/libadwaita apps, Flatpaks, Firefox and Chrome
# (WhiteSur, MIT, github.com/vinceliuice/WhiteSur-gtk-theme), red accent, pinned.
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS gtktheme
ARG WS_VERSION=2026-09-10
ARG WS_SHA256=65516c8f45da45c602471e31b4de0b6e9aed6eb3fc3820df16161d077245a1a2
RUN dnf -y install --setopt=install_weak_deps=False sassc glib2-devel libxml2 bc which findutils xz \
        util-linux shadow-utils && \
    curl -fsSL -o /tmp/ws.tar.gz "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/${WS_VERSION}.tar.gz" && \
    echo "${WS_SHA256}  /tmp/ws.tar.gz" | sha256sum -c - && \
    tar xzf /tmp/ws.tar.gz -C /tmp && WS="/tmp/WhiteSur-gtk-theme-${WS_VERSION}" && \
    mkdir -p /out/usr/share/themes && \
    tar xJf "$WS/release/WhiteSur-Dark.tar.xz" -C /out/usr/share/themes && \
    tar xJf "$WS/release/WhiteSur-Light.tar.xz" -C /out/usr/share/themes && \
    useradd -m builder && cp -r "$WS" /home/builder/ws && chown -R builder /home/builder/ws && \
    (runuser -u builder -- bash -c 'cd ~/ws && USER=builder HOME=/home/builder ./install.sh -l -t red -c dark' || true) && \
    test -f /home/builder/.config/gtk-4.0/gtk.css && \
    install -d /out/usr/share/ravana/gtk-4.0 && cp -rL /home/builder/.config/gtk-4.0/. /out/usr/share/ravana/gtk-4.0/ && \
    install -Dm644 "$WS/COPYING" /out/usr/share/licenses/whitesur-gtk-theme/COPYING && \
    ls /out/usr/share/themes /out/usr/share/ravana/gtk-4.0

# Rounded window corners on every window, macOS style (KDE-Rounded-Corners, GPL-3.0).
# Built against the base image's exact KWin so the plugin matches it. If Fedora has
# no matching kwin-devel, the stage installs nothing and windows keep square bottoms.
FROM ${BASE_IMAGE} AS roundcorners
ARG RC_VERSION=0.11.0
ARG RC_SHA256=73833c9835262ad212075539edad771af75adc5be62ef027e55e09da2b97f0cb
COPY build_files/fedora-build.repo /etc/yum.repos.d/ravana-build-fedora.repo
RUN set -eux; mkdir -p /out; \
    KV="$(rpm -q --qf '%{VERSION}-%{RELEASE}' kwin)"; echo "kwin $KV"; \
    if dnf5 install -y --setopt=install_weak_deps=False --repo=ravana-build-fedora --repo=ravana-build-updates \
        cmake gcc-c++ extra-cmake-modules "kwin-devel-$KV" kf6-kconfigwidgets-devel libepoxy-devel \
        kf6-kcmutils-devel kf6-ki18n-devel qt6-qtbase-private-devel wayland-devel libdrm-devel; then \
      curl -fsSL -o /tmp/rc.tar.gz "https://github.com/matinlotfali/KDE-Rounded-Corners/archive/refs/tags/v${RC_VERSION}.tar.gz"; \
      echo "${RC_SHA256}  /tmp/rc.tar.gz" | sha256sum -c -; \
      tar xzf /tmp/rc.tar.gz -C /tmp; cd "/tmp/KDE-Rounded-Corners-${RC_VERSION}"; \
      cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release; \
      cmake --build build -j"$(nproc)"; DESTDIR=/out cmake --install build; \
      install -Dm644 LICENSE /out/usr/share/licenses/kwin-effect-roundcorners/LICENSE; \
      find /out -type f | head -20; \
    else echo "WARNING: no kwin-devel $KV in Fedora; rounded corners skipped"; fi

FROM scratch AS ctx
COPY system_files /files
COPY build_files /build_files

FROM ${BASE_IMAGE}

ARG IMAGE_NAME=ravana-os
ARG IMAGE_VENDOR=ravana-os
ARG IMAGE_VERSION=0.1
ARG IMAGE_FLAVOR=main

COPY --from=keyd /out/ /
COPY --from=roundcorners /out/ /
COPY --from=gtktheme /out/ /

RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" IMAGE_VERSION="${IMAGE_VERSION}" IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /run/context/build_files/build.sh

LABEL org.opencontainers.image.title="Ravana OS" \
      org.opencontainers.image.description="Lightweight gaming + developer OS" \
      containers.bootc="1" \
      ostree.bootable="true"
