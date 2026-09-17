#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# 1.0.1 exists in the registry
tags=$(curl -fsS --max-time 10 "http://127.0.0.1:8146/v2/chai-46-api/tags/list" 2>/dev/null)
has=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log((j.tags||[]).includes("1.0.1")?"yes":"no")}catch(e){console.log("no")}' "$tags")
if [ "$has" != "yes" ]; then
  fail "The registry has no chai-46-api:1.0.1 (tags: ${tags:-none}). Build with --build-arg APP_VERSION=1.0.1 and push it."
fi
pass "chai-46-api:1.0.1 is in the registry"

# The running api IS 1.0.1
apiref=$(docker container inspect -f '{{.Config.Image}}' chai-45-api 2>/dev/null)
if [ "$apiref" != "127.0.0.1:8146/chai-46-api:1.0.1" ]; then
  fail "The running api's image is '${apiref:-missing}' — update compose.registry.yaml to :1.0.1 and re-run: docker compose -f compose.registry.yaml up -d --wait"
fi
pass "Running api container uses 127.0.0.1:8146/chai-46-api:1.0.1"

h=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' chai-45-api)
[ "$h" = "healthy" ] || fail "The upgraded api is '$h', not healthy — check: docker compose -f compose.registry.yaml logs api"
pass "The upgraded api is healthy"

# The version is baked into the IMAGE (build-arg, not a run-time env override)
imgver=$(docker image inspect -f '{{range .Config.Env}}{{println .}}{{end}}' 127.0.0.1:8146/chai-46-api:1.0.1 2>/dev/null | grep '^APP_VERSION=' | cut -d= -f2)
if [ "$imgver" != "1.0.1" ]; then
  fail "The 1.0.1 image bakes in APP_VERSION='${imgver:-unset}' — rebuild with: docker build --build-arg APP_VERSION=1.0.1 -t 127.0.0.1:8146/chai-46-api:1.0.1 ../ch45/api (then push and re-up)."
fi
pass "APP_VERSION=1.0.1 is baked into the image itself"

# And the release answers live
status=$(curl -sS --max-time 15 http://127.0.0.1:8045/api/status 2>/dev/null)
ver=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log(j.version||"missing")}catch(e){console.log("unparseable")}' "$status")
if [ "$ver" != "1.0.1" ]; then
  fail "/api/status reports version '$ver' — expected 1.0.1. Did the api actually get recreated? docker compose -f compose.registry.yaml up -d --wait"
fi
pass "Live response says version 1.0.1"

celebrate "Challenge complete — and so is the book. 46 chapters, one platform, shipped from your own registry. Kubernetes next: bring these images."
