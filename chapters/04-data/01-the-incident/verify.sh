#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker volume inspect chai-13-pgdata >/dev/null 2>&1; then
  fail "No volume named 'chai-13-pgdata' found. Run the container with -v chai-13-pgdata:/var/lib/postgresql/data (Docker creates the volume for you)."
fi
pass "Volume 'chai-13-pgdata' exists"

if ! docker container inspect chai-13-db >/dev/null 2>&1; then
  fail "No container named 'chai-13-db' found. Run postgres:16-alpine with --name chai-13-db."
fi

img=$(docker container inspect -f '{{.Config.Image}}' chai-13-db)
case "$img" in
  postgres:16-alpine*) pass "Container 'chai-13-db' created from 'postgres:16-alpine'" ;;
  *) fail "chai-13-db uses image '$img' — expected 'postgres:16-alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-13-db)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-13-db is '$state', not running. Check 'docker logs chai-13-db' — did you set -e POSTGRES_PASSWORD=<anything>?"
fi

mount=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Type}}:{{.Name}}{{end}}{{end}}' chai-13-db)
if [ "$mount" = "volume:chai-13-pgdata" ]; then
  pass "chai-13-pgdata is mounted at /var/lib/postgresql/data"
else
  fail "The mount at /var/lib/postgresql/data is '${mount:-missing}' — expected the named volume chai-13-pgdata. (A 64-char hex name means Docker gave you an anonymous volume: re-run with -v chai-13-pgdata:/var/lib/postgresql/data.)"
fi

note=""
for _ in $(seq 1 30); do
  note=$(docker exec chai-13-db psql -U postgres -tAc "SELECT note FROM incident LIMIT 1" 2>/dev/null) && [ -n "$note" ] && break
  sleep 1
done
if [ "$note" = "data survives containers" ]; then
  pass "The 'incident' table still holds: '$note'"
else
  fail "Couldn't read the row from the incident table (got: '${note:-nothing}'). Create it: docker exec chai-13-db psql -U postgres -c \"INSERT INTO incident (note) VALUES ('data survives containers');\" (and the CREATE TABLE first)."
fi

vol_born=$(docker volume inspect -f '{{.CreatedAt}}' chai-13-pgdata)
con_born=$(docker container inspect -f '{{.Created}}' chai-13-db)
if node -e 'const [v,c]=process.argv.slice(1); process.exit(new Date(c).getTime() > new Date(v).getTime() ? 0 : 1)' "$vol_born" "$con_born"; then
  pass "Timestamp proof: the running container is younger than its volume (volume $vol_born, container $con_born)"
else
  fail "chai-13-db is not younger than chai-13-pgdata — it looks like the original container is still running. Do the drill: docker rm -f chai-13-db, then start a NEW one reattaching -v chai-13-pgdata:/var/lib/postgresql/data."
fi

celebrate "Exercise 13.1 complete. The container was cattle; the data never lived in it."
