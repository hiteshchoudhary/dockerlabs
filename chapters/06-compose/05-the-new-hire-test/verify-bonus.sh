#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

CF="${LAB_WORKSPACE:?}/ch23/compose.yaml"
[ -f "$CF" ] || fail "No compose.yaml at workspace/ch23/ — finish the main exercise first."

profiles=$(docker compose -p chai-23 -f "$CF" --profile debug config --format json 2>/dev/null | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  console.log(JSON.stringify(c.services?.adminer?.profiles || []));' 2>/dev/null)
if echo "$profiles" | grep -q '"debug"'; then
  pass "adminer is declared behind the debug profile"
else
  fail "No adminer service behind profiles: [\"debug\"] in the config. Add it: image adminer, profiles: [\"debug\"]."
fi

find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-23" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

adm=$(find_svc adminer)
if [ -z "$adm" ]; then
  fail "adminer isn't running. Activate the profile: docker compose --profile debug up -d (from workspace/ch23/)."
fi
state=$(docker inspect -f '{{.State.Status}}' "$adm")
[ "$state" = "running" ] || fail "adminer's container is '$state' — check docker compose logs adminer."
pass "adminer is up and running under project chai-23"

for svc in db cache api web; do
  id=$(find_svc "$svc")
  [ -n "$id" ] || fail "Core service '$svc' is no longer running — the profile adds tooling, never replaces the stack. Re-run: docker compose --profile debug up -d"
  h=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$id")
  [ "$h" = "healthy" ] || fail "Core service '$svc' is not healthy anymore ('${h:-none}') — docker compose ps and logs will say why."
done
pass "The core four are still running and healthy around it"

celebrate "Challenge complete. Tooling on a flag, platform untouched — Part 6, done."
