#!/usr/bin/env bash
# Upload live ISOs to Cloudflare R2 (free downloads, fast worldwide, direct .iso links).
#
# Usage: scripts/r2-upload.sh <testing|latest> <edition>-live.iso...
#
# Each channel keeps one copy per edition at a fixed address (replaced on every build):
#   <R2_PUBLIC_URL>/testing/ravana-os-live.iso   (+ .sha256)
#   <R2_PUBLIC_URL>/latest/ravana-os-nvidia-live.iso
#
# Needs: R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY (R2 API token, Object Read & Write),
#        R2_ACCOUNT_ID, R2_BUCKET; optional R2_PUBLIC_URL for the printed links.
set -euo pipefail
: "${R2_ACCESS_KEY_ID:?}" "${R2_SECRET_ACCESS_KEY:?}" "${R2_ACCOUNT_ID:?}" "${R2_BUCKET:?}"
CHANNEL="$1"; shift
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" AWS_DEFAULT_REGION=auto
ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
for iso in "$@"; do
    name="$(basename "$iso")"
    [ -f "$iso.sha256" ] || (cd "$(dirname "$iso")" && sha256sum "$name" > "$name.sha256")
    echo "Uploading $name to $CHANNEL/"
    aws s3 cp --endpoint-url "$ENDPOINT" --only-show-errors \
        --content-type application/x-iso9660-image "$iso" "s3://$R2_BUCKET/$CHANNEL/$name"
    aws s3 cp --endpoint-url "$ENDPOINT" --only-show-errors \
        --content-type text/plain "$iso.sha256" "s3://$R2_BUCKET/$CHANNEL/$name.sha256"
    echo "Download: ${R2_PUBLIC_URL:-https://<public-url>}/$CHANNEL/$name"
done
