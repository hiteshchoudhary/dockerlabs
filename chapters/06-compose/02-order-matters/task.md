# Exercise

**20.1 — Make the web front wait for a genuinely ready database.**

Scaffolding is in `workspace/ch20/` (a `site/` folder). Work there.

1. Create **`workspace/ch20/compose.yaml`** with project name **`chai-20`** and two services:
   - **`db`** — from **`postgres:16-alpine`**, with `POSTGRES_PASSWORD` set (any value), and a **healthcheck** that probes readiness with `pg_isready` (pick a sensible `interval`/`timeout`/`retries`).
   - **`web`** — from **`nginx:alpine`**, publishing host port **`8020`** to container port `80`, serving `./site` (read-only mount at `/usr/share/nginx/html`), and — the point of the chapter — a long-form `depends_on` on `db` with **`condition: service_healthy`**.
2. Bring the stack up detached and watch the order: `db` must report `Healthy` before `web` even starts. Run `docker compose ps` until you see `(healthy)` next to the db.
3. Peek at the machinery: `docker inspect -f '{{.State.Health.Status}}' chai-20-db-1`.

**You pass when:**

- Your compose file gives `db` a `pg_isready`-based healthcheck and gives `web` a `depends_on` on `db` with `condition: service_healthy`.
- The `db` container (project `chai-20`) is running **and healthy**.
- The `web` container is running, and `http://localhost:8020` serves the orders dashboard.

The verifier parses your compose file's resolved config and inspects live container state — it doesn't care how many attempts it took you to get there.
