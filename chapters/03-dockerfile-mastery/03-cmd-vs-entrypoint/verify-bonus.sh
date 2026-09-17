#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-09-peek >/dev/null 2>&1; then
  fail "No container named 'chai-09-peek'. Run one with the entrypoint overridden to cat: docker run --name chai-09-peek --entrypoint cat chai-09-tool:v1 /usr/local/bin/greet"
fi
pass "Container 'chai-09-peek' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-09-peek)
if [ "$img" != "chai-09-tool:v1" ]; then
  fail "chai-09-peek was created from '$img' — expected chai-09-tool:v1. Remove it (docker rm chai-09-peek) and rerun from your tool image."
fi
pass "Created from chai-09-tool:v1"

exitcode=$(docker container inspect -f '{{.State.ExitCode}}' chai-09-peek)
if [ "$exitcode" != "0" ]; then
  fail "chai-09-peek exited with code $exitcode. Did cat get the right path as its argument? Remove it and try: --entrypoint cat ... chai-09-tool:v1 /usr/local/bin/greet"
fi
pass "It exited cleanly (code 0)"

logs=$(docker logs chai-09-peek 2>&1)
if echo "$logs" | grep -q 'echo "chai says:' ; then
  pass "Its logs show the script's source, not a greeting — the entrypoint was truly overridden"
else
  fail "The logs don't contain the greet script's source (got: '${logs:-nothing}'). Override the executable with --entrypoint cat (before the image name) and pass /usr/local/bin/greet as the argument (after it)."
fi

celebrate "Challenge complete. No image's entrypoint can hide from you now."
