#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# --- the network ---
if ! docker network inspect chai-17-net >/dev/null 2>&1; then
  fail "No network named 'chai-17-net' found. Create it: docker network create chai-17-net"
fi
driver=$(docker network inspect -f '{{.Driver}}' chai-17-net)
if [ "$driver" = "bridge" ]; then
  pass "Network 'chai-17-net' exists (driver: bridge)"
else
  fail "chai-17-net exists but its driver is '$driver' — expected 'bridge'. Remove it (docker network rm chai-17-net) and recreate with plain: docker network create chai-17-net"
fi

# --- the two containers ---
check_member() {  # $1 = container name
  local name="$1"
  if ! docker container inspect "$name" >/dev/null 2>&1; then
    fail "No container named '$name' found. Run one: docker run -d --name $name --network chai-17-net alpine sleep 3600"
  fi
  pass "Container '$name' exists"

  local img
  img=$(docker container inspect -f '{{.Config.Image}}' "$name")
  case "$img" in
    alpine|alpine:*) pass "'$name' was created from alpine" ;;
    *) fail "'$name' uses image '$img' — expected 'alpine'. Remove it (docker rm -f $name) and re-run from alpine." ;;
  esac

  local state
  state=$(docker container inspect -f '{{.State.Status}}' "$name")
  if [ "$state" = "running" ]; then
    pass "'$name' is running"
  else
    fail "'$name' is '$state', not running. Alpine exits instantly without work — re-run it with a long command: docker rm -f $name && docker run -d --name $name --network chai-17-net alpine sleep 3600"
  fi

  if docker inspect -f '{{json .NetworkSettings.Networks}}' "$name" | grep -q '"chai-17-net"'; then
    pass "'$name' is attached to chai-17-net"
  else
    fail "'$name' is not on chai-17-net. Plug it in: docker network connect chai-17-net $name"
  fi
}

check_member chai-17-a
check_member chai-17-b

# --- DNS by name, both directions ---
if docker exec chai-17-a ping -c 1 -W 3 chai-17-b >/dev/null 2>&1; then
  pass "chai-17-a reaches chai-17-b by NAME (embedded DNS at work)"
else
  fail "From inside chai-17-a, 'ping chai-17-b' failed. Both containers must sit on chai-17-net — check docker network inspect chai-17-net, and connect any missing one: docker network connect chai-17-net <name>"
fi

if docker exec chai-17-b ping -c 1 -W 3 chai-17-a >/dev/null 2>&1; then
  pass "chai-17-b reaches chai-17-a by NAME too"
else
  fail "From inside chai-17-b, 'ping chai-17-a' failed. Check both containers are attached to chai-17-net: docker network inspect chai-17-net"
fi

celebrate "Exercise 17.1 complete. Your containers are on a first-name basis — no IPs memorized."
