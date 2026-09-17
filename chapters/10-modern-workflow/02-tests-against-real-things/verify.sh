#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

SCRIPT="${LAB_WORKSPACE:?}/ch42/integration.sh"
RESULT="${LAB_WORKSPACE}/ch42/result.txt"

if [ ! -f "$SCRIPT" ]; then
  fail "No script at workspace/ch42/integration.sh — create the ch42 folder and write the test script there."
fi
pass "integration.sh exists"

if [ ! -x "$SCRIPT" ]; then
  fail "integration.sh isn't executable. Fix: chmod +x ch42/integration.sh"
fi
pass "integration.sh is executable"

if [ ! -f "$RESULT" ]; then
  fail "No workspace/ch42/result.txt — your script must write its report there. Run it: ./ch42/integration.sh"
fi

if grep -q '^PASS postgres' "$RESULT"; then
  pass "result.txt reports: PASS postgres"
else
  fail "result.txt has no 'PASS postgres' line. The script should write it only after the SQL round-trip succeeds."
fi

if grep -q '^roundtrip=chai aur docker' "$RESULT"; then
  pass "result.txt carries the round-tripped value: chai aur docker"
else
  fail "result.txt has no 'roundtrip=chai aur docker' line — write the value your SELECT actually returned (psql -tA gives it bare, but watch for leading whitespace)."
fi

if docker container inspect chai-42-db >/dev/null 2>&1; then
  state=$(docker container inspect -f '{{.State.Status}}' chai-42-db)
  fail "chai-42-db still exists (state: $state) — a leaked test database is a failed teardown. Use --rm at start and 'docker rm -f chai-42-db' at the end, then re-run the script."
fi
pass "chai-42-db is gone — the database was truly throwaway"

celebrate "Exercise 42.1 complete. Real database, real assertions, zero residue."
