# Exercise

**42.1 — Build a throwaway-database integration test from primitives.**

Write a shell script **`workspace/ch42/integration.sh`** (create the `ch42` folder; the lab terminal opens in `workspace/`), make it executable, and run it. The script must perform the four Testcontainers moves:

1. **Start throwaway:** a detached Postgres from `postgres:16-alpine` named exactly **`chai-42-db`**, started with `--rm` so it self-deletes on stop (set `POSTGRES_PASSWORD`; publish `8042:5432` if you want host access).
2. **Wait for ready:** loop on `pg_isready` (via `docker exec`, with `-h 127.0.0.1`) until it succeeds — with a bounded number of attempts, not forever.
3. **Test reality:** run a real SQL round-trip through `psql` — create a table, insert the exact value `chai aur docker`, select it back, and capture what the database actually returned.
4. **Tear down and report:** remove the database, then write **`workspace/ch42/result.txt`** containing these two lines (the roundtrip value must be what your `SELECT` returned, not a hardcoded string):
   ```
   PASS postgres
   roundtrip=chai aur docker
   ```

**You pass when:**

- `workspace/ch42/integration.sh` exists and is executable.
- `workspace/ch42/result.txt` contains a line `PASS postgres` and a line `roundtrip=chai aur docker`.
- No container named `chai-42-db` exists anymore — running *or* stopped. Ephemerality is the point; a leaked database is a failed test.

State is all the verifier sees — the results file and what's (not) left in Docker — never your command history.
