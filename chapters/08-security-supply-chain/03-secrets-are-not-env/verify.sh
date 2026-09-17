#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

tokenfile="${LAB_WORKSPACE:?}/ch32/token.txt"
[ -f "$tokenfile" ] || fail "Scaffold file workspace/ch32/token.txt is missing — restore it (it's part of the chapter scaffold)."
token=$(head -n1 "$tokenfile" | tr -d '[:space:]')

host_sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else sha256sum "$1" | cut -d' ' -f1; fi
}

if ! docker image inspect chai-32-api:v1 >/dev/null 2>&1; then
  fail "No image 'chai-32-api:v1'. Build it from workspace/ch32: docker build --secret id=apitoken,src=token.txt -t chai-32-api:v1 ."
fi
pass "Image 'chai-32-api:v1' exists"

# --- the attacker's audit: history ---
if docker history --no-trunc chai-32-api:v1 2>/dev/null | grep -qF "$token"; then
  fail "The token VALUE is visible in 'docker history chai-32-api:v1' — it got baked in (ENV, ARG, or an echo). Use RUN --mount=type=secret instead, and rebuild without cache."
fi
pass "docker history contains no trace of the token value"

# --- image environment ---
imgenv=$(docker image inspect -f '{{range .Config.Env}}{{.}}
{{end}}' chai-32-api:v1)
if echo "$imgenv" | grep -qF "$token"; then
  fail "An image environment variable carries the token value. Remove the ENV/ARG and rebuild — secrets are not env."
fi
if echo "$imgenv" | grep -qiE '^[A-Z_]*TOKEN[A-Z_]*='; then
  fail "The image defines a TOKEN-named environment variable. Delete it from the Dockerfile — the build gets the token via --mount=type=secret only."
fi
pass "Image environment is clean — no token value, no TOKEN-named variable"

# --- the token file must not have been COPYed in ---
if docker run --rm --name chai-32-probe chai-32-api:v1 sh -c 'test -f /app/token.txt' >/dev/null 2>&1; then
  fail "/app/token.txt exists inside the image — you COPYed the secret into a layer (deleting it later wouldn't help; layers are additive). Remove the COPY and rebuild."
fi
pass "token.txt was never COPYed into the image"

# --- runtime probe: the secret mount left no trace ---
leftovers=$(docker run --rm --name chai-32-probe chai-32-api:v1 sh -c 'ls -A /run/secrets 2>/dev/null | wc -l' 2>/dev/null | tr -d '[:space:]')
if [ "${leftovers:-0}" != "0" ]; then
  fail "/run/secrets is not empty at runtime — the secret leaked past its RUN step. Use --mount=type=secret (not COPY into /run/secrets) and rebuild."
fi
runtimeenv=$(docker run --rm --name chai-32-probe chai-32-api:v1 env 2>/dev/null)
if echo "$runtimeenv" | grep -qiE '^[A-Z_]*(APITOKEN|API_TOKEN)[A-Z_]*='; then
  fail "A fresh container from the image carries an APITOKEN-style env variable. Remove it from the Dockerfile and rebuild."
fi
pass "Throwaway probe confirms: /run/secrets empty, no APITOKEN in the runtime environment"

# --- proof the secret WAS there during the build ---
expected=$(host_sha256 "$tokenfile")
actual=$(docker run --rm --name chai-32-probe chai-32-api:v1 cat /app/token.fingerprint 2>/dev/null | tr -d '[:space:]')
if [ -z "$actual" ]; then
  fail "No /app/token.fingerprint in the image — install-deps.sh never ran with the secret. Wire it up: RUN --mount=type=secret,id=apitoken sh ./install-deps.sh, built with --secret id=apitoken,src=token.txt."
fi
if [ "$actual" != "$expected" ]; then
  fail "The build-time fingerprint ($actual) doesn't match the sha256 of workspace/ch32/token.txt ($expected). Rebuild passing THIS token: docker build --secret id=apitoken,src=token.txt -t chai-32-api:v1 ."
fi
pass "Build fingerprint matches token.txt — the secret was present during the build, and only its hash remains"

celebrate "Exercise 32.1 complete. The token was used and never kept — cryptographically provable."
