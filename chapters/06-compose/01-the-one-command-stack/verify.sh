#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if [ ! -f "${LAB_WORKSPACE:?}/ch19/compose.yaml" ]; then
  fail "No compose.yaml at workspace/ch19/. Create it there — that's where the stack is declared."
fi
pass "workspace/ch19/compose.yaml exists"

# Find containers by compose labels — project + service.
find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-19" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

web_id=$(find_svc web)
if [ -z "$web_id" ]; then
  fail "No running container for service 'web' in project chai-19. Bring the stack up: cd ch19 && docker compose up -d (and make sure the file has name: chai-19)."
fi
pass "Service 'web' is running under project chai-19"

web_img=$(docker inspect -f '{{.Config.Image}}' "$web_id")
case "$web_img" in
  nginx:alpine*|nginx:*alpine*) pass "web uses the nginx:alpine image" ;;
  *) fail "web runs image '$web_img' — expected nginx:alpine. Fix the image: line and run docker compose up -d again." ;;
esac

redis_id=$(find_svc redis)
if [ -z "$redis_id" ]; then
  fail "No running container for service 'redis' in project chai-19. Add a redis service (image: redis:alpine) and re-run docker compose up -d."
fi
pass "Service 'redis' is running under project chai-19"

redis_img=$(docker inspect -f '{{.Config.Image}}' "$redis_id")
case "$redis_img" in
  redis:alpine*|redis:*alpine*) pass "redis uses the redis:alpine image" ;;
  *) fail "redis runs image '$redis_img' — expected redis:alpine." ;;
esac

body=$(curl -fsS --max-time 5 http://localhost:8019/ 2>/dev/null)
if echo "$body" | grep -qi "ChaiCode status board"; then
  pass "http://localhost:8019 serves the status board"
else
  fail "Port 8019 doesn't serve the scaffolded page. Check ports: (\"8019:80\") and the ./site volume mount, then docker compose up -d."
fi

celebrate "Exercise 19.1 complete. Your stack is now a file, not a shell history."
