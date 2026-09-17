Skeleton: `mkdir -p ch42`, write `ch42/integration.sh` starting with `#!/usr/bin/env bash` and `set -euo pipefail`, then `chmod +x ch42/integration.sh` and run it with `./ch42/integration.sh`. Start the DB: `docker run -d --rm --name chai-42-db -e POSTGRES_PASSWORD=secret -p 8042:5432 postgres:16-alpine`.

---

The wait loop, bounded: `for i in $(seq 1 30); do docker exec chai-42-db pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break; sleep 1; done` — the `-h 127.0.0.1` matters (the image's init phase answers on the Unix socket before the real server is up). Round-trip with clean output: `row=$(docker exec chai-42-db psql -h 127.0.0.1 -U postgres -tAq -c "CREATE TABLE notes(body text); INSERT INTO notes VALUES ('chai aur docker'); SELECT body FROM notes;")` — `-tAq` gives you the bare value (drop the `-q` and you'll also capture `CREATE TABLE` / `INSERT 0 1` tags).

---

Finish: `docker rm -f chai-42-db`, then `printf 'PASS postgres\nroundtrip=%s\n' "$row" > ch42/result.txt`. Under `set -e`, guard anything allowed to fail (`|| true`). Challenge: same shape — `docker run -d --rm --name chai-42-cache redis:alpine`, wait until `docker exec chai-42-cache redis-cli ping` says PONG, then `docker exec chai-42-cache redis-cli SET book "chai aur docker"` and `val=$(docker exec chai-42-cache redis-cli GET book)` — and *append* the two redis lines with `>>` so the postgres lines survive.
