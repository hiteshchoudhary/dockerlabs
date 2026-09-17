#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if docker container inspect chai-39-timeout >/dev/null 2>&1; then
  fail "Container 'chai-39-timeout' still exists — the timeout must REAP it (docker rm -f) once the wall clock expires. It's still there, which means it was never reaped."
fi
pass "chai-39-timeout is gone — the wall-clock guard reaped it"

f="${LAB_WORKSPACE:?}/ch39/timeout.txt"
if [ ! -f "$f" ]; then
  fail "No marker at workspace/ch39/timeout.txt. When the timeout fires, record it: echo 'killed after timeout' > ./ch39/timeout.txt"
fi
chars=$(tr -d '[:space:]' < "$f" | wc -c | tr -d ' ')
if [ "${chars:-0}" -ge 5 ]; then
  pass "Timeout marker recorded ($(head -1 "$f"))"
else
  fail "workspace/ch39/timeout.txt is empty or trivial — write a line recording the timeout kill."
fi

celebrate "Challenge complete. Runaway time is caged too — the last bar is in place."
