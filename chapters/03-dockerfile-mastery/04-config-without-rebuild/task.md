# Exercise

**10.1 — Build once, run as demo and prod purely via environment.**

1. Read `workspace/ch10/app/server.js` — it answers differently depending on the `MODE` environment variable.
2. Create a `Dockerfile` in `workspace/ch10/app/`:
   - `FROM node:22-alpine`, a `WORKDIR`, `COPY`, and an exec-form `CMD` (Chapter 7's recipe),
   - plus **`ENV MODE=demo`** — the image's baked-in default personality.
3. Build it **once** as **`chai-10-api:v1`**.
4. Run two detached containers from that single image:
   - **`chai-10-demo`** on host port **`8010`** → container port `3000`, running in `demo` mode (the `ENV` default already does this),
   - **`chai-10-prod`** on host port **`8110`** → container port `3000`, with `MODE` overridden to `prod` at run time (`-e`).
5. Curl both ports and enjoy one artifact with two personalities.

**You pass when:**

- Containers **`chai-10-demo`** and **`chai-10-prod`** are both running **from the exact same image** (`chai-10-api:v1`).
- `chai-10-demo`'s environment carries `MODE=demo`; `chai-10-prod`'s carries `MODE=prod`.
- `http://localhost:8010` reports `"mode":"demo"` and `http://localhost:8110` reports `"mode":"prod"` — different answers, zero rebuilds.

The verifier never sees your commands — it compares the two containers' image IDs, reads their configured environments, and curls both ports.
