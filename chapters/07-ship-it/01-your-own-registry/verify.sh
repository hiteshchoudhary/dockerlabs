#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-24-registry >/dev/null 2>&1; then
  fail "No container named 'chai-24-registry' found. Start it: docker run -d --name chai-24-registry -p 8124:5000 registry:2"
fi

img=$(docker container inspect -f '{{.Config.Image}}' chai-24-registry)
case "$img" in
  registry:2|registry:2*) pass "chai-24-registry runs the 'registry:2' image" ;;
  *) fail "chai-24-registry uses image '$img' — expected 'registry:2'. Remove it (docker rm -f chai-24-registry) and start it again from registry:2." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-24-registry)
if [ "$state" = "running" ]; then
  pass "The registry is running"
else
  fail "chai-24-registry is '$state' — start it: docker start chai-24-registry"
fi

catalog=$(curl -fsS --max-time 5 http://127.0.0.1:8124/v2/_catalog 2>/dev/null)
if [ -z "$catalog" ]; then
  fail "Nothing answers on http://127.0.0.1:8124/v2/_catalog — is port 5000 published on 8124? Recreate: docker rm -f chai-24-registry && docker run -d --name chai-24-registry -p 8124:5000 registry:2"
fi
pass "The registry answers on host port 8124"

if echo "$catalog" | grep -q '"chai-24-api"'; then
  pass "Catalog lists chai-24-api"
else
  fail "The catalog says $catalog — no 'chai-24-api' in there yet. Tag your build as 127.0.0.1:8124/chai-24-api:1.0 and docker push it."
fi

tags=$(curl -fsS --max-time 5 http://127.0.0.1:8124/v2/chai-24-api/tags/list 2>/dev/null)
if echo "$tags" | grep -q '"1.0"'; then
  pass "Registry reports tag 1.0 for chai-24-api"
else
  fail "Tags list says ${tags:-nothing} — expected tag '1.0'. Push it: docker push 127.0.0.1:8124/chai-24-api:1.0"
fi

if docker image inspect 127.0.0.1:8124/chai-24-api:1.0 >/dev/null 2>&1; then
  pass "Local image 127.0.0.1:8124/chai-24-api:1.0 exists"
else
  fail "No local image named 127.0.0.1:8124/chai-24-api:1.0. Create the alias: docker tag chai-24-api:1.0 127.0.0.1:8124/chai-24-api:1.0"
fi

celebrate "Exercise 24.1 complete. You own the whole shipping pipeline now."
