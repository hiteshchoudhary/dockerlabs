Docker creates a named volume on first use — no `docker volume create` needed: `docker run -d --name chai-13-db -e POSTGRES_PASSWORD=chai -v chai-13-pgdata:/var/lib/postgresql/data postgres:16-alpine`. Give it a few seconds to initialize; `docker exec chai-13-db pg_isready -U postgres` (or `docker logs chai-13-db`) tells you when it's ready.

---

`psql` one-liners through exec need no password — inside the container it connects over the local socket: `docker exec chai-13-db psql -U postgres -c "CREATE TABLE incident (id serial PRIMARY KEY, note text);"` then `docker exec chai-13-db psql -U postgres -c "INSERT INTO incident (note) VALUES ('data survives containers');"`. Check with `... psql -U postgres -c "SELECT * FROM incident;"`.

---

The full drill: `docker rm -f chai-13-db`, then re-run the exact `docker run` command from hint 1 (the volume is reattached, and with existing data Postgres skips initialization). Challenge: `docker exec chai-13-db sh -c 'echo doomed > /doomed.txt'`, then `mkdir -p ch13 && docker diff chai-13-db > ./ch13/diff.txt`, then rm -f and re-run once more — `docker exec chai-13-db ls /doomed.txt` now errors, while the `incident` row survives.
