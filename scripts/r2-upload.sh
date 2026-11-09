#!/usr/bin/env bash
# Upload live ISOs to Cloudflare R2 (free downloads, fast worldwide, direct .iso links),
# staying inside R2's free 10 GB of storage.
#
# Usage: scripts/r2-upload.sh <channel> <edition>-live.iso...
#
# Rules that keep storage under the free limit:
#   - only editions in R2_EDITIONS are uploaded (default: ravana-os, the AMD/Intel ISO)
#   - only the channel in R2_CHANNEL is uploaded (default: testing); each upload
#     replaces the previous file at the same address instead of adding a new one
#   - before uploading, the bucket total is checked; if the new file would take it
#     past R2_LIMIT_GB (default 9.5), the upload is skipped with a warning
#   - leftover parts of interrupted uploads (which also use storage) are removed first
#
# Address: <R2_PUBLIC_URL>/<channel>/<edition>-live.iso (+ .sha256)
# Needs: R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ACCOUNT_ID, R2_BUCKET.
set -euo pipefail
: "${R2_ACCESS_KEY_ID:?}" "${R2_SECRET_ACCESS_KEY:?}" "${R2_ACCOUNT_ID:?}" "${R2_BUCKET:?}"
CHANNEL="$1"; shift
EDITIONS="${R2_EDITIONS:-ravana-os}"
WANT_CHANNEL="${R2_CHANNEL:-testing}"
LIMIT=$(awk -v g="${R2_LIMIT_GB:-9.5}" 'BEGIN {printf "%d", g * 1e9}')
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" AWS_DEFAULT_REGION=auto
EP=(--endpoint-url "https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com")

if [ "$CHANNEL" != "$WANT_CHANNEL" ]; then
    echo "R2 holds the $WANT_CHANNEL channel only; skipping $CHANNEL."
    exit 0
fi

# Remove parts of interrupted uploads
aws s3api list-multipart-uploads "${EP[@]}" --bucket "$R2_BUCKET" \
    --query 'Uploads[].[Key,UploadId]' --output text 2>/dev/null | while read -r key id; do
    [ -n "$key" ] && [ "$key" != "None" ] || continue
    echo "Removing unfinished upload of $key"
    aws s3api abort-multipart-upload "${EP[@]}" --bucket "$R2_BUCKET" --key "$key" --upload-id "$id"
done

bucket_total() {
    local t
    t=$(aws s3api list-objects-v2 "${EP[@]}" --bucket "$R2_BUCKET" --query 'Contents[].Size' --output text 2>/dev/null \
        | tr '\t' '\n' | grep -E '^[0-9]+$' | awk '{s+=$1} END {printf "%d", s}')
    echo "${t:-0}"
}
object_size() {
    local n
    n=$(aws s3api head-object "${EP[@]}" --bucket "$R2_BUCKET" --key "$1" --query ContentLength --output text 2>/dev/null) || n=0
    [[ "$n" =~ ^[0-9]+$ ]] || n=0
    echo "$n"
}
gb() { awk -v b="$1" 'BEGIN {printf "%.2f", b / 1e9}'; }

for iso in "$@"; do
    name="$(basename "$iso")"
    edition="${name%-live.iso}"
    if ! [[ " $EDITIONS " == *" $edition "* ]]; then
        echo "R2 holds $EDITIONS only; skipping $name (it stays a GitHub download)."
        continue
    fi
    [ -f "$iso.sha256" ] || (cd "$(dirname "$iso")" && sha256sum "$name" > "$name.sha256")
    key="$CHANNEL/$name"
    total=$(bucket_total); old=$(object_size "$key"); new=$(stat -c %s "$iso")
    after=$(( total - old + new ))
    echo "Bucket now $(gb "$total") GB; after replacing $name: $(gb "$after") GB (limit $(gb "$LIMIT") GB)"
    if [ "$after" -gt "$LIMIT" ]; then
        echo "::warning::Skipping R2 upload of $name: it would take the bucket past the free-storage limit"
        continue
    fi
    aws s3 cp "${EP[@]}" --only-show-errors --content-type application/x-iso9660-image "$iso" "s3://$R2_BUCKET/$key"
    aws s3 cp "${EP[@]}" --only-show-errors --content-type text/plain "$iso.sha256" "s3://$R2_BUCKET/$key.sha256"
    echo "Bucket after upload: $(gb "$(bucket_total)") GB"
    echo "Download: ${R2_PUBLIC_URL:-https://<public-url>}/$key"
done
