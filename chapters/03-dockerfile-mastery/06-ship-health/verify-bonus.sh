#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-12-sick >/dev/null 2>&1; then
  fail "No container named 'chai-12-sick'. Run the saboteur: docker run -d --name chai-12-sick -e FAIL_HEALTH=1 chai-12-api:v1"
fi
pass "Container 'chai-12-sick' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-12-sick)
if [ "$img" != "chai-12-api:v1" ]; then
  fail "chai-12-sick runs image '$img' — expected the same chai-12-api:v1. Remove it and rerun."
fi
if ! docker container inspect -f '{{range .Config.Env}}{{println .}}{{end}}' chai-12-sick | grep -q '^FAIL_HEALTH=.'; then
  fail "chai-12-sick has no FAIL_HEALTH set — it isn't sick, just healthy with a scary name. Rerun with -e FAIL_HEALTH=1."
fi
pass "Same image, with FAIL_HEALTH set"

state=$(docker container inspect -f '{{.State.Status}}' chai-12-sick)
if [ "$state" != "running" ]; then
  fail "chai-12-sick is '$state' — it must stay Up while its health fails (that's the whole point). Check docker logs chai-12-sick and rerun it."
fi

# Wait for the flip: starting -> (3 failed probes) -> unhealthy
health=""
for _ in $(seq 1 40); do
  health=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' chai-12-sick)
  [ "$health" = "unhealthy" ] && break
  sleep 2
done
if [ "$health" = "unhealthy" ]; then
  pass "Health status flipped to 'unhealthy' — while STATUS still says Up"
else
  fail "Health status is '${health:-none}' after 80s, not 'unhealthy'. With slow default timings the flip takes 90s+ — rebuild with --interval=5s --retries=3, rerun both containers, and try again."
fi

celebrate "Challenge complete. 'Up' and 'working' will never fool you again."
