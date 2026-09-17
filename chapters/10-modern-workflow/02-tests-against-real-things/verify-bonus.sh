#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

RESULT="${LAB_WORKSPACE:?}/ch42/result.txt"

if [ ! -f "$RESULT" ]; then
  fail "No workspace/ch42/result.txt — finish the main exercise, then extend the script and re-run it."
fi

if grep -q '^PASS redis' "$RESULT"; then
  pass "result.txt reports: PASS redis"
else
  fail "result.txt has no 'PASS redis' line — add the redis leg to integration.sh (append with >>) and re-run it."
fi

if grep -q '^roundtrip-redis=chai aur docker' "$RESULT"; then
  pass "result.txt carries the redis round-trip: chai aur docker"
else
  fail "result.txt has no 'roundtrip-redis=chai aur docker' line — write what redis-cli GET actually returned."
fi

if ! grep -q '^PASS postgres' "$RESULT"; then
  fail "The postgres lines vanished from result.txt — the redis leg must APPEND (>>), not overwrite. Re-run the full script."
fi
pass "postgres markers still intact alongside redis"

for c in chai-42-db chai-42-cache; do
  if docker container inspect "$c" >/dev/null 2>&1; then
    fail "$c still exists — both throwaways must be gone. Tear down with 'docker rm -f $c' and re-run the script."
  fi
done
pass "chai-42-db and chai-42-cache both gone"

celebrate "Challenge complete. Two real services, tested and vaporized."
