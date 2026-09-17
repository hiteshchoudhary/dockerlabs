#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-08-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-08-api:v1' — finish the main exercise first."
fi

secret="${LAB_WORKSPACE:?}/ch08/app/secret.env"
if [ ! -f "$secret" ]; then
  fail "No file at workspace/ch08/app/secret.env. Create the fake credentials file first: echo \"API_KEY=super-secret-chai\" > secret.env"
fi
pass "secret.env exists on the host"

di="${LAB_WORKSPACE}/ch08/app/.dockerignore"
if [ -f "$di" ] && grep -Eq '^[[:space:]]*((\*\*/)?secret\.env|\*\.env)[[:space:]]*$' "$di"; then
  pass ".dockerignore covers it (secret.env or *.env)"
else
  fail ".dockerignore doesn't cover secret.env. Add a line with 'secret.env' (or '*.env') and rebuild."
fi

# Probe the image: where did WORKDIR put the app?
wd=$(docker image inspect -f '{{.Config.WorkingDir}}' chai-08-api:v1)
wd=${wd:-/app}

if docker run --rm --name chai-08-probe chai-08-api:v1 sh -c "test -f '$wd/server.js'"; then
  pass "server.js made it into the image ($wd/server.js)"
else
  fail "server.js is missing inside the image at $wd — did COPY . . disappear from the Dockerfile? Rebuild."
fi

if docker run --rm --name chai-08-probe chai-08-api:v1 sh -c "test -f '$wd/secret.env'"; then
  fail "secret.env IS inside the image ($wd/secret.env) — the ignore rule wasn't active when you built. Fix .dockerignore, rebuild chai-08-api:v1, and verify again."
else
  pass "secret.env is NOT in the image — the context never contained it"
fi

celebrate "Challenge complete. What never enters the context can never leak from a layer."
