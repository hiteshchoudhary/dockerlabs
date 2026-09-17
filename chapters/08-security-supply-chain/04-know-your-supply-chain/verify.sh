#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

df="${LAB_WORKSPACE:?}/ch33/Dockerfile"
if [ ! -f "$df" ]; then
  fail "No Dockerfile at workspace/ch33/Dockerfile. Write one whose FROM pins alpine by digest (alpine@sha256:...)."
fi
pass "workspace/ch33/Dockerfile exists"

fromline=$(grep -iE '^[[:space:]]*FROM[[:space:]]' "$df" | head -n1)
if ! echo "$fromline" | grep -qiE 'alpine(:[^@[:space:]]+)?@sha256:[0-9a-f]{64}'; then
  fail "The FROM line is '${fromline:-missing}' — expected alpine pinned by digest, e.g. FROM alpine@sha256:<64 hex chars>. Fetch the real one: docker image inspect -f '{{index .RepoDigests 0}}' alpine"
fi
pass "FROM pins alpine with an @sha256: digest"

digest=$(echo "$fromline" | grep -oE 'sha256:[0-9a-f]{64}' | head -n1)
if ! docker image inspect "alpine@$digest" >/dev/null 2>&1; then
  fail "The digest in your FROM ($digest) doesn't match any alpine image on this machine — content addressing doesn't negotiate. Run docker pull alpine, then copy the digest from: docker image inspect -f '{{index .RepoDigests 0}}' alpine"
fi
pass "The digest is genuine — it resolves to a real alpine image locally"

if ! docker image inspect chai-33-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-33-api:v1'. Build it from workspace/ch33: docker build -t chai-33-api:v1 ."
fi
pass "Image 'chai-33-api:v1' exists"

title=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.title"}}' chai-33-api:v1)
if [ "$title" != "chai-33-api" ]; then
  fail "Label org.opencontainers.image.title is '${title:-unset}' — expected 'chai-33-api'. Add: LABEL org.opencontainers.image.title=\"chai-33-api\" and rebuild."
fi
pass "OCI title label is set"

baselayer=$(docker image inspect -f '{{index .RootFS.Layers 0}}' "alpine@$digest" 2>/dev/null)
builtlayer=$(docker image inspect -f '{{index .RootFS.Layers 0}}' chai-33-api:v1 2>/dev/null)
if [ -z "$baselayer" ] || [ "$baselayer" != "$builtlayer" ]; then
  fail "chai-33-api:v1's bottom layer doesn't match the pinned base's — the image wasn't built FROM the digest in your Dockerfile. Rebuild: docker build -t chai-33-api:v1 workspace/ch33"
fi
pass "Bottom layer of chai-33-api:v1 is byte-identical to the pinned base — ancestry proven"

celebrate "Exercise 33.1 complete. Nobody re-points your base image now — not even its maintainers."
