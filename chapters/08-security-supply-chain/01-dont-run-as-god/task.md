# Exercise

**30.1 — Build the API image that refuses to be root.**

The scaffold lives in **`workspace/ch30/app`** — `server.js` plus `package.json`, no dependencies. The server listens on port 3000 and writes to `/app/data` at startup, so a wrong ownership setup crashes on boot.

1. Write a `Dockerfile` in `workspace/ch30/app` that:
   - starts from `node:22-alpine`,
   - creates a **dedicated system user and group** (pick a name — `chai` is a good one),
   - copies the app in **owned by that user** (one layer, no `RUN chown -R` afterthought),
   - switches to that user with `USER`,
   - starts the server with `node server.js`.
2. Build it as **`chai-30-api:v1`**.
3. Run it detached as **`chai-30-api`**, publishing host port **8030** to container port 3000.
4. Prove it: `docker exec chai-30-api id` should *not* say uid 0, and `curl localhost:8030` should answer with the uid it runs as.

**You pass when:**

- Image `chai-30-api:v1` exists and its config carries a non-root `USER`.
- Container `chai-30-api` is running from that image with port 8030 published.
- `id -u` inside the running container is not `0`.
- The API answers on port 8030 and reports a non-zero uid (which also proves the file ownership is right — it couldn't have booted otherwise).

The verifier reads image config and live container state — it never sees your Dockerfile edits or your shell, only their results.
