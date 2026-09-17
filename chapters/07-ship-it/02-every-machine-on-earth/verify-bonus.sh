#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect 127.0.0.1:8125/chai-25-api:1.0 >/dev/null 2>&1; then
  fail "No local image 127.0.0.1:8125/chai-25-api:1.0 — pull the amd64 variant: docker pull --platform linux/amd64 127.0.0.1:8125/chai-25-api:1.0"
fi

arch=$(docker image inspect -f '{{.Architecture}}' 127.0.0.1:8125/chai-25-api:1.0)
if [ "$arch" = "amd64" ]; then
  pass "The local copy is the amd64 variant"
else
  fail "The local copy is '$arch' — pull the foreign one explicitly: docker pull --platform linux/amd64 127.0.0.1:8125/chai-25-api:1.0"
fi

archfile="${LAB_WORKSPACE:?}/ch25/arch.txt"
if [ ! -f "$archfile" ]; then
  fail "No file at workspace/ch25/arch.txt. Run the image and capture its output: docker run --rm --name chai-25-probe 127.0.0.1:8125/chai-25-api:1.0 > ./ch25/arch.txt"
fi

if grep -q 'x86_64' "$archfile"; then
  pass "workspace/ch25/arch.txt says x86_64 — an amd64 build artifact, executed on your arm64 machine"
else
  fail "arch.txt says '$(tr -d '[:space:]' < "$archfile")' — expected x86_64. Make sure you pulled with --platform linux/amd64 BEFORE running, then capture the output again."
fi

celebrate "Challenge complete. You just watched QEMU run a foreign CPU's binaries live."
