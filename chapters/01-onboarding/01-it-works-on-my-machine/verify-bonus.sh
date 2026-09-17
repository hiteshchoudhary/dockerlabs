#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-01-echo >/dev/null 2>&1; then
  fail "No container named 'chai-01-echo' found. Did you pass --name chai-01-echo?"
fi
pass "Container 'chai-01-echo' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-01-echo)
case "$img" in
  alpine|alpine:*) pass "Created from the 'alpine' image" ;;
  *) fail "Container uses image '$img' — expected 'alpine'." ;;
esac

if docker logs chai-01-echo 2>&1 | grep -q "hello chaicode"; then
  pass "Its logs say 'hello chaicode'"
else
  fail "The logs don't contain 'hello chaicode'. Everything after the image name becomes the container's command — try: docker run --name chai-01-echo alpine echo \"hello chaicode\" (remove the old one first: docker rm chai-01-echo)."
fi

celebrate "Challenge complete. You can make a container run anything."
