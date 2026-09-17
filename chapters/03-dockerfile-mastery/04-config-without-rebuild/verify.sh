#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

for c in chai-10-demo chai-10-prod; do
  if ! docker container inspect "$c" >/dev/null 2>&1; then
    fail "No container named '$c'. Build chai-10-api:v1 once, then run both: docker run -d --name chai-10-demo -p 8010:3000 chai-10-api:v1 and docker run -d --name chai-10-prod -p 8110:3000 -e MODE=prod chai-10-api:v1"
  fi
  state=$(docker container inspect -f '{{.State.Status}}' "$c")
  if [ "$state" != "running" ]; then
    fail "Container '$c' is '$state', not running. Check docker logs $c, fix, and rerun it."
  fi
done
pass "Both containers exist and are running"

img1=$(docker container inspect -f '{{.Image}}' chai-10-demo)
img2=$(docker container inspect -f '{{.Image}}' chai-10-prod)
if [ "$img1" = "$img2" ]; then
  pass "Both run from the exact same image — one artifact, zero rebuilds"
else
  fail "chai-10-demo and chai-10-prod run DIFFERENT images. The whole point is one build: rebuild once as chai-10-api:v1, then start both containers from it."
fi
ref=$(docker container inspect -f '{{.Config.Image}}' chai-10-demo)
if [ "$ref" != "chai-10-api:v1" ]; then
  fail "The containers run image '$ref' — expected chai-10-api:v1. Rebuild with that tag and rerun both."
fi
pass "And that image is chai-10-api:v1"

env_demo=$(docker container inspect -f '{{range .Config.Env}}{{println .}}{{end}}' chai-10-demo)
if echo "$env_demo" | grep -qx 'MODE=demo'; then
  pass "chai-10-demo's environment carries MODE=demo"
else
  fail "chai-10-demo's environment has no MODE=demo. Bake a default into the image (ENV MODE=demo) or pass -e MODE=demo, then rerun the container."
fi
env_prod=$(docker container inspect -f '{{range .Config.Env}}{{println .}}{{end}}' chai-10-prod)
if echo "$env_prod" | grep -qx 'MODE=prod'; then
  pass "chai-10-prod's environment carries MODE=prod"
else
  fail "chai-10-prod's environment has no MODE=prod. Override at run time: docker run ... -e MODE=prod chai-10-api:v1 (remove the old container first)."
fi

body=$(curl -fsS --max-time 5 http://127.0.0.1:8010/ 2>/dev/null)
if echo "$body" | grep -q '"mode":"demo"'; then
  pass "http://localhost:8010 answers in demo mode"
else
  fail "http://localhost:8010 didn't report \"mode\":\"demo\" (got: '${body:-no response}'). Is chai-10-demo published with -p 8010:3000?"
fi
body=$(curl -fsS --max-time 5 http://127.0.0.1:8110/ 2>/dev/null)
if echo "$body" | grep -q '"mode":"prod"'; then
  pass "http://localhost:8110 answers in prod mode — same image, different personality"
else
  fail "http://localhost:8110 didn't report \"mode\":\"prod\" (got: '${body:-no response}'). Is chai-10-prod published with -p 8110:3000 and running with -e MODE=prod?"
fi

celebrate "Exercise 10.1 complete. Build once, configure everywhere."
