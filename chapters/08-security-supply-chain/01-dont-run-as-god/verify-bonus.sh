#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-30-flag >/dev/null 2>&1; then
  fail "No container named 'chai-30-flag'. Run the official node image as non-root: docker run -d --name chai-30-flag --user node node:22-alpine sleep 3600"
fi
pass "Container 'chai-30-flag' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-30-flag)
case "$img" in
  node:22-alpine|node:22-alpine@*) pass "Created from 'node:22-alpine'" ;;
  *) fail "chai-30-flag uses image '$img' — expected 'node:22-alpine' (the point is de-godding an OFFICIAL image)." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-30-flag)
if [ "$state" != "running" ]; then
  fail "chai-30-flag is '$state' — it must stay alive to be inspected. Give it a long command, e.g. sleep 3600."
fi
pass "It is running"

cfguser=$(docker container inspect -f '{{.Config.User}}' chai-30-flag)
case "$cfguser" in
  ""|"root"|"0"|"0:0")
    fail "No user override recorded (Config.User is '${cfguser:-<empty>}'). Re-run with --user node (or --user 1000)."
    ;;
  *) pass "Runtime user override recorded: '$cfguser'" ;;
esac

uid=$(docker exec chai-30-flag id -u 2>/dev/null)
if [ -z "$uid" ] || [ "$uid" = "0" ]; then
  fail "id -u inside chai-30-flag returned '${uid:-nothing}' — expected a non-zero uid. Re-run with --user node."
fi
pass "Process inside runs as uid $uid — official image, de-godded at runtime"

celebrate "Challenge complete. Build-time USER or runtime --user — either way, never god."
