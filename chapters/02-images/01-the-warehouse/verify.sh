#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect nginx:alpine >/dev/null 2>&1; then
  fail "nginx:alpine isn't present locally. Pull it: docker pull nginx:alpine"
fi
pass "nginx:alpine is present locally"

if ! docker image inspect nginx:1.25-alpine >/dev/null 2>&1; then
  fail "nginx:1.25-alpine isn't present locally. Pull it: docker pull nginx:1.25-alpine"
fi
pass "nginx:1.25-alpine is present locally"

if ! docker image inspect chai-04-api:pinned >/dev/null 2>&1; then
  fail "No image named 'chai-04-api:pinned'. Retag the pinned variant: docker tag nginx:1.25-alpine chai-04-api:pinned"
fi
pass "Image 'chai-04-api:pinned' exists"

pinned_id=$(docker image inspect -f '{{.Id}}' chai-04-api:pinned)
nginx_id=$(docker image inspect -f '{{.Id}}' nginx:1.25-alpine)
if [ "$pinned_id" = "$nginx_id" ]; then
  pass "chai-04-api:pinned and nginx:1.25-alpine share one image ID — a retag, not a rebuild"
else
  fail "chai-04-api:pinned is a different image than nginx:1.25-alpine. Remove the tag (docker rmi chai-04-api:pinned) and retag: docker tag nginx:1.25-alpine chai-04-api:pinned"
fi

digestfile="${LAB_WORKSPACE:?}/ch04/digest.txt"
if [ ! -f "$digestfile" ]; then
  fail "No file at workspace/ch04/digest.txt. Write the image's sha256 digest there (see docker images --digests)."
fi

written=$(grep -oE 'sha256:[0-9a-f]{64}' "$digestfile" | head -1)
if [ -z "$written" ]; then
  fail "workspace/ch04/digest.txt doesn't contain a sha256:<64-hex> digest. Try: docker image inspect -f '{{index .RepoDigests 0}}' chai-04-api:pinned"
fi

# The real digest(s) of the pinned image: RepoDigests, plus the ID (which IS
# the manifest digest under the containerd image store).
actual=$(docker image inspect -f '{{range .RepoDigests}}{{println .}}{{end}}{{.Id}}' chai-04-api:pinned | grep -oE 'sha256:[0-9a-f]{64}' | sort -u)
if echo "$actual" | grep -qx "$written"; then
  pass "workspace/ch04/digest.txt matches the image's real digest ($written)"
else
  fail "digest.txt says '$written' but that isn't this image's digest. Read it off the image itself: docker image inspect -f '{{index .RepoDigests 0}}' chai-04-api:pinned"
fi

celebrate "Exercise 4.1 complete. Tags are stickers; you now hold the fingerprint."
