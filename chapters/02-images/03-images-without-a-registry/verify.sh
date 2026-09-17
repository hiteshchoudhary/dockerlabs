#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

tarfile="${LAB_WORKSPACE:?}/ch06/chai-06-api.tar"
if [ ! -f "$tarfile" ]; then
  fail "No tar at workspace/ch06/chai-06-api.tar. Save the image there: docker save chai-06-api:v1 -o ./ch06/chai-06-api.tar (mkdir -p ch06 first)."
fi
pass "workspace/ch06/chai-06-api.tar exists"

if ! tar -tf "$tarfile" >/dev/null 2>&1; then
  fail "chai-06-api.tar isn't a readable tar archive. Re-create it: docker save chai-06-api:v1 -o ./ch06/chai-06-api.tar"
fi
if ! tar -tf "$tarfile" 2>/dev/null | grep -q '^manifest.json$'; then
  fail "The tar has no manifest.json, so it isn't a 'docker save' image archive (docker export tars won't do here — they're just files). Use: docker save chai-06-api:v1 -o ./ch06/chai-06-api.tar"
fi
pass "It's a genuine image archive (manifest.json present)"

if ! tar -xOf "$tarfile" manifest.json 2>/dev/null | grep -q 'chai-06-api'; then
  fail "The archive's manifest doesn't mention chai-06-api — a different image (or an untagged ID) was saved. Save it by name: docker save chai-06-api:v1 -o ./ch06/chai-06-api.tar"
fi
pass "The archive contains the chai-06-api image, name and all"

if ! docker image inspect chai-06-api:v1 >/dev/null 2>&1; then
  fail "The image 'chai-06-api:v1' isn't present locally — the round-trip isn't closed. Load it back: docker load -i ./ch06/chai-06-api.tar"
fi
pass "Image 'chai-06-api:v1' is present locally — the round-trip is closed"

celebrate "Exercise 6.1 complete. You can ship images anywhere a file can go."
