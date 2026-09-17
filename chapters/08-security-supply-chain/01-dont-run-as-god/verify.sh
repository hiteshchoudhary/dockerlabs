#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# --- image ---
if ! docker image inspect chai-30-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-30-api:v1' found. Build it from workspace/ch30/app: docker build -t chai-30-api:v1 ."
fi
pass "Image 'chai-30-api:v1' exists"

imguser=$(docker image inspect -f '{{.Config.User}}' chai-30-api:v1)
case "$imguser" in
  ""|"root"|"0"|"0:0")
    fail "The image's USER is '${imguser:-<empty>}' — that's root. Add a dedicated user (addgroup -S chai && adduser -S -G chai chai) and a USER line, then rebuild."
    ;;
  *) pass "Image config sets USER '$imguser' (non-root)" ;;
esac

# --- container ---
if ! docker container inspect chai-30-api >/dev/null 2>&1; then
  fail "No container named 'chai-30-api'. Run it: docker run -d --name chai-30-api -p 8030:3000 chai-30-api:v1"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-30-api)
if [ "$state" != "running" ]; then
  fail "chai-30-api is '$state', not running. Check docker logs chai-30-api — an EACCES crash means the app files aren't owned by your USER (use COPY --chown)."
fi
pass "Container 'chai-30-api' is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-30-api)
case "$img" in
  chai-30-api:v1) pass "It was created from 'chai-30-api:v1'" ;;
  *) fail "chai-30-api runs image '$img' — expected 'chai-30-api:v1'. Remove it and re-run from your image." ;;
esac

# --- the actual uid inside ---
uid=$(docker exec chai-30-api id -u 2>/dev/null)
if [ -z "$uid" ]; then
  fail "Couldn't exec into chai-30-api to check the uid — is it healthy? See docker logs chai-30-api."
fi
if [ "$uid" = "0" ]; then
  fail "The process inside runs as uid 0 (root). Add USER <youruser> after the COPY in your Dockerfile, rebuild, and re-run the container."
fi
pass "Process inside runs as uid $uid — not root"

# --- port + behavior (also proves ownership: the app writes at startup) ---
port=$(docker container inspect -f '{{(index (index .NetworkSettings.Ports "3000/tcp") 0).HostPort}}' chai-30-api 2>/dev/null)
if [ "$port" != "8030" ]; then
  fail "Container port 3000 isn't published on host port 8030 (found: '${port:-none}'). Re-run with -p 8030:3000."
fi
pass "Port 8030 → 3000 is published"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8030/ 2>/dev/null)
if [ -z "$body" ]; then
  fail "No HTTP answer on http://127.0.0.1:8030 — check docker logs chai-30-api."
fi
if echo "$body" | grep -q '"uid":0[,}]'; then
  fail "The API reports it runs as uid 0. The USER line must come after root-only steps but before CMD — rebuild and re-run."
fi
if ! echo "$body" | grep -q '"uid":'; then
  fail "Unexpected response on 8030: '$body'. Make sure the container runs the chapter scaffold (workspace/ch30/app/server.js)."
fi
pass "API answers on 8030 and reports a non-zero uid (file ownership is right, or it couldn't have booted)"

celebrate "Exercise 30.1 complete. The API no longer runs as god."
