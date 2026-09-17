# Exercise

**19.1 — Declare a two-service stack and bring it up with one command.**

The scaffolding is in `workspace/ch19/` — a `site/` folder with a static status page. Work from there (`cd ch19` in the lab terminal).

1. Create **`workspace/ch19/compose.yaml`** declaring project name **`chai-19`** (top-level `name:`) with two services:
   - **`web`** — from the **`nginx:alpine`** image, publishing host port **`8019`** to container port `80`, serving the scaffolded page (mount `./site` read-only at `/usr/share/nginx/html`).
   - **`redis`** — from the **`redis:alpine`** image. No ports, no mounts — it just needs to be on the stack.
2. Bring the whole stack up, detached, with a single command.
3. Look around while it runs: `docker compose ps` for the unit view, `docker compose logs web` for one service's logs. Notice the container names Compose chose.

**You pass when:**

- A `web` service container is running under project `chai-19`, created from `nginx:alpine`.
- A `redis` service container is running under project `chai-19`, created from `redis:alpine`.
- `http://localhost:8019` serves the ChaiCode status board page.

The verifier reads the compose labels and probes the port — it never sees which commands you ran, only the stack you left running.
