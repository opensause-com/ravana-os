#!/usr/bin/env bash
# Lower idle RAM on the KDE desktop without removing anything games or dev
# tools depend on. File-based settings live in system_files/.
set -euxo pipefail

# Disable background services that only cost RAM on a gaming/dev box,
# but only if the base actually ships them.
for unit in ModemManager.service; do
    if systemctl list-unit-files "$unit" --no-legend | grep -q .; then
        systemctl disable "$unit" || true
    fi
done
