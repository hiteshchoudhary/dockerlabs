#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-29-registry >/dev/null 2>&1; then
  fail "No container named 'chai-29-registry'. Start it: docker run -d --name chai-29-registry -p 8129:5000 registry:2"
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-29-registry)
if [ "$state" != "running" ]; then
  fail "chai-29-registry is '$state' — start it: docker start chai-29-registry"
fi

tags=$(curl -fsS --max-time 5 http://127.0.0.1:8129/v2/chai-29-app/tags/list 2>/dev/null)
if [ -z "$tags" ]; then
  fail "The registry on 8129 has no chai-29-app repository yet (or isn't published on 8129). Build and push both versions first — see steps 2 and 3."
fi
pass "Registry on 8129 knows chai-29-app"

if echo "$tags" | grep -q '"1.0"'; then
  pass "Registry holds tag 1.0"
else
  fail "Tags list says $tags — no '1.0'. Build and push v1: docker build --build-arg APP_VERSION=1.0 -t 127.0.0.1:8129/chai-29-app:1.0 ./ch29 && docker push 127.0.0.1:8129/chai-29-app:1.0"
fi

if echo "$tags" | grep -q '"2.0"'; then
  pass "Registry holds tag 2.0 — full version history in place"
else
  fail "Tags list says $tags — no '2.0'. Build and push v2: docker build --build-arg APP_VERSION=2.0 -t 127.0.0.1:8129/chai-29-app:2.0 ./ch29 && docker push 127.0.0.1:8129/chai-29-app:2.0"
fi

if ! docker container inspect chai-29-app >/dev/null 2>&1; then
  fail "No container named 'chai-29-app'. Deploy: docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0 — then upgrade it to :2.0 by the ritual."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-29-app)
if [ "$state" != "running" ]; then
  fail "chai-29-app is '$state' — the deploy isn't live. docker start chai-29-app (or re-run the ritual's final run step)."
fi
pass "chai-29-app is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-29-app)
body=$(curl -fsS --max-time 5 http://127.0.0.1:8029/ 2>/dev/null)
if [ -z "$body" ]; then
  fail "Nothing answers on http://127.0.0.1:8029/ — publish the app on 8029: the run step needs -p 8029:80."
fi

case "$img" in
  127.0.0.1:8129/chai-29-app:2.0)
    if echo "$body" | grep -q 'version 2.0'; then
      pass "Running :2.0 and serving 'version 2.0' — config and response agree"
    else
      fail "The container claims :2.0 but answers '$body' — a mutated snowflake. Replace it by the ritual: pull, stop, rm, run 127.0.0.1:8129/chai-29-app:2.0"
    fi
    ;;
  127.0.0.1:8129/chai-29-app:1.0)
    if [ ! -f "${LAB_WORKSPACE:?}/ch29/rollback.txt" ]; then
      fail "chai-29-app is running :1.0 — that's the starting point, not the deploy. Upgrade by the ritual: docker pull 127.0.0.1:8129/chai-29-app:2.0, stop, rm, run the :2.0 tag. (Rolled back on purpose? The challenge's morning note at workspace/ch29/rollback.txt is what tells me so.)"
    fi
    if echo "$body" | grep -q 'version 1.0'; then
      pass "Running :1.0 with the rollback note in place — challenge state, accepted"
    else
      fail "The container claims :1.0 but answers '$body' — config and response disagree. Re-run the rollback ritual cleanly: stop, rm, run 127.0.0.1:8129/chai-29-app:1.0"
    fi
    ;;
  *)
    fail "chai-29-app runs '$img' — deploys come from the registry: expected 127.0.0.1:8129/chai-29-app:2.0 (or :1.0 after the challenge's rollback). Replace it by the ritual."
    ;;
esac

celebrate "Exercise 29.1 complete. Upgrades are a ritual now, not an adventure."
