#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-33-registry >/dev/null 2>&1; then
  fail "No container named 'chai-33-registry'. Start it: docker run -d --name chai-33-registry -p 8133:5000 registry:2"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-33-registry)
[ "$state" = "running" ] || fail "chai-33-registry is '$state', not running. Start it (docker start chai-33-registry) or re-run it."
if ! curl -fsS --max-time 5 http://127.0.0.1:8133/v2/ >/dev/null 2>&1; then
  fail "The registry API doesn't answer on http://127.0.0.1:8133/v2/ — publish port 8133 (-p 8133:5000) and re-run."
fi
pass "Local registry 'chai-33-registry' is up on 8133"

ref="localhost:8133/chai-33-api:signed"
index=$(docker buildx imagetools inspect "$ref" 2>/dev/null)
if [ -z "$index" ]; then
  fail "Nothing at $ref in the registry. Build and push with the chai-33-builder: docker buildx build --builder chai-33-builder --sbom=true --provenance=true -t $ref --push ch33"
fi
pass "Image '$ref' exists in your registry"

if ! echo "$index" | grep -q "attestation-manifest"; then
  fail "No attestation manifest riding with $ref — it was pushed without --sbom=true --provenance=true. Rebuild and push again with both flags (and --push)."
fi
pass "The index carries an attestation manifest (the unknown/unknown entry, as promised)"

sbom=$(docker buildx imagetools inspect "$ref" --format '{{ json .SBOM }}' 2>/dev/null)
if [ -z "$sbom" ] || [ "$sbom" = "null" ] || ! echo "$sbom" | grep -i "spdx" >/dev/null; then
  fail "Couldn't extract an SPDX SBOM from $ref. Rebuild with --sbom=true and push again."
fi
pass "SBOM attestation verified — an SPDX inventory ships with the image"

prov=$(docker buildx imagetools inspect "$ref" --format '{{ json .Provenance }}' 2>/dev/null)
if [ -z "$prov" ] || [ "$prov" = "null" ] || ! echo "$prov" | grep -i "slsa" >/dev/null; then
  fail "Couldn't extract SLSA provenance from $ref. Rebuild with --provenance=true and push again."
fi
pass "Provenance attestation verified — the image carries its own birth certificate"

celebrate "Challenge complete. Your registry now serves evidence, not just bits."
