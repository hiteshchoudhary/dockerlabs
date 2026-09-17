#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-16-hidden >/dev/null 2>&1; then
  fail "No container named 'chai-16-hidden' found. Run one with no ports published: docker run -d --name chai-16-hidden nginx:alpine"
fi
pass "Container 'chai-16-hidden' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-16-hidden)
case "$img" in
  nginx:alpine*|nginx) pass "Created from nginx:alpine" ;;
  *) fail "chai-16-hidden uses image '$img' — expected 'nginx:alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-16-hidden)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-16-hidden is '$state', not running. Check docker logs chai-16-hidden, then remove and re-run it."
fi

exposed=$(docker inspect -f '{{json .Config.ExposedPorts}}' chai-16-hidden)
if echo "$exposed" | grep -q '80/tcp'; then
  pass "Image metadata still documents EXPOSE 80 (ExposedPorts: 80/tcp)"
else
  fail "The image metadata shows no exposed 80/tcp — did you run nginx:alpine?"
fi

bindings=$(docker inspect -f '{{len .HostConfig.PortBindings}}' chai-16-hidden)
if [ "$bindings" = "0" ]; then
  pass "PortBindings is empty — nothing published, exactly as intended"
else
  fail "chai-16-hidden has $bindings published port(s) — this one must have NONE. Recreate it without any -p or -P: docker rm -f chai-16-hidden && docker run -d --name chai-16-hidden nginx:alpine"
fi

# Join the container's own network namespace and prove nginx is serving in there.
if docker run --rm --name chai-16-probe --network container:chai-16-hidden alpine \
     wget -qO- -T 5 http://127.0.0.1 2>/dev/null | grep -qi nginx; then
  pass "Probe from inside its network namespace: nginx IS serving on port 80 in there"
else
  fail "A probe inside chai-16-hidden's network namespace couldn't fetch the nginx page. Is the container healthy? Check docker logs chai-16-hidden."
fi

celebrate "Challenge complete. EXPOSE documents; only -p opens."
