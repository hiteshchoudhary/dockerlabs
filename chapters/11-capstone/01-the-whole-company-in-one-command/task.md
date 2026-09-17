# Exercise

**45.1 — Boot the whole platform with one command.**

Everything happens in `workspace/ch45/`. The app code is scaffolded (`api/`, `web/`, `seed.sql`) — you write **`compose.yaml`** from scratch.

1. Start the file with `name: chai-45` so the project name is fixed, then define five services. Give each an explicit `container_name`: **`chai-45-web`**, **`chai-45-api`**, **`chai-45-db`**, **`chai-45-cache`**, **`chai-45-qdrant`**. The service names must be `web`, `api`, `db`, `cache`, `qdrant` — the nginx proxy and the API's connection defaults resolve exactly those DNS names.
2. **web** — `build: ./web`, publish port **`8045:80`**. This is the platform's only published port; the API is reached through nginx's `/api` proxy, so port 8145 deliberately stays unused.
3. **api** — `build: ./api`, read-only root filesystem, a healthcheck that hits its own `http://127.0.0.1:3000/health` (busybox `wget` is in the image), and `depends_on` with `condition: service_healthy` for `db` and `cache` (qdrant: `service_started` is fine, or give it a healthcheck too).
4. **db** — `postgres:16-alpine` with `POSTGRES_USER=chai`, `POSTGRES_PASSWORD=chai-aur-docker`, `POSTGRES_DB=chaicode`, a `pg_isready` healthcheck, data on a volume named exactly **`chai-45-pgdata`**, and `./seed.sql` mounted read-only into `/docker-entrypoint-initdb.d/`.
5. **cache** — `redis:alpine` with a `redis-cli ping` healthcheck.
6. **qdrant** — `qdrant/qdrant` with its storage (`/qdrant/storage`) on a volume named exactly **`chai-45-qdrant`**.
7. Define two networks, `frontend` and `backend`: `web` on frontend only, `api` on both, `db`/`cache`/`qdrant` on backend only. None of the backend three may publish any host port.
8. Make `web` wait for a healthy `api` (nginx exits at startup if the name `api` doesn't resolve to something alive), then bring it all up:

   ```
   docker compose up -d --wait
   ```

   Open `http://localhost:8045` — the status page should show every service connected.

**You pass when:**

- All five containers are running under compose project `chai-45`, with the exact names above.
- `api`, `db` and `cache` report **healthy**; the api's compose config gates on healthy dependencies.
- The api runs as a **non-root** user on a **read-only** root filesystem.
- `chai-45_frontend` holds exactly web + api; `chai-45_backend` holds api + db + cache + qdrant; web is not on the backend network.
- `db`, `cache` and `qdrant` publish **no** host ports; web answers on **8045**.
- Volumes `chai-45-pgdata` and `chai-45-qdrant` are mounted where they belong.
- `http://localhost:8045/` serves the ChaiCode page, and `/api/status` reports `db`, `cache` and `qdrant` all `connected`.
- The seeded row `masala chai` exists in the `chai_menu` table.

The verifier reads Docker's state — networks, mounts, labels, live HTTP — not your shell history. Any compose file that produces this exact reality passes.
