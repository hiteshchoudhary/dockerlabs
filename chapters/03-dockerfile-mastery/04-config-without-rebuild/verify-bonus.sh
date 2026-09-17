#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-10-api:stamped >/dev/null 2>&1; then
  fail "No image 'chai-10-api:stamped'. Build it with a stamp: docker build -t chai-10-api:stamped --build-arg BUILD_ID=chai-2026 ."
fi
pass "Image 'chai-10-api:stamped' exists"

ver=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.version"}}' chai-10-api:stamped 2>/dev/null)
if [ -n "$ver" ]; then
  pass "It carries org.opencontainers.image.version = '$ver' (the ARG, frozen into metadata)"
else
  fail "The label org.opencontainers.image.version is empty or missing. Add ARG BUILD_ID + LABEL org.opencontainers.image.version=\$BUILD_ID to the Dockerfile and rebuild with --build-arg BUILD_ID=<something>."
fi

runtime_env=$(docker image inspect -f '{{range .Config.Env}}{{println .}}{{end}}' chai-10-api:stamped)
if echo "$runtime_env" | grep -q '^BUILD_ID='; then
  fail "BUILD_ID leaked into the image's runtime environment — you used ENV, not ARG. Declare it as ARG BUILD_ID (build-time only) and rebuild."
else
  pass "BUILD_ID is nowhere in the runtime environment — the ARG evaporated after the build"
fi

celebrate "Challenge complete. Every image you ship can now say which build it came from."
