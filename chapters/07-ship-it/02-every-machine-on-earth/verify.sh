#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-25-registry >/dev/null 2>&1; then
  fail "No container named 'chai-25-registry' found. Start it: docker run -d --name chai-25-registry -p 8125:5000 registry:2"
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-25-registry)
if [ "$state" = "running" ]; then
  pass "chai-25-registry is running"
else
  fail "chai-25-registry is '$state' — start it: docker start chai-25-registry"
fi

catalog=$(curl -fsS --max-time 5 http://127.0.0.1:8125/v2/_catalog 2>/dev/null)
if [ -z "$catalog" ]; then
  fail "Nothing answers on http://127.0.0.1:8125/v2/_catalog — publish port 5000 on 8125: docker rm -f chai-25-registry && docker run -d --name chai-25-registry -p 8125:5000 registry:2"
fi
pass "The registry answers on host port 8125"

if ! echo "$catalog" | grep -q '"chai-25-api"'; then
  fail "Catalog says $catalog — no 'chai-25-api' yet. Build and push it with buildx (see the chapter's full invocation; the tag must be 127.0.0.1:8125/chai-25-api:1.0)."
fi
pass "Catalog lists chai-25-api"

manifest=$(docker buildx imagetools inspect 127.0.0.1:8125/chai-25-api:1.0 2>/dev/null)
if [ -z "$manifest" ]; then
  fail "Couldn't read a manifest for 127.0.0.1:8125/chai-25-api:1.0 — was the buildx push tagged :1.0? Re-run the buildx build with -t 127.0.0.1:8125/chai-25-api:1.0"
fi

if echo "$manifest" | grep -q 'linux/amd64'; then
  pass "Manifest list contains linux/amd64"
else
  fail "The manifest for chai-25-api:1.0 has no linux/amd64 entry. Build BOTH platforms in one command: --platform linux/amd64,linux/arm64"
fi

if echo "$manifest" | grep -q 'linux/arm64'; then
  pass "Manifest list contains linux/arm64"
else
  fail "The manifest for chai-25-api:1.0 has no linux/arm64 entry. Build BOTH platforms in one command: --platform linux/amd64,linux/arm64"
fi

celebrate "Exercise 25.1 complete. One tag, every CPU that matters."
