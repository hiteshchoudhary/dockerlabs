#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

CF="${LAB_WORKSPACE:?}/ch20/compose.yaml"
if [ ! -f "$CF" ]; then
  fail "No compose.yaml at workspace/ch20/. Create the stack file there first."
fi
pass "workspace/ch20/compose.yaml exists"

cfg=$(docker compose -p chai-20 -f "$CF" config --format json 2>&1)
if [ $? -ne 0 ]; then
  fail "Your compose file doesn't parse: $(echo "$cfg" | head -n2). Run 'docker compose config' in workspace/ch20/ to see the full error."
fi

# --- declared config: healthcheck on db, service_healthy on web ---
hc=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const t = c.services?.db?.healthcheck?.test;
  console.log(t ? JSON.stringify(t) : "");' 2>/dev/null)
if [ -z "$hc" ]; then
  fail "Service 'db' has no healthcheck in the compose config. Add a healthcheck: block with a pg_isready test."
fi
if echo "$hc" | grep -q "pg_isready"; then
  pass "db has a pg_isready healthcheck"
else
  fail "db's healthcheck test is $hc — it should probe readiness with pg_isready."
fi

cond=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  console.log(c.services?.web?.depends_on?.db?.condition || "");' 2>/dev/null)
if [ "$cond" = "service_healthy" ]; then
  pass "web depends_on db with condition: service_healthy"
else
  fail "web's depends_on condition on db is '${cond:-missing}' — use the long form: depends_on: db: condition: service_healthy. (The short list form only orders starts.)"
fi

# --- live state ---
find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-20" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

db_id=$(find_svc db)
if [ -z "$db_id" ]; then
  fail "No running 'db' container in project chai-20. Bring the stack up: docker compose up -d (in workspace/ch20/)."
fi

health=""
for _ in $(seq 1 15); do
  health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$db_id" 2>/dev/null)
  [ "$health" = "healthy" ] && break
  sleep 2
done
case "$health" in
  healthy) pass "db is running and healthy" ;;
  "")      fail "db is running but reports no health status — the healthcheck isn't attached. Fix the healthcheck block and recreate: docker compose up -d --force-recreate db." ;;
  *)       fail "db's health is '$health', not healthy. Read the probe log: docker inspect -f '{{json .State.Health.Log}}' chai-20-db-1 — is POSTGRES_PASSWORD set?" ;;
esac

if [ -z "$(find_svc web)" ]; then
  fail "No running 'web' container in project chai-20. If up is stuck 'Waiting', your db never became healthy; otherwise run docker compose up -d again."
fi
pass "web is running"

if curl -fsS --max-time 5 http://localhost:8020/ 2>/dev/null | grep -qi "Orders dashboard"; then
  pass "http://localhost:8020 serves the orders dashboard"
else
  fail "Port 8020 doesn't serve the scaffolded page. Check ports: (\"8020:80\") and the ./site mount, then docker compose up -d."
fi

celebrate "Exercise 20.1 complete. Your startup order is now deterministic, not lucky."
