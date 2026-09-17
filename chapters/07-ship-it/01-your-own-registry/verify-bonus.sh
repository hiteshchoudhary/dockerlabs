#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-24-registry >/dev/null 2>&1; then
  fail "chai-24-registry doesn't exist — finish the main exercise first."
fi

registry_digest=$(curl -fsSI --max-time 5 \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json' \
  http://127.0.0.1:8124/v2/chai-24-api/manifests/1.0 2>/dev/null \
  | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')
if [ -z "$registry_digest" ]; then
  fail "Couldn't read the manifest digest for chai-24-api:1.0 from the registry — is the image pushed and the registry up? Finish the main exercise first."
fi
pass "Registry says chai-24-api:1.0 is $registry_digest"

if ! docker image inspect chai-24-api:roundtrip >/dev/null 2>&1; then
  fail "No local image named 'chai-24-api:roundtrip'. Pull it back and alias it: docker pull 127.0.0.1:8124/chai-24-api:1.0 && docker tag 127.0.0.1:8124/chai-24-api:1.0 chai-24-api:roundtrip"
fi
pass "Image 'chai-24-api:roundtrip' exists"

if docker image inspect -f '{{json .RepoDigests}}' chai-24-api:roundtrip | grep -q "$registry_digest"; then
  pass "Its repo digest matches the registry's digest — the round trip changed nothing"
else
  local_digests=$(docker image inspect -f '{{json .RepoDigests}}' chai-24-api:roundtrip)
  fail "Digest mismatch: registry says $registry_digest but the local image carries $local_digests. Re-pull from the registry (docker pull 127.0.0.1:8124/chai-24-api:1.0) and retag that pulled image as chai-24-api:roundtrip."
fi

celebrate "Challenge complete. Content addressing means what you pull is what you pushed — provably."
