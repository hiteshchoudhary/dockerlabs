#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-02-crash >/dev/null 2>&1; then
  fail "No container named 'chai-02-crash' found."
fi
pass "Container 'chai-02-crash' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-02-crash)
case "$img" in
  alpine|alpine:*) pass "Created from the 'alpine' image" ;;
  *) fail "Container uses image '$img' — expected 'alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-02-crash)
[ "$state" = "exited" ] && pass "It has exited" || fail "chai-02-crash is '$state' — it should be dead already."

code=$(docker container inspect -f '{{.State.ExitCode}}' chai-02-crash)
if [ "$code" = "7" ]; then
  pass "Exit code is exactly 7"
else
  fail "Exit code is $code, not 7. A shell can choose its own death: sh -c \"exit 7\""
fi

celebrate "Challenge complete. You read exit codes like a coroner."
