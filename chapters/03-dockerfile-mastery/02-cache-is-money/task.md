# Exercise

**8.1 — Deps-first Dockerfile with a .dockerignore.**

1. Look at `workspace/ch08/app/` — the ChaiCode API now has `package.json`, `package-lock.json`, and one real dependency.
2. In that directory, create a **`.dockerignore`** that excludes at least **`node_modules`**.
3. Create a `Dockerfile` using the deps-first pattern:
   - `FROM node:22-alpine`, a `WORKDIR`,
   - copy **only** `package.json` + `package-lock.json` (hint: `package*.json`),
   - `RUN npm ci` (or `npm install`) — the expensive step, safely above the code,
   - **then** copy the rest of the app (`COPY . .`),
   - `CMD` to start the server.
4. Build it as **`chai-08-api:v1`**, then run a detached container named **`chai-08-api`** publishing host port **`8008`** to container port `3000`.
5. Feel the payoff: edit `server.js` trivially (add a comment), rebuild, and watch `npm ci` report `CACHED`.

**You pass when:**

- Image **`chai-08-api:v1`** exists, and its layer history shows the deps-first order: a `COPY` of the package files, then the npm install step, then the full-app `COPY`.
- `workspace/ch08/app/.dockerignore` exists and excludes `node_modules`.
- Container **`chai-08-api`** is running from that image and `http://localhost:8008` answers JSON with an `uptime` field (proof the dependency actually installed).

The verifier reads the image's history and the resulting state — the order of your *layers* is what's graded, not the order you typed commands in.
