#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-43-api >/dev/null 2>&1; then
  fail "chai-43-api isn't there — finish the main exercise first."
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-43-api)
[ "$state" = "running" ] || fail "chai-43-api is '$state' — it must be running for the probe."

PROBE="${LAB_WORKSPACE:?}/ch43/probe.txt"
if [ ! -f "$PROBE" ]; then
  fail "No workspace/ch43/probe.txt — run a busybox probe joined to the API's network namespace (--network container:chai-43-api) and save the wget output there."
fi
pass "probe.txt exists"

# The admin port is NOT published — only a probe inside the namespace can see it.
mine=$(docker run --rm --name chai-43-probe --network container:chai-43-api busybox wget -qO- --timeout=5 http://127.0.0.1:9090/ 2>/dev/null)
if [ -z "$mine" ]; then
  fail "The verifier's own probe couldn't reach the admin endpoint on :9090 — is chai-43-api running the unmodified scaffold binary?"
fi

theirs=$(tr -d '[:space:]' < "$PROBE")
minetrim=$(echo "$mine" | tr -d '[:space:]')
if [ -n "$theirs" ] && [ "$theirs" = "$minetrim" ]; then
  pass "probe.txt matches the admin endpoint's live response"
else
  fail "probe.txt doesn't match what :9090 actually serves. From inside the namespace: docker run --rm --network container:chai-43-api busybox wget -qO- http://127.0.0.1:9090/ > ./ch43/probe.txt"
fi

celebrate "Challenge complete. Unpublished ports keep no secrets from a namespace-joined probe."
