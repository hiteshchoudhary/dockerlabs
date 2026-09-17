#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

CF="${LAB_WORKSPACE:?}/ch23/compose.yaml"
[ -f "$CF" ] || fail "No compose.yaml at workspace/ch23/. The whole platform is declared there — create it."
pass "workspace/ch23/compose.yaml exists"

cfg=$(docker compose -p chai-23 -f "$CF" config --format json 2>&1)
if [ $? -ne 0 ]; then
  fail "Your compose file doesn't parse: $(echo "$cfg" | head -n2). Run 'docker compose config' in workspace/ch23/ for the full error."
fi

decl=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const s = c.services || {};
  const missing = ["db", "cache", "api", "web"].filter((n) => !s[n]);
  if (missing.length) { console.log("missing:" + missing.join(",")); process.exit(0); }
  const nohc = ["db", "cache", "api", "web"].filter((n) => !s[n].healthcheck?.test);
  if (nohc.length) { console.log("nohc:" + nohc.join(",")); process.exit(0); }
  for (const dep of ["db", "cache"]) {
    if (s.api.depends_on?.[dep]?.condition !== "service_healthy") {
      console.log("dep:" + dep); process.exit(0);
    }
  }
  console.log("ok");' 2>/dev/null)

case "$decl" in
  ok)        pass "Config: all four services, healthchecks everywhere, api waits on healthy db AND cache" ;;
  missing:*) fail "Config is missing service(s): ${decl#missing:}. The stack needs exactly db, cache, api and web." ;;
  nohc:*)    fail "No healthcheck on: ${decl#nohc:}. Every service in this stack declares one — see the chapter." ;;
  dep:*)     fail "api's depends_on for '${decl#dep:}' isn't condition: service_healthy. It must wait for BOTH db and cache to be healthy." ;;
  *)         fail "Couldn't read the resolved config. Run 'docker compose config' in workspace/ch23/ to debug." ;;
esac

find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-23" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

for svc in db cache api web; do
  id=$(find_svc "$svc")
  if [ -z "$id" ]; then
    fail "No running '$svc' container in project chai-23. One command boots it all: docker compose up -d --build --wait (from workspace/ch23/)."
  fi
  health=""
  for _ in $(seq 1 15); do
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$id" 2>/dev/null)
    [ "$health" = "healthy" ] && break
    sleep 2
  done
  if [ "$health" = "healthy" ]; then
    pass "$svc is running and healthy"
  else
    fail "$svc is running but health is '${health:-none}'. Probe log: docker inspect -f '{{json .State.Health.Log}}' \$(docker compose -p chai-23 ps -q $svc)"
  fi
done

for svc in db cache; do
  id=$(find_svc "$svc")
  nports=$(docker inspect -f '{{len .HostConfig.PortBindings}}' "$id")
  if [ "$nports" = "0" ]; then
    pass "$svc publishes no host ports (network-only, as it should be)"
  else
    fail "$svc publishes host ports — remove its ports: section entirely. Services reach it by name over the project network."
  fi
done

if curl -fsS --max-time 5 http://localhost:8023/ 2>/dev/null | grep -qi "ChaiCode platform"; then
  pass "http://localhost:8023 serves the platform front"
else
  fail "Port 8023 doesn't serve the scaffolded site. web needs ports: \"8023:80\" and the ./site mount."
fi

api_body=$(curl -fsS --max-time 8 http://localhost:8123/ 2>/dev/null)
if echo "$api_body" | grep -q '"db":"up"' && echo "$api_body" | grep -q '"cache":"up"'; then
  pass "API reports db and cache reachable: $api_body"
else
  fail "http://localhost:8123/ answered '${api_body:-nothing}' — expected db and cache 'up'. Service names must be exactly db and cache, api port mapping 8123:3000."
fi

celebrate "Exercise 23.1 complete. Clone, one command, whole platform — the new hire test, passed."
