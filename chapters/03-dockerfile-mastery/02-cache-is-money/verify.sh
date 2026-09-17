#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# Image exists
if ! docker image inspect chai-08-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-08-api:v1' found. Build it from workspace/ch08/app: docker build -t chai-08-api:v1 ."
fi
pass "Image 'chai-08-api:v1' exists"

# Layer history must show deps-first ordering:
#   COPY (package files) ... RUN npm ... COPY (rest of app)
# docker history lists newest-first, so reverse to oldest-first and scan.
order=$(docker history --no-trunc --format '{{.CreatedBy}}' chai-08-api:v1 \
  | tail -r 2>/dev/null || docker history --no-trunc --format '{{.CreatedBy}}' chai-08-api:v1 | sed '1!G;h;$!d')

stage=0
while IFS= read -r line; do
  case "$stage" in
    0) echo "$line" | grep -qi '^COPY .*package' && stage=1 ;;
    1) echo "$line" | grep -Eqi '^RUN .*(npm (ci|install|i)\b)' && stage=2 ;;
    2) echo "$line" | grep -qi '^COPY ' && stage=3 ;;
  esac
done <<EOF
$order
EOF

case "$stage" in
  0) fail "The image's history has no early 'COPY package*.json' layer. Copy the package files by themselves BEFORE npm install, then rebuild." ;;
  1) fail "Found the package-files COPY, but no 'RUN npm ci' (or npm install) layer after it. Add the install step below that COPY and rebuild." ;;
  2) fail "Deps install found, but no 'COPY . .' after it — the app code never gets copied in. Add the full COPY as the later step and rebuild." ;;
  3) pass "Layer history shows the deps-first order: COPY package files → npm install → COPY the app" ;;
esac

# .dockerignore exists and excludes node_modules
di="${LAB_WORKSPACE:?}/ch08/app/.dockerignore"
if [ ! -f "$di" ]; then
  fail "No .dockerignore in workspace/ch08/app. Create it with at least a 'node_modules' line."
fi
if grep -Eq '^[[:space:]]*(\*\*/)?node_modules/?[[:space:]]*$' "$di"; then
  pass ".dockerignore exists and excludes node_modules"
else
  fail ".dockerignore exists but has no line excluding node_modules. Add a line containing exactly: node_modules"
fi

# Container running and answering with the dependency-powered field
if ! docker container inspect chai-08-api >/dev/null 2>&1; then
  fail "No container named 'chai-08-api'. Run one: docker run -d --name chai-08-api -p 8008:3000 chai-08-api:v1"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-08-api)
if [ "$state" != "running" ]; then
  fail "Container 'chai-08-api' is '$state', not running. If it crashed with 'Cannot find module', the npm install layer is missing — check docker logs chai-08-api."
fi
img=$(docker container inspect -f '{{.Config.Image}}' chai-08-api)
if [ "$img" != "chai-08-api:v1" ]; then
  fail "Container 'chai-08-api' runs image '$img' — expected chai-08-api:v1. Remove it and rerun from your image."
fi
pass "Container 'chai-08-api' is running from chai-08-api:v1"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8008/ 2>/dev/null)
if echo "$body" | grep -q '"uptime"'; then
  pass "http://localhost:8008 answers with an uptime — the dependency installed and works"
else
  fail "http://localhost:8008 didn't return JSON with an 'uptime' field (got: '${body:-no response}'). Publish with -p 8008:3000 and check docker logs chai-08-api."
fi

celebrate "Exercise 8.1 complete. Your rebuilds are now measured in milliseconds, not minutes."
