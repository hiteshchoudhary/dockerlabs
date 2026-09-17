#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-27-app >/dev/null 2>&1; then
  fail "No container named 'chai-27-app' found. Run a chatty container with capped logs (see the exercise's full command)."
fi
pass "Container 'chai-27-app' exists"

state=$(docker container inspect -f '{{.State.Status}}' chai-27-app)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-27-app is '$state' — start it: docker start chai-27-app"
fi

driver=$(docker container inspect -f '{{.HostConfig.LogConfig.Type}}' chai-27-app)
if [ "$driver" = "json-file" ]; then
  pass "Log driver is json-file"
else
  fail "Log driver is '$driver' — expected json-file. Recreate with --log-driver json-file (log config can't be changed on a live container)."
fi

maxsize=$(docker container inspect -f '{{index .HostConfig.LogConfig.Config "max-size"}}' chai-27-app)
if [ "$maxsize" = "1m" ]; then
  pass "Rotation size cap is max-size=1m"
else
  fail "max-size is '${maxsize:-unset}' — expected 1m. Recreate chai-27-app with --log-opt max-size=1m"
fi

maxfile=$(docker container inspect -f '{{index .HostConfig.LogConfig.Config "max-file"}}' chai-27-app)
if [ "$maxfile" = "3" ]; then
  pass "Rotation file cap is max-file=3"
else
  fail "max-file is '${maxfile:-unset}' — expected 3. Recreate chai-27-app with --log-opt max-file=3"
fi

if [ -n "$(docker logs --tail 5 chai-27-app 2>&1)" ]; then
  pass "docker logs shows the stream flowing"
else
  fail "docker logs chai-27-app returned nothing — the container isn't printing. Its command should echo in a loop (see the exercise), and remember: echo to stdout, not to a file."
fi

celebrate "Exercise 27.1 complete. Chatty container, bounded disk — logging done right."
