#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-43-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-43-api:v1'. Build it: docker build -t chai-43-api:v1 ./ch43"
fi
pass "Image 'chai-43-api:v1' exists"

size=$(docker image inspect -f '{{.Size}}' chai-43-api:v1)
if [ "$size" -lt 20000000 ]; then
  pass "Image is tiny: $((size / 1000000)) MB — the Go toolchain stayed behind"
else
  fail "Image is $((size / 1000000)) MB — that's not a scratch image. Make sure the final stage is 'FROM scratch' copying only the binary (the scaffold Dockerfile does this)."
fi

layers=$(docker image inspect -f '{{len .RootFS.Layers}}' chai-43-api:v1)
if [ "$layers" -le 2 ]; then
  pass "Only $layers layer(s) — nothing shipped but the binary"
else
  fail "Image has $layers layers — a scratch final stage should have 1. Rebuild from the scaffold Dockerfile."
fi

if ! docker container inspect chai-43-api >/dev/null 2>&1; then
  fail "No container 'chai-43-api'. Run it: docker run -d --name chai-43-api -p 8043:8043 chai-43-api:v1"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-43-api)
[ "$state" = "running" ] || fail "chai-43-api is '$state', not running. Check 'docker logs chai-43-api', then recreate it."
pass "Container 'chai-43-api' is running"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8043/ 2>/dev/null)
if echo "$body" | grep -q "chai-43-api"; then
  pass "Answers on port 8043"
else
  fail "Nothing useful on http://localhost:8043 — publish the port: docker run -d --name chai-43-api -p 8043:8043 chai-43-api:v1"
fi

NOSHELL="${LAB_WORKSPACE:?}/ch43/noshell.txt"
if [ ! -f "$NOSHELL" ]; then
  fail "No workspace/ch43/noshell.txt — try to exec a shell and capture the failure: docker exec chai-43-api sh > ./ch43/noshell.txt 2>&1"
fi
if grep -Eqi 'executable file not found|no such file' "$NOSHELL"; then
  pass "noshell.txt holds the proof: no shell exists in this image"
else
  fail "noshell.txt doesn't contain the runtime's failure text. Capture both streams: docker exec chai-43-api sh > ./ch43/noshell.txt 2>&1"
fi

FINDINGS="${LAB_WORKSPACE}/ch43/findings.txt"
if [ ! -f "$FINDINGS" ]; then
  fail "No workspace/ch43/findings.txt — extract the entrypoint with docker inspect and write 'entrypoint=<path>' there."
fi
expected=$(docker inspect -f '{{.Path}}' chai-43-api)
written=$(grep '^entrypoint=' "$FINDINGS" | head -1 | cut -d= -f2- | tr -d '[:space:]')
if [ -n "$written" ] && [ "$written" = "$expected" ]; then
  pass "findings.txt matches reality: PID 1 is $expected"
else
  fail "findings.txt says 'entrypoint=${written:-nothing}' but the container actually runs '$expected'. Use: docker inspect -f '{{.Path}}' chai-43-api"
fi

celebrate "Exercise 43.1 complete. A box with no doors, and you read it anyway."
