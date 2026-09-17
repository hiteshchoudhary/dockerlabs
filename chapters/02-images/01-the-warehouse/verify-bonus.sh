#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-04-digest >/dev/null 2>&1; then
  fail "No container named 'chai-04-digest'. Run one from the digest reference: docker run -d --name chai-04-digest -p 8004:80 nginx@sha256:..."
fi
pass "Container 'chai-04-digest' exists"

state=$(docker container inspect -f '{{.State.Status}}' chai-04-digest)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-04-digest is '$state', not running. Remove it (docker rm -f chai-04-digest) and run it detached (-d)."
fi

ref=$(docker container inspect -f '{{.Config.Image}}' chai-04-digest)
refdigest=$(echo "$ref" | grep -oE 'sha256:[0-9a-f]{64}' | head -1)
case "$ref" in
  *@sha256:*) pass "Image reference is in digest form: $ref" ;;
  *) fail "The container was started from '$ref' — a tag, not a digest. Use the name@sha256:... form: docker run -d --name chai-04-digest -p 8004:80 nginx@\$(cat ./ch04/digest.txt)" ;;
esac

digestfile="${LAB_WORKSPACE:?}/ch04/digest.txt"
recorded=$(grep -oE 'sha256:[0-9a-f]{64}' "$digestfile" 2>/dev/null | head -1)
if [ -z "$recorded" ]; then
  fail "workspace/ch04/digest.txt is missing or has no digest — finish the main exercise first."
fi
if [ "$refdigest" = "$recorded" ]; then
  pass "The digest in the reference matches the one you recorded"
else
  fail "The container's digest ($refdigest) isn't the one in digest.txt ($recorded). Re-run it pinned to your recorded digest."
fi

if curl -fsS --max-time 5 http://127.0.0.1:8004 >/dev/null 2>&1; then
  pass "http://127.0.0.1:8004 answers"
else
  fail "Nothing answering on http://127.0.0.1:8004. Publish the port when you run it: -p 8004:80"
fi

celebrate "Challenge complete. You ran an image no tag can ever move under you."
