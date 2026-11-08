#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/yum.repos.d/ravana-build-fedora.repo
dnf5 clean all || true
rm -rf /tmp/* || true
# /var is populated at runtime on bootc systems; ship it empty.
rm -rf /var && mkdir -p /var/tmp && chmod 1777 /var/tmp
bootc container lint
