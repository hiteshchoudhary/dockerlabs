#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-18-lonely >/dev/null 2>&1; then
  fail "No container named 'chai-18-lonely' found. Run one: docker run -d --name chai-18-lonely --network none alpine sleep 3600"
fi
pass "Container 'chai-18-lonely' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-18-lonely)
case "$img" in
  alpine|alpine:*) pass "Created from alpine" ;;
  *) fail "chai-18-lonely uses image '$img' — expected 'alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-18-lonely)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-18-lonely is '$state', not running. Give it a long command: docker rm -f chai-18-lonely && docker run -d --name chai-18-lonely --network none alpine sleep 3600"
fi

mode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' chai-18-lonely)
if [ "$mode" = "none" ]; then
  pass "Network mode is 'none'"
else
  fail "Network mode is '$mode' — expected 'none'. The mode is fixed at creation: docker rm -f chai-18-lonely && docker run -d --name chai-18-lonely --network none alpine sleep 3600"
fi

ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' chai-18-lonely)
if [ -z "$ip" ]; then
  pass "No IP address on any network — no cable was ever crimped"
else
  fail "chai-18-lonely somehow has IP '$ip' — it must have none. Recreate it with --network none."
fi

if docker exec chai-18-lonely ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
  fail "chai-18-lonely reached the internet — that's exactly what 'none' must prevent. Recreate it with --network none."
else
  pass "Ping to 8.8.8.8 from inside failed — total isolation confirmed"
fi

celebrate "Challenge complete. You now know every way a container can be wired — including not at all."
