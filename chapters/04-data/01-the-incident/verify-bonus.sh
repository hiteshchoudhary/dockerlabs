#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-13-db >/dev/null 2>&1; then
  fail "chai-13-db doesn't exist — finish the main exercise first."
fi

difffile="${LAB_WORKSPACE:?}/ch13/diff.txt"
if [ ! -f "$difffile" ]; then
  fail "No file at workspace/ch13/diff.txt. Capture the evidence before the kill: mkdir -p ch13 && docker diff chai-13-db > ./ch13/diff.txt"
fi
if grep -Eq '^A /doomed\.txt$' "$difffile"; then
  pass "diff.txt records 'A /doomed.txt' — the writable layer held the file"
else
  fail "workspace/ch13/diff.txt doesn't show '/doomed.txt' being added. Write the file first (docker exec chai-13-db sh -c 'echo doomed > /doomed.txt'), THEN capture docker diff."
fi

if docker exec chai-13-db test -f /doomed.txt 2>/dev/null; then
  fail "/doomed.txt is still inside chai-13-db — that means this is the same container. Recreate it (docker rm -f chai-13-db, then run a fresh one with the chai-13-pgdata volume) and watch the file vanish."
else
  pass "/doomed.txt is gone — it died with the old container's writable layer"
fi

note=""
for _ in $(seq 1 30); do
  note=$(docker exec chai-13-db psql -U postgres -tAc "SELECT note FROM incident LIMIT 1" 2>/dev/null) && [ -n "$note" ] && break
  sleep 1
done
if [ "$note" = "data survives containers" ]; then
  pass "…and the incident row is still alive in the volume"
else
  fail "The incident row is missing (got: '${note:-nothing}') — did the new container reattach -v chai-13-pgdata:/var/lib/postgresql/data?"
fi

celebrate "Challenge complete. Writable layer: ephemeral. Volume: forever."
