#!/usr/bin/env bash
# Only accept Ravana OS images signed with the Ravana key (cosign.pub in the repo).
set -euxo pipefail
KEY=/etc/pki/containers/ravana-os.pub
test -s "$KEY"
cmp "$KEY" /run/context/files/etc/pki/containers/ravana-os.pub
python3 - <<'PY'
import json
p = "/etc/containers/policy.json"
policy = json.load(open(p))
docker = policy.setdefault("transports", {}).setdefault("docker", {})
docker["ghcr.io/ravana-os"] = [{
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/ravana-os.pub",
    "signedIdentity": {"type": "matchRepository"},
}]
json.dump(policy, open(p, "w"), indent=2)
print(json.dumps(docker["ghcr.io/ravana-os"], indent=2))
PY
