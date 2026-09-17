#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-21" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

dbg_id=$(find_svc debug)
if [ -z "$dbg_id" ]; then
  fail "No running 'debug' container in project chai-21. Activate the profile: docker compose --profile debug up -d (from workspace/ch21/)."
fi
state=$(docker inspect -f '{{.State.Status}}' "$dbg_id")
if [ "$state" = "running" ]; then
  pass "debug service is up under project chai-21"
else
  fail "debug container exists but is '$state' — give it a long-lived command: sleep infinity."
fi

if [ -z "$(find_svc web)" ]; then
  fail "web is no longer running — the profile adds tooling, it shouldn't replace the stack. Re-run: docker compose --profile debug up -d"
fi
if curl -fsS --max-time 5 http://localhost:8021/ 2>/dev/null | grep -q '"message":"chai is ready"'; then
  pass "web still answers on 8021 alongside the tooling"
else
  fail "web stopped answering on 8021. Bring the whole stack back: docker compose --profile debug up -d"
fi

celebrate "Challenge complete. Tooling on demand — one flag in, one flag out."
