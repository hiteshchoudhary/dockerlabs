#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

for c in chai-37-qdrant chai-37-api; do
  if ! docker container inspect "$c" >/dev/null 2>&1; then
    fail "Container '$c' doesn't exist. From workspace/ch37: docker compose up -d --build (compose.yaml must set container_name: $c)."
  fi
  state=$(docker container inspect -f '{{.State.Status}}' "$c")
  if [ "$state" != "running" ]; then
    fail "'$c' is '$state', not running. Check: docker compose -p chai-37 logs"
  fi
  proj=$(docker container inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$c")
  if [ "$proj" != "chai-37" ]; then
    fail "'$c' isn't part of Compose project 'chai-37' (found: '${proj:-none}'). Set top-level 'name: chai-37' in compose.yaml and re-up."
  fi
done
pass "Both services are running under Compose project 'chai-37'"

qports=$(docker container inspect -f '{{range $p, $b := .NetworkSettings.Ports}}{{if $b}}{{$p}} {{end}}{{end}}' chai-37-qdrant)
if [ -z "$qports" ]; then
  pass "qdrant has no published ports — the database stays private"
else
  fail "chai-37-qdrant publishes '$qports' to the host — remove its ports: section entirely; the api reaches it over the project network."
fi

aport=$(docker container inspect -f '{{(index (index .NetworkSettings.Ports "8000/tcp") 0).HostPort}}' chai-37-api 2>/dev/null)
if [ "$aport" = "8037" ]; then
  pass "api port 8000 published on host port 8037"
else
  fail "The api isn't published on host port 8037 (found: '${aport:-none}'). Use ports: [\"8037:8000\"] on the api service."
fi

body=""
for i in $(seq 1 15); do
  body=$(curl -fsS 'http://127.0.0.1:8037/ask?q=what+is+docker' 2>/dev/null) && break
  sleep 2
done
if [ -z "$body" ]; then
  fail "GET http://127.0.0.1:8037/ask isn't answering (waited 30s). Check: docker compose -p chai-37 logs api"
fi

check=$(node -e '
const j = JSON.parse(process.argv[1]);
if (j.source !== "qdrant") { console.log("NOSOURCE"); process.exit(0); }
const h = j.hits;
if (!Array.isArray(h) || h.length < 1 || !h[0].text) { console.log("NOHITS"); process.exit(0); }
console.log("OK");
' "$body" 2>/dev/null)

case "$check" in
  OK) pass "/ask returns qdrant-backed hits with real text" ;;
  NOSOURCE) fail "/ask answered, but without \"source\":\"qdrant\" — are you running the scaffolded server.js from workspace/ch37/api unmodified?" ;;
  NOHITS) fail "/ask answered with no hits — qdrant may still be seeding, or the api can't reach it. Check QDRANT_URL=http://qdrant:6333 and docker compose -p chai-37 logs api." ;;
  *) fail "/ask didn't return valid JSON. Check: curl -s 'http://127.0.0.1:8037/ask?q=test' and the api logs." ;;
esac

celebrate "Exercise 37.1 complete. A GenAI stack, one command, database invisible to the world."
