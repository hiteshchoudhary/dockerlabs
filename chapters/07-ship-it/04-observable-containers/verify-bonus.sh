#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

evfile="${LAB_WORKSPACE:?}/ch27/events.txt"
if [ ! -f "$evfile" ]; then
  fail "No file at workspace/ch27/events.txt. Capture a window of the daemon's diary: docker events --since 10m --until 0s --filter container=chai-27-app > ./ch27/events.txt (after a stop/start cycle; mkdir -p ch27 first)."
fi
pass "workspace/ch27/events.txt exists"

if [ ! -s "$evfile" ]; then
  fail "events.txt is empty — your --since/--until window probably missed the action. Stop and start chai-27-app again, then re-capture with --since 10m --until 0s."
fi

if grep -E 'container start' "$evfile" | grep -q 'chai-27'; then
  pass "It records a container start event for chai-27-*"
else
  fail "No 'container start' event for a chai-27 container in events.txt. Do the cycle first (docker stop chai-27-app && docker start chai-27-app), then re-capture the window."
fi

if grep -E 'container stop' "$evfile" | grep -q 'chai-27'; then
  pass "It records a container stop event for chai-27-*"
else
  fail "No 'container stop' event for a chai-27 container in events.txt. Stop the container (docker stop chai-27-app), start it again, then re-capture the window."
fi

celebrate "Challenge complete. The daemon keeps a diary, and you know how to read it."
