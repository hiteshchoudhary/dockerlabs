#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-03-box >/dev/null 2>&1; then
  fail "chai-03-box doesn't exist — finish the main exercise first."
fi

actual=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' chai-03-box)
if [ -z "$actual" ]; then
  fail "chai-03-box has no IP right now — is it running?"
fi
pass "Container's actual IP: $actual"

ipfile="${LAB_WORKSPACE:?}/ch03/ip.txt"
if [ ! -f "$ipfile" ]; then
  fail "No file at workspace/ch03/ip.txt. Write the template's output there."
fi

written=$(tr -d '[:space:]' < "$ipfile")
if [ "$written" = "$actual" ]; then
  pass "workspace/ch03/ip.txt matches exactly"
else
  fail "ip.txt says '$written' but the container's IP is '$actual'. Use the range template from the chapter."
fi

celebrate "Challenge complete. Format templates are yours."
