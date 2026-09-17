#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-26-oom >/dev/null 2>&1; then
  fail "No container named 'chai-26-oom' found. Run the hog: docker run --name chai-26-oom --memory 32m --memory-swap 32m alpine sh -c 'head -c 100m /dev/zero | tail'"
fi
pass "Container 'chai-26-oom' exists"

mem=$(docker container inspect -f '{{.HostConfig.Memory}}' chai-26-oom)
if [ "$mem" = "33554432" ]; then
  pass "It ran under a 32 MiB memory cap"
else
  fail "chai-26-oom's memory limit is '$mem' bytes — expected 33554432 (--memory 32m). Remove it (docker rm -f chai-26-oom) and run the hog again with the cap."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-26-oom)
if [ "$state" = "running" ]; then
  fail "chai-26-oom is still running — the hog hasn't hit the cap. Give it a moment, or make sure its command is: sh -c 'head -c 100m /dev/zero | tail'"
fi
pass "It is dead ($state)"

oom=$(docker container inspect -f '{{.State.OOMKilled}}' chai-26-oom)
exitcode=$(docker container inspect -f '{{.State.ExitCode}}' chai-26-oom)
if [ "$oom" = "true" ] || [ "$exitcode" = "137" ]; then
  pass "The kernel's OOM killer took it down (OOMKilled=$oom, exit code $exitcode)"
else
  fail "chai-26-oom exited $exitcode with OOMKilled=$oom — that's not an OOM kill. The command must out-eat the cap: docker rm -f chai-26-oom && docker run --name chai-26-oom --memory 32m --memory-swap 32m alpine sh -c 'head -c 100m /dev/zero | tail'"
fi

celebrate "Challenge complete. You've met the OOM killer on your own terms."
