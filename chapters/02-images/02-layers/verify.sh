#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-05-snapshot:v1 >/dev/null 2>&1; then
  fail "No image named 'chai-05-snapshot:v1'. Freeze your container's writable layer: docker commit chai-05-lab chai-05-snapshot:v1"
fi
pass "Image 'chai-05-snapshot:v1' exists"

inside=$(docker run --rm --name chai-05-probe chai-05-snapshot:v1 cat /app/build-info.txt 2>/dev/null)
if [ "$inside" = "assembled by hand" ]; then
  pass "A probe container from the image finds /app/build-info.txt saying 'assembled by hand'"
else
  fail "/app/build-info.txt in the image is missing or wrong (got: '${inside:-nothing}'). Create it inside chai-05-lab (docker exec ... sh -c '...'), then commit again: docker commit chai-05-lab chai-05-snapshot:v1"
fi

if ! docker image inspect alpine >/dev/null 2>&1; then
  fail "The 'alpine' image isn't present locally, so the layer comparison can't run. Pull it (docker pull alpine) — the snapshot must be built on it."
fi

layers=$(docker image inspect -f '{{len .RootFS.Layers}}' chai-05-snapshot:v1)
base_layers=$(docker image inspect -f '{{len .RootFS.Layers}}' alpine)
if [ "$layers" -gt "$base_layers" ]; then
  pass "The snapshot has $layers layers vs alpine's $base_layers — your writable layer is frozen on top"
else
  fail "chai-05-snapshot:v1 has no extra layer over alpine ($layers vs $base_layers). Commit the container you modified, not a fresh one: docker commit chai-05-lab chai-05-snapshot:v1"
fi

base_first=$(docker image inspect -f '{{index .RootFS.Layers 0}}' alpine)
snap_first=$(docker image inspect -f '{{index .RootFS.Layers 0}}' chai-05-snapshot:v1)
if [ "$base_first" = "$snap_first" ]; then
  pass "Its bottom layer is alpine's layer, bit for bit — shared, not copied"
else
  fail "The snapshot's bottom layer isn't alpine's — it wasn't committed from an alpine container. Start over from: docker run -d --name chai-05-lab alpine sleep 3600"
fi

top_comment=$(docker history --format '{{.Comment}}' chai-05-snapshot:v1 2>/dev/null | head -1)
if [ "$top_comment" = "buildkit.dockerfile.v0" ]; then
  fail "chai-05-snapshot:v1 was produced by a Dockerfile build, not docker commit. This one time, fall into the trap on purpose: docker commit chai-05-lab chai-05-snapshot:v1"
fi
pass "The top layer came from a commit, not a Dockerfile build"

celebrate "Exercise 5.1 complete. You've built an image by hand — and now you know why nobody does."
