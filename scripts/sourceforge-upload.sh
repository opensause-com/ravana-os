#!/usr/bin/env bash
# Upload live ISOs to SourceForge (fast worldwide mirrors, direct .iso links, no sign-in).
#
# Usage: scripts/sourceforge-upload.sh <testing|latest> <stamp> <edition>-live.iso...
#
# Layout on SourceForge:
#   testing/<edition>/<edition>-testing-<stamp>-live.iso    only the newest testing ISO is kept
#   releases/<version>-<stamp>/<edition>-<version>-<stamp>-live.iso
#
# Needs: SF_SSH_KEY (private key added to the SourceForge account), SF_USER, SF_PROJECT.
# Optional: SF_API_KEY, makes the stable AMD/Intel ISO the project's big green "Download" button.
set -euo pipefail

: "${SF_SSH_KEY:?SF_SSH_KEY is not set}" "${SF_USER:?SF_USER is not set}" "${SF_PROJECT:?SF_PROJECT is not set}"
CHANNEL="$1" STAMP="$2"
shift 2
VERSION="${VERSION:-$(sed -n 's/^ARG IMAGE_VERSION=//p' Containerfile)}"

KEY="$(mktemp)"
trap 'rm -f "$KEY"' EXIT
printf '%s\n' "$SF_SSH_KEY" > "$KEY"
chmod 600 "$KEY"
mkdir -p ~/.ssh
ssh-keyscan -t ed25519,rsa frs.sourceforge.net >> ~/.ssh/known_hosts 2>/dev/null
SSH="ssh -i $KEY -o IdentitiesOnly=yes -o BatchMode=yes"
FRS="$SF_USER@frs.sourceforge.net:/home/frs/project/$SF_PROJECT"

for iso in "$@"; do
  edition="$(basename "$iso" -live.iso)"
  if [ "$CHANNEL" = testing ]; then
    name="$edition-testing-$STAMP-live.iso"
    dest="testing/$edition"
    prune=(--delete)          # keep only the newest testing ISO per edition
  else
    name="$edition-$VERSION-$STAMP-live.iso"
    dest="releases/$VERSION-$STAMP"
    prune=()
  fi

  stage="$(mktemp -d -p "$(dirname "$iso")")"
  ln "$iso" "$stage/$name"
  (cd "$stage" && sha256sum "$name" > "$name.sha256")

  echo "Uploading $name to $dest"
  rsync -e "$SSH" -v --partial --mkpath --times "${prune[@]}" "$stage/" "$FRS/$dest/"
  rm -rf "$stage"

  if [ "$CHANNEL" != testing ] && [ "$edition" = ravana-os ] && [ -n "${SF_API_KEY:-}" ]; then
    curl -fsS -H "Accept: application/json" -X PUT \
      -d "default=windows&default=mac&default=linux&default=bsd&default=solaris&default=others" \
      -d "api_key=$SF_API_KEY" \
      "https://sourceforge.net/projects/$SF_PROJECT/files/$dest/$name" >/dev/null \
      && echo "Set as the default download"
  fi

  echo "Download: https://sourceforge.net/projects/$SF_PROJECT/files/$dest/$name/download"
done
