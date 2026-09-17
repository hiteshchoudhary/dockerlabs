#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-31-flag >/dev/null 2>&1; then
  fail "No container named 'chai-31-flag'. Run alpine as uid 65534 with read-only rootfs, cap-drop ALL, no cap-adds, no-new-privileges — and keep it alive (sleep 3600)."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-31-flag)
if [ "$state" != "running" ]; then
  fail "chai-31-flag is '$state' — it must stay alive to be inspected. Give it a long command: sleep 3600."
fi
pass "Container 'chai-31-flag' is running"

ro=$(docker container inspect -f '{{.HostConfig.ReadonlyRootfs}}' chai-31-flag)
[ "$ro" = "true" ] || fail "Rootfs is writable — add --read-only."
pass "Root filesystem is read-only"

capdrop=$(docker container inspect -f '{{range .HostConfig.CapDrop}}{{.}} {{end}}' chai-31-flag)
echo "$capdrop" | grep -qiw "ALL" || fail "CapDrop is '${capdrop:-empty}' — expected ALL. Add --cap-drop ALL."
pass "All capabilities dropped"

capadd=$(docker container inspect -f '{{range .HostConfig.CapAdd}}{{.}} {{end}}' chai-31-flag)
nadds=$(echo "$capadd" | wc -w | tr -d ' ')
if [ "$nadds" != "0" ]; then
  fail "CapAdd holds '$capadd' — this sandbox adds back NOTHING. Remove every --cap-add."
fi
pass "Capability set is empty — the process holds no root powers at all"

secopt=$(docker container inspect -f '{{range .HostConfig.SecurityOpt}}{{.}} {{end}}' chai-31-flag)
echo "$secopt" | grep -q "no-new-privileges" || fail "no-new-privileges isn't set. Add --security-opt no-new-privileges."
pass "no-new-privileges set"

uid=$(docker exec chai-31-flag id -u 2>/dev/null)
if [ "$uid" != "65534" ]; then
  fail "id -u inside returned '${uid:-nothing}' — expected 65534. Re-run with --user 65534:65534."
fi
pass "Runs as uid 65534 (nobody) — and still runs happily"

celebrate "Challenge complete. Zero capabilities, zero writes, zero escalation — the strongest box yet."
