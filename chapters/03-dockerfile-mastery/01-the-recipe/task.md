# Exercise

**7.1 — Write your first Dockerfile and ship the ChaiCode API.**

1. Look at the app: `workspace/ch07/app/server.js` — a zero-dependency Node server that answers JSON on port `3000`.
2. Create a `Dockerfile` next to it (in `workspace/ch07/app/`) that:
   - starts `FROM node:22-alpine`,
   - carries the label **`org.opencontainers.image.title`** with the exact value **`chai-07-api`** (this is your builder's mark — it's how the verifier knows *you* built the image instead of pulling one),
   - copies `server.js` into the image (a `WORKDIR` like `/app` keeps it tidy),
   - declares `CMD` so a container starts the server with `node`.
3. Build it from that directory, tagging the image **`chai-07-api:v1`**.
4. Run a detached container named **`chai-07-api`** from it, publishing host port **`8007`** to container port `3000`.
5. Prove it's alive: `curl http://localhost:8007` should answer JSON from `chaicode-api`.

**You pass when:**

- An image **`chai-07-api:v1`** exists locally.
- It carries the label `org.opencontainers.image.title` = `chai-07-api`.
- A container named **`chai-07-api`** is running from that image.
- `http://localhost:8007` answers with the ChaiCode API's JSON.

As always, the verifier reads the resulting image, container, and HTTP state — it never sees which commands you ran or how many attempts it took.
