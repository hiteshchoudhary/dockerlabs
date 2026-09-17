#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-01-hello >/dev/null 2>&1; then
  fail "No container named 'chai-01-hello' found. Did you pass --name chai-01-hello?"
fi
pass "Container 'chai-01-hello' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-01-hello)
case "$img" in
  hello-world|hello-world:*) pass "Created from the 'hello-world' image" ;;
  *) fail "Container uses image '$img' — expected 'hello-world'." ;;
esac

exitcode=$(docker container inspect -f '{{.State.ExitCode}}' chai-01-hello)
if [ "$exitcode" = "0" ]; then
  pass "It ran and exited cleanly (exit code 0)"
else
  fail "Exit code was $exitcode — the container didn't finish cleanly. Remove it (docker rm chai-01-hello) and run it again."
fi

celebrate "Exercise 1.1 complete. Your machine runs containers."
