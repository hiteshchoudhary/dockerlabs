#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

tokenfile="${LAB_WORKSPACE:?}/ch32/token.txt"
[ -f "$tokenfile" ] || fail "Scaffold file workspace/ch32/token.txt is missing — restore it."
token=$(head -n1 "$tokenfile" | tr -d '[:space:]')

host_sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else sha256sum "$1" | cut -d' ' -f1; fi
}

if ! docker container inspect chai-32-app >/dev/null 2>&1; then
  fail "No container named 'chai-32-app'. Run your image with the token bind-mounted read-only at /run/secrets/apitoken, published on 8032."
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-32-app)
[ "$state" = "running" ] || fail "chai-32-app is '$state', not running. Check docker logs chai-32-app."
pass "Container 'chai-32-app' is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-32-app)
[ "$img" = "chai-32-api:v1" ] || fail "chai-32-app runs image '$img' — expected 'chai-32-api:v1'."
pass "Created from 'chai-32-api:v1'"

# --- the mount: file secret, read-only, conventional path ---
mounts=$(docker container inspect -f '{{range .Mounts}}{{.Destination}}|rw={{.RW}} {{end}}' chai-32-app)
mountinfo=""
for m in $mounts; do
  case "$m" in /run/secrets*) mountinfo="$m" ;; esac
done
if [ -z "$mountinfo" ]; then
  fail "No mount under /run/secrets found (mounts: '${mounts:-none}'). Bind-mount the token: -v \"\$PWD/ch32/token.txt:/run/secrets/apitoken:ro\""
fi
case "$mountinfo" in
  *"rw=false"*) pass "Secret mounted at ${mountinfo%%|*} — read-only" ;;
  *) fail "The secret mount (${mountinfo%%|*}) is WRITABLE. Add :ro to the -v flag and re-run the container." ;;
esac

# --- the app actually loaded it ---
body=$(curl -fsS --max-time 5 http://127.0.0.1:8032/ 2>/dev/null)
[ -n "$body" ] || fail "No HTTP answer on http://127.0.0.1:8032 — publish with -p 8032:3000 and check docker logs chai-32-app."
echo "$body" | grep -q '"secretLoaded":true' \
  || fail "The API reports secretLoaded:false — the file isn't at /run/secrets/apitoken inside the container. Check the -v target path."
expected=$(host_sha256 "$tokenfile")
echo "$body" | grep -qF "\"fingerprint\":\"$expected\"" \
  || fail "The runtime fingerprint doesn't match workspace/ch32/token.txt — a different file is mounted at /run/secrets/apitoken."
pass "API on 8032 loaded the runtime secret — fingerprint matches token.txt"

# --- and env stayed clean ---
cenv=$(docker container inspect -f '{{range .Config.Env}}{{.}}
{{end}}' chai-32-app)
if echo "$cenv" | grep -qF "$token"; then
  fail "An environment variable in chai-32-app carries the token VALUE — that's the leak this chapter kills. Re-run without the -e; the file mount alone is enough."
fi
badenv=$(echo "$cenv" | grep -iE '^[A-Z_]*TOKEN[A-Z_]*=' | grep -viE '^[A-Z_]*_FILE=' || true)
if [ -n "$badenv" ]; then
  fail "chai-32-app has a TOKEN-named env variable ($badenv). Only _FILE-style pointers are acceptable in env — re-run without it."
fi
pass "Container environment is clean — the secret travels as a file, not as env"

celebrate "Challenge complete. Same secret, delivered at build and at run — and never stored either time."
