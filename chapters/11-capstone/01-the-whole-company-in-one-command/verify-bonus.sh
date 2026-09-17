#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

state=$(docker container inspect -f '{{.State.Status}}' chai-45-db 2>/dev/null)
if [ "$state" != "running" ]; then
  fail "chai-45-db is ${state:-missing} — bring the platform back up first: docker compose up -d --wait (from workspace/ch45)."
fi
pass "chai-45-db is running"

# The marker row must exist…
row_epoch=$(docker exec chai-45-db psql -U chai -d chaicode -tAc \
  "SELECT floor(extract(epoch FROM created_at)) FROM deploy_log WHERE note='survived-the-recreate' ORDER BY created_at ASC LIMIT 1" 2>/dev/null | tr -d '[:space:]')
if [ -z "$row_epoch" ]; then
  fail "No 'survived-the-recreate' row in deploy_log. Insert it: docker compose exec db psql -U chai -d chaicode -c \"INSERT INTO deploy_log (note) VALUES ('survived-the-recreate');\""
fi
pass "Marker row 'survived-the-recreate' exists in deploy_log"

# …and must be OLDER than the current db container — proof the row outlived
# the container that wrote it (docker compose down destroys containers;
# only the chai-45-pgdata volume carries the data across).
created=$(docker inspect -f '{{.Created}}' chai-45-db)
created_epoch=$(node -e 'console.log(Math.floor(Date.parse(process.argv[1])/1000))' "$created")
if [ "$row_epoch" -lt "$created_epoch" ] 2>/dev/null; then
  pass "The row predates the current db container (row @$row_epoch < container created @$created_epoch)"
else
  fail "The current chai-45-db container is older than the marker row — the stack wasn't recreated after the insert. Run: docker compose down && docker compose up -d --wait (no -v!), then verify again."
fi

# And the platform must be back on its feet after the teardown.
status=$(curl -sS --max-time 15 http://127.0.0.1:8045/api/status 2>/dev/null)
ok=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log(j.db==="connected"&&j.cache==="connected"&&j.qdrant==="connected"?"yes":"no")}catch(e){console.log("no")}' "$status")
if [ "$ok" = "yes" ]; then
  pass "Platform fully reconnected after the teardown"
else
  fail "The stack is up but /api/status isn't all-connected yet. Give it a moment or check: docker compose ps"
fi

celebrate "Challenge complete. Containers are cattle; the data lives on the volume. You've proven it."
