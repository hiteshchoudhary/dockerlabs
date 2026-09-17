#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-07-api >/dev/null 2>&1; then
  fail "chai-07-api doesn't exist — finish the main exercise first."
fi
if ! docker container inspect chai-07-copy >/dev/null 2>&1; then
  fail "No container named 'chai-07-copy'. Run a second one from the same image: docker run -d --name chai-07-copy -p 8107:3000 chai-07-api:v1"
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-07-copy)
if [ "$state" != "running" ]; then
  fail "chai-07-copy is '$state', not running. Check docker logs chai-07-copy, or was port 8107 taken?"
fi
pass "Second container 'chai-07-copy' is running"

img1=$(docker container inspect -f '{{.Image}}' chai-07-api)
img2=$(docker container inspect -f '{{.Image}}' chai-07-copy)
if [ "$img1" = "$img2" ]; then
  pass "Both containers run from the exact same image (one class, two objects)"
else
  fail "chai-07-copy runs a different image than chai-07-api. Start it from chai-07-api:v1 without rebuilding."
fi

body=$(curl -fsS --max-time 5 http://127.0.0.1:8107/ 2>/dev/null)
if echo "$body" | grep -q '"service":"chaicode-api"'; then
  pass "http://localhost:8107 answers too"
else
  fail "No ChaiCode JSON on http://localhost:8107. Publish the port: -p 8107:3000."
fi

celebrate "Challenge complete. One image, as many containers as you like."
