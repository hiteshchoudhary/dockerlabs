#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

WS="${LAB_WORKSPACE:?}/ch21"
CF="$WS/compose.yaml"

[ -f "$CF" ] || fail "No compose.yaml at workspace/ch21/. Create it there."
[ -f "$WS/.env" ] || fail "No .env at workspace/ch21/. It must sit next to compose.yaml to be picked up."
[ -f "$WS/web.env" ] || fail "No web.env at workspace/ch21/. That's the env_file for the web service."
pass "compose.yaml, .env and web.env all exist"

grep -Eq '^[[:space:]]*CHAI_MODE=dev[[:space:]]*$' "$WS/.env" \
  || fail ".env doesn't set CHAI_MODE=dev. One line: CHAI_MODE=dev"
grep -Eq '^[[:space:]]*CHAI_MESSAGE=chai is ready[[:space:]]*$' "$WS/web.env" \
  || fail "web.env doesn't set CHAI_MESSAGE=chai is ready (exact text, no quotes)."
pass ".env sets CHAI_MODE=dev; web.env sets CHAI_MESSAGE=chai is ready"

cfg=$(docker compose -p chai-21 -f "$CF" config --format json 2>&1)
if [ $? -ne 0 ]; then
  fail "Your compose file doesn't parse: $(echo "$cfg" | head -n2). Run 'docker compose config' in workspace/ch21/ for the full error."
fi

vals=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const env = c.services?.web?.environment || {};
  console.log(env.CHAI_MODE || "MISSING");
  console.log(env.CHAI_MESSAGE || "MISSING");
  console.log(c.services?.debug ? "yes" : "no");' 2>/dev/null)
mode=$(sed -n 1p <<<"$vals")
msg=$(sed -n 2p <<<"$vals")
has_debug=$(sed -n 3p <<<"$vals")

if [ "$mode" = "dev" ]; then
  pass "Resolved config: web gets CHAI_MODE=dev (substituted from .env)"
else
  fail "Resolved config shows CHAI_MODE='$mode' for web — expected dev via \${CHAI_MODE:-prod} in environment: plus CHAI_MODE=dev in .env."
fi

if [ "$msg" = "chai is ready" ]; then
  pass "Resolved config: web gets CHAI_MESSAGE from web.env"
else
  fail "Resolved config shows CHAI_MESSAGE='$msg' for web — list web.env under the service's env_file:."
fi

if [ "$has_debug" = "no" ]; then
  pass "debug service is absent from the default config (profile gating works)"
else
  fail "The debug service appears in the DEFAULT config — it isn't behind a profile. Add profiles: [\"debug\"] to it."
fi

dbg_profiles=$(docker compose -p chai-21 -f "$CF" --profile debug config --format json 2>/dev/null | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  console.log(JSON.stringify(c.services?.debug?.profiles || []));' 2>/dev/null)
if echo "$dbg_profiles" | grep -q '"debug"'; then
  pass "…and appears (profiles: [\"debug\"]) once the profile is activated"
else
  fail "No debug service found even with --profile debug. Declare it: image alpine, command sleep infinity, profiles: [\"debug\"]."
fi

web_id=$(docker ps -q \
  --filter "label=com.docker.compose.project=chai-21" \
  --filter "label=com.docker.compose.service=web" | head -n1)
if [ -z "$web_id" ]; then
  fail "No running 'web' container in project chai-21. From workspace/ch21/: docker compose up -d --build"
fi
pass "web is running under project chai-21"

body=$(curl -fsS --max-time 5 http://localhost:8021/ 2>/dev/null)
if echo "$body" | grep -q '"message":"chai is ready"' && echo "$body" | grep -q '"mode":"dev"'; then
  pass "http://localhost:8021 answers with the message and mode from your env files"
else
  fail "Port 8021 answered '${body:-nothing}' — expected \"message\":\"chai is ready\" and \"mode\":\"dev\". Env changes need a recreate: docker compose up -d (check ports: \"8021:3000\" too)."
fi

celebrate "Exercise 21.1 complete. Same image, any environment — config now lives outside."
