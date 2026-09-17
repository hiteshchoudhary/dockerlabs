# Exercise

**12.1 — Ship the API with a pulse and a manifest.**

1. Look at `workspace/ch12/app/server.js` — the ChaiCode API now serves **`/health`** alongside `/`.
2. Create a `Dockerfile` in `workspace/ch12/app/` (the Chapter 7 recipe, plus the shipping discipline):
   - `FROM node:22-alpine`, `WORKDIR`, `COPY`, exec-form `CMD`,
   - **OCI labels**: `org.opencontainers.image.title` with the exact value **`chai-12-api`**, plus a non-empty `org.opencontainers.image.description` and `org.opencontainers.image.authors` (your email or handle),
   - a **`HEALTHCHECK`** probing `http://127.0.0.1:3000/health` — use fast lab timings (`--interval=5s --timeout=3s --retries=3`) so you can watch it work; busybox `wget` is already in the image.
3. Build it as **`chai-12-api:v1`** and run a detached container named **`chai-12-api`** publishing host port **`8012`** to container port `3000`.
4. Watch the state machine: `docker ps` shows `(health: starting)`, then `(healthy)` within a few seconds.

**You pass when:**

- Image **`chai-12-api:v1`** exists, has a `HEALTHCHECK` baked in, and carries the three OCI labels (title exactly `chai-12-api`, description and authors non-empty).
- Container **`chai-12-api`** is running from it and reports **`healthy`** (the verifier watches `.State.Health.Status`, waiting patiently through `starting`).
- `http://localhost:8012/health` answers on the host side too.

The verifier reads image config, health state, and HTTP responses — nothing about how you got there.
