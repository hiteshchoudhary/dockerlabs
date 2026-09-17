#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

BUDGET=20000000   # 20 MB, as measured by docker image inspect .Size

if ! docker image inspect chai-11-api:slim >/dev/null 2>&1; then
  fail "No image 'chai-11-api:slim' found. Build it from workspace/ch11/app: docker build -t chai-11-api:slim ."
fi
pass "Image 'chai-11-api:slim' exists"

size=$(docker image inspect -f '{{.Size}}' chai-11-api:slim)
mb=$(node -e "console.log(($size/1000000).toFixed(1))")
if [ "$size" -lt "$BUDGET" ]; then
  pass "It weighs ${mb} MB — under the 20 MB budget"
else
  fail "chai-11-api:slim weighs ${mb} MB — over the 20 MB budget. You're almost certainly shipping the Go toolchain: make sure the FINAL stage is FROM alpine and only COPY --from=build the binary, then rebuild."
fi

if ! docker container inspect chai-11-api >/dev/null 2>&1; then
  fail "No container named 'chai-11-api'. Run one: docker run -d --name chai-11-api -p 8011:3000 chai-11-api:slim"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-11-api)
if [ "$state" != "running" ]; then
  fail "Container 'chai-11-api' is '$state', not running. Check docker logs chai-11-api — does CMD point at the path you copied the binary to?"
fi
img=$(docker container inspect -f '{{.Config.Image}}' chai-11-api)
if [ "$img" != "chai-11-api:slim" ]; then
  fail "Container 'chai-11-api' runs image '$img' — expected chai-11-api:slim. Remove it and rerun from your slim image."
fi
pass "Container 'chai-11-api' is running from chai-11-api:slim"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8011/ 2>/dev/null)
if echo "$body" | grep -q '"lang":"go"' && echo "$body" | grep -q '"service":"chaicode-api"'; then
  pass "http://localhost:8011 answers — the Go rewrite is serving"
else
  fail "http://localhost:8011 didn't return the Go API's JSON (got: '${body:-no response}'). Publish with -p 8011:3000 and check docker logs chai-11-api."
fi

celebrate "Exercise 11.1 complete. Same app, a tenth of the megabytes."
