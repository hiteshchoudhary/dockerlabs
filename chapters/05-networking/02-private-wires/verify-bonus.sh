#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-17-c >/dev/null 2>&1; then
  fail "No container named 'chai-17-c' found. Run one on the default bridge: docker run -d --name chai-17-c alpine sleep 3600"
fi
pass "Container 'chai-17-c' exists"

state=$(docker container inspect -f '{{.State.Status}}' chai-17-c)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-17-c is '$state', not running. Re-run it with a long command: docker rm -f chai-17-c && docker run -d --name chai-17-c alpine sleep 3600"
fi

nets=$(docker inspect -f '{{json .NetworkSettings.Networks}}' chai-17-c)
if echo "$nets" | grep -q '"bridge"'; then
  pass "Still attached to the default 'bridge' network"
else
  fail "chai-17-c is not on the default bridge. Run it WITHOUT --network (docker run -d --name chai-17-c alpine sleep 3600), then patch it into chai-17-net live."
fi

if echo "$nets" | grep -q '"chai-17-net"'; then
  pass "ALSO attached to chai-17-net — dual-homed, so the cable was patched in live"
else
  fail "chai-17-c is not on chai-17-net. Connect it without stopping it: docker network connect chai-17-net chai-17-c"
fi

if docker exec chai-17-c ping -c 1 -W 3 chai-17-a >/dev/null 2>&1; then
  pass "chai-17-c reaches chai-17-a by name across the private wire"
else
  fail "From inside chai-17-c, 'ping chai-17-a' failed. Is chai-17-a still running on chai-17-net? Reconnect if you left it unplugged: docker network connect chai-17-net chai-17-c"
fi

celebrate "Challenge complete. You can rewire a running container without dropping it."
