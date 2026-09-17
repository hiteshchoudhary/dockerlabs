#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-12-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-12-api:v1' found. Build it from workspace/ch12/app: docker build -t chai-12-api:v1 ."
fi
pass "Image 'chai-12-api:v1' exists"

hc=$(docker image inspect -f '{{if .Config.Healthcheck}}{{join .Config.Healthcheck.Test " "}}{{end}}' chai-12-api:v1)
if [ -n "$hc" ] && [ "$hc" != "NONE" ]; then
  pass "It has a HEALTHCHECK baked in"
else
  fail "The image has no HEALTHCHECK. Add one to the Dockerfile (probe http://127.0.0.1:3000/health with wget) and rebuild."
fi

title=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.title"}}' chai-12-api:v1 2>/dev/null)
if [ "$title" = "chai-12-api" ]; then
  pass "Label org.opencontainers.image.title = chai-12-api"
else
  fail "Label org.opencontainers.image.title should be 'chai-12-api' (got: '${title:-nothing}'). Fix the LABEL line and rebuild."
fi
desc=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.description"}}' chai-12-api:v1 2>/dev/null)
if [ -n "$desc" ]; then
  pass "Label org.opencontainers.image.description is set"
else
  fail "Label org.opencontainers.image.description is missing or empty. Add it and rebuild."
fi
authors=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.authors"}}' chai-12-api:v1 2>/dev/null)
if [ -n "$authors" ]; then
  pass "Label org.opencontainers.image.authors is set ($authors)"
else
  fail "Label org.opencontainers.image.authors is missing or empty. Add it and rebuild."
fi

if ! docker container inspect chai-12-api >/dev/null 2>&1; then
  fail "No container named 'chai-12-api'. Run one: docker run -d --name chai-12-api -p 8012:3000 chai-12-api:v1"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-12-api)
if [ "$state" != "running" ]; then
  fail "Container 'chai-12-api' is '$state', not running. Check docker logs chai-12-api."
fi
img=$(docker container inspect -f '{{.Config.Image}}' chai-12-api)
if [ "$img" != "chai-12-api:v1" ]; then
  fail "Container 'chai-12-api' runs image '$img' — expected chai-12-api:v1. Remove it and rerun from your image."
fi
pass "Container 'chai-12-api' is running from chai-12-api:v1"

# Wait for the health state machine: starting -> healthy
health=""
for _ in $(seq 1 30); do
  health=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' chai-12-api)
  [ "$health" = "healthy" ] && break
  sleep 2
done
if [ "$health" = "healthy" ]; then
  pass "Health status is 'healthy' — the container is taking its own pulse"
else
  fail "Health status is '${health:-none}' after 60s, not 'healthy'. Read the probe's own words: docker inspect -f '{{json .State.Health}}' chai-12-api — does the check hit http://127.0.0.1:3000/health with wget?"
fi

body=$(curl -fsS --max-time 5 http://127.0.0.1:8012/health 2>/dev/null)
if echo "$body" | grep -q '"status":"healthy"'; then
  pass "http://localhost:8012/health answers healthy from the host, too"
else
  fail "http://localhost:8012/health didn't answer (got: '${body:-no response}'). Publish the port with -p 8012:3000."
fi

celebrate "Exercise 12.1 complete — and with it, Part 3. Your images now testify about themselves."
