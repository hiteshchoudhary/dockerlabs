# Exercise

**23.1 — The full platform, one command, everything healthy.**

Scaffolding is in `workspace/ch23/`: `site/` (the static front) and `api/` (the ChaiCode API server + Dockerfile — it answers `/health`, and reports db/cache reachability on `/`). Work in `workspace/ch23/`.

Create **`workspace/ch23/compose.yaml`**, project name **`chai-23`**, four services:

1. **`db`** — **`postgres:16-alpine`**, `POSTGRES_PASSWORD` set, named volume **`pgdata`** mounted at `/var/lib/postgresql/data`, healthcheck via `pg_isready`. **No published ports.**
2. **`cache`** — **`redis:alpine`**, healthcheck via `redis-cli ping`. **No published ports.**
3. **`api`** — `build: ./api`, host port **`8123`** → container `3000`, an HTTP healthcheck against its `/health` (busybox `wget` is in the image), and `depends_on` **both** `db` and `cache` with `condition: service_healthy`.
4. **`web`** — **`nginx:alpine`**, host port **`8023`** → container `80`, serving `./site` (read-only at `/usr/share/nginx/html`), with an HTTP healthcheck (`wget` against `http://127.0.0.1:80/`).

Then the moment this Part has been building toward — bring it all up with one command and make it *prove* readiness:

```
docker compose up -d --build --wait
```

**You pass when:**

- All four containers of project `chai-23` are running **and healthy**.
- The resolved config shows `api` waiting on healthy `db` *and* healthy `cache`, and a healthcheck on every service.
- `http://localhost:8023` serves the platform page; `http://localhost:8123/` answers `{"service":"chaicode-api","db":"up","cache":"up"}`.
- `db` and `cache` publish **no** host ports — the network is the only way in.

As always, only the state you leave behind is graded — the verifier reads config, labels, health, and HTTP, not your history.
