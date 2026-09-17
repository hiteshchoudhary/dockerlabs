#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-03-box >/dev/null 2>&1; then
  fail "No container named 'chai-03-box' found. Run a long-lived alpine container with that name."
fi
pass "Container 'chai-03-box' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-03-box)
case "$img" in
  alpine|alpine:*) pass "Created from the 'alpine' image" ;;
  *) fail "Container uses image '$img' — expected 'alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-03-box)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-03-box is '$state' — it must stay alive. Give it a long command: sleep 3600."
fi

inside=$(docker exec chai-03-box cat /app/status.txt 2>/dev/null)
if [ "$inside" = "all systems go" ]; then
  pass "Inside the container: /app/status.txt says 'all systems go'"
else
  fail "/app/status.txt inside the container is missing or wrong (got: '${inside:-nothing}'). Use docker exec with sh -c so the redirect happens inside."
fi

hostfile="${LAB_WORKSPACE:?}/ch03/status.txt"
if [ ! -f "$hostfile" ]; then
  fail "No file at workspace/ch03/status.txt on the host. Extract it: docker cp chai-03-box:/app/status.txt ./ch03/status.txt"
fi
if grep -q "all systems go" "$hostfile"; then
  pass "Extracted to the host: workspace/ch03/status.txt matches"
else
  fail "workspace/ch03/status.txt exists but its content doesn't match. Copy the file again with docker cp."
fi

celebrate "Exercise 3.1 complete. No container can hide anything from you now."
