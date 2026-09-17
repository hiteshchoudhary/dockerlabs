#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

BUDGET=10000000   # 10 MB for the scratch build

if ! docker image inspect chai-11-api:scratch >/dev/null 2>&1; then
  fail "No image 'chai-11-api:scratch'. Switch the final stage to FROM scratch, add -ldflags=\"-s -w\" to go build, and build with -t chai-11-api:scratch"
fi
pass "Image 'chai-11-api:scratch' exists"

size=$(docker image inspect -f '{{.Size}}' chai-11-api:scratch)
mb=$(node -e "console.log(($size/1000000).toFixed(1))")
if [ "$size" -lt "$BUDGET" ]; then
  pass "It weighs ${mb} MB — under the 10 MB budget"
else
  fail "chai-11-api:scratch weighs ${mb} MB — over the 10 MB budget. Final stage must be FROM scratch with only the binary, built with -ldflags=\"-s -w\"."
fi

if ! docker container inspect chai-11-mini >/dev/null 2>&1; then
  fail "No container named 'chai-11-mini'. Run one: docker run -d --name chai-11-mini -p 8111:3000 chai-11-api:scratch"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-11-mini)
if [ "$state" != "running" ]; then
  fail "chai-11-mini is '$state', not running. On scratch there's no shell to blame — check docker logs chai-11-mini; the binary must be static (CGO_ENABLED=0)."
fi
img=$(docker container inspect -f '{{.Config.Image}}' chai-11-mini)
if [ "$img" != "chai-11-api:scratch" ]; then
  fail "chai-11-mini runs image '$img' — expected chai-11-api:scratch. Remove it and rerun."
fi
pass "Container 'chai-11-mini' is running from the scratch image"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8111/ 2>/dev/null)
if echo "$body" | grep -q '"service":"chaicode-api"'; then
  pass "http://localhost:8111 answers from an image that contains nothing but your binary"
else
  fail "No ChaiCode JSON on http://localhost:8111 (got: '${body:-no response}'). Publish with -p 8111:3000."
fi

celebrate "Challenge complete. You've hit the floor: an app with zero operating system."
