#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# Image exists
if ! docker image inspect chai-07-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-07-api:v1' found. Build it from workspace/ch07/app: docker build -t chai-07-api:v1 ."
fi
pass "Image 'chai-07-api:v1' exists"

# Builder's mark: the required label proves it was built here, not pulled
title=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.title"}}' chai-07-api:v1 2>/dev/null)
if [ "$title" = "chai-07-api" ]; then
  pass "It carries your builder's mark (org.opencontainers.image.title = chai-07-api)"
else
  fail "The image is missing the label org.opencontainers.image.title=\"chai-07-api\" (got: '${title:-nothing}'). Add a LABEL line to your Dockerfile and rebuild."
fi

# Container running from that image
if ! docker container inspect chai-07-api >/dev/null 2>&1; then
  fail "No container named 'chai-07-api'. Run one: docker run -d --name chai-07-api -p 8007:3000 chai-07-api:v1"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-07-api)
if [ "$state" != "running" ]; then
  fail "Container 'chai-07-api' is '$state', not running. Check its last words with: docker logs chai-07-api — then fix the Dockerfile, rebuild, and rerun."
fi
img=$(docker container inspect -f '{{.Config.Image}}' chai-07-api)
case "$img" in
  chai-07-api:v1) pass "Container 'chai-07-api' is running from chai-07-api:v1" ;;
  *) fail "Container 'chai-07-api' runs image '$img' — expected chai-07-api:v1. Remove it and rerun from your image." ;;
esac

# HTTP answers on 8007
body=$(curl -fsS --max-time 5 http://127.0.0.1:8007/ 2>/dev/null)
if echo "$body" | grep -q '"service":"chaicode-api"'; then
  pass "http://localhost:8007 answers with the ChaiCode API's JSON"
else
  fail "Nothing useful on http://localhost:8007 (got: '${body:-no response}'). Publish the port with -p 8007:3000 and make sure CMD starts the server (docker logs chai-07-api)."
fi

celebrate "Exercise 7.1 complete. That's your app, in your image, running anywhere."
