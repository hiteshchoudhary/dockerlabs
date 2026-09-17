#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-02-web >/dev/null 2>&1; then
  fail "No container named 'chai-02-web' found. Run nginx detached with --name chai-02-web."
fi
pass "Container 'chai-02-web' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-02-web)
case "$img" in
  nginx|nginx:*) pass "Created from an 'nginx' image" ;;
  *) fail "Container uses image '$img' — expected nginx." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-02-web)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-02-web is '$state' — it must be running when you verify. docker start chai-02-web"
fi

created=$(docker container inspect -f '{{.Created}}' chai-02-web)
started=$(docker container inspect -f '{{.State.StartedAt}}' chai-02-web)
gap=$(node -e "const a=new Date(process.argv[1]),b=new Date(process.argv[2]);console.log(Math.round((b-a)/1000))" "$created" "$started" 2>/dev/null || echo 0)
if [ "${gap:-0}" -ge 3 ]; then
  pass "StartedAt is ${gap}s after Created — a real stop/start cycle happened"
else
  fail "This container has never been restarted (StartedAt ≈ Created). Let it run a few seconds, then: docker restart chai-02-web"
fi

if docker container inspect chai-02-junk >/dev/null 2>&1; then
  fail "The graveyard isn't clean: 'chai-02-junk' still exists. Remove it: docker rm chai-02-junk"
fi
pass "No 'chai-02-junk' left behind — graveyard clean"

celebrate "Exercise 2.1 complete. You own the container lifecycle."
