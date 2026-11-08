#!/usr/bin/env bash
# Entry point: copy system_files over /, then run NN-*.sh scripts in order.
set -euo pipefail
CONTEXT=/run/context
cp -avf "$CONTEXT/files/." /
for script in $(find "$CONTEXT/build_files" -maxdepth 1 -name '[0-9]*-*.sh' | sort -V); do
    echo "::group:: ===== $(basename "$script") ====="
    bash "$script"
    echo "::endgroup::"
done
