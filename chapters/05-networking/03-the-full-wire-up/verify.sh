#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# --- the network ---
if ! docker network inspect chai-18-net >/dev/null 2>&1; then
  fail "No network named 'chai-18-net' found. Create it first: docker network create chai-18-net"
fi
driver=$(docker network inspect -f '{{.Driver}}' chai-18-net)
if [ "$driver" = "bridge" ]; then
  pass "Network 'chai-18-net' exists (driver: bridge)"
else
  fail "chai-18-net has driver '$driver' — expected 'bridge'. Recreate it: docker network rm chai-18-net && docker network create chai-18-net"
fi

check_service() {  # $1 name, $2 expected image prefix, $3 human image name, $4 run hint
  local name="$1" want="$2" human="$3" hint="$4"
  if ! docker container inspect "$name" >/dev/null 2>&1; then
    fail "No container named '$name' found. Run it: $hint"
  fi
  pass "Container '$name' exists"

  local img
  img=$(docker container inspect -f '{{.Config.Image}}' "$name")
  case "$img" in
    "$want"|"$want":*) pass "'$name' was created from $human" ;;
    *) fail "'$name' uses image '$img' — expected '$human'. Remove it (docker rm -f $name) and re-run: $hint" ;;
  esac

  local state
  state=$(docker container inspect -f '{{.State.Status}}' "$name")
  if [ "$state" = "running" ]; then
    pass "'$name' is running"
  else
    fail "'$name' is '$state', not running. Read its last words (docker logs $name) — postgres, for one, exits without POSTGRES_PASSWORD — then remove and re-run it."
  fi

  if docker inspect -f '{{json .NetworkSettings.Networks}}' "$name" | grep -q '"chai-18-net"'; then
    pass "'$name' is attached to chai-18-net"
  else
    fail "'$name' is not on chai-18-net. Plug it in: docker network connect chai-18-net $name"
  fi
}

check_service chai-18-db    postgres "postgres:16-alpine" "docker run -d --name chai-18-db --network chai-18-net -e POSTGRES_PASSWORD=chai postgres:16-alpine"
check_service chai-18-cache redis    "redis:alpine"       "docker run -d --name chai-18-cache --network chai-18-net redis:alpine"
check_service chai-18-api   nginx    "nginx:alpine"       "docker run -d --name chai-18-api --network chai-18-net -p 8018:80 nginx:alpine"

# --- isolation: db and cache must publish NOTHING ---
for svc in chai-18-db chai-18-cache; do
  bindings=$(docker inspect -f '{{len .HostConfig.PortBindings}}' "$svc")
  if [ "$bindings" = "0" ]; then
    pass "'$svc' publishes no host ports — invisible from outside the network"
  else
    fail "'$svc' has $bindings published port(s) — the back rooms must have NONE. Bindings can't be removed live: docker rm -f $svc and re-run it without any -p."
  fi
done

# --- the front door answers on 8018 ---
api_port=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostPort}}' chai-18-api 2>/dev/null)
if [ "$api_port" = "8018" ]; then
  pass "chai-18-api publishes container port 80 on host port 8018"
else
  fail "chai-18-api's 80/tcp is bound to host port '${api_port:-nothing}' — expected 8018. Recreate it with -p 8018:80."
fi
if curl -fsS --max-time 5 http://127.0.0.1:8018 >/dev/null 2>&1; then
  pass "Front door answers on http://127.0.0.1:8018"
else
  fail "Nothing answered on http://127.0.0.1:8018. Check docker logs chai-18-api, then recreate it with -p 8018:80."
fi

# --- inside wiring: api reaches db and cache BY NAME ---
# (postgres can take a few seconds to listen after starting — retry briefly)
db_ok=""
for i in 1 2 3 4 5 6; do
  if docker exec chai-18-api nc -z -w 2 chai-18-db 5432 >/dev/null 2>&1; then db_ok=yes; break; fi
  sleep 2
done
if [ "$db_ok" = "yes" ]; then
  pass "From inside chai-18-api: chai-18-db:5432 is reachable by name"
else
  fail "chai-18-api can't reach chai-18-db:5432. Is postgres actually up (docker logs chai-18-db — it needs POSTGRES_PASSWORD), and are both on chai-18-net?"
fi

if docker exec chai-18-api nc -z -w 2 chai-18-cache 6379 >/dev/null 2>&1; then
  pass "From inside chai-18-api: chai-18-cache:6379 is reachable by name"
else
  fail "chai-18-api can't reach chai-18-cache:6379. Check docker logs chai-18-cache and that both containers are attached to chai-18-net."
fi

celebrate "Exercise 18.1 complete. One door published, everything else dark — that's a production topology."
