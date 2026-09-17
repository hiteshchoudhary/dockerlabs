# Exercise

**22.1 — Wire a live inner loop onto a build-based service.**

Scaffolding is in `workspace/ch22/` — an `app/` folder with a landing-page server (it re-reads `public/index.html` on every request), its `package.json`, and a Dockerfile. Work in `workspace/ch22/`.

1. Create **`workspace/ch22/compose.yaml`** with project name **`chai-22`** and one service:
   - **`web`** — `build: ./app`, publishing host port **`8022`** to container port `3000`.
2. Give it a `develop:` section with a **`watch:`** rule: `action: sync`, watching **`./app/public`** on the host, targeting **`/usr/src/app/public`** in the container.
3. Build and start the stack detached (`up -d --build`).
4. Feel the loop (do this part for yourself — it's the payoff): run `docker compose watch` in one terminal, edit `app/public/index.html` in another, refresh `http://localhost:8022`. Watch the `Syncing service "web"` line appear. Stop watch with `Ctrl-C` when done; the service keeps running.

**You pass when:**

- The resolved compose config shows a `develop.watch` rule on `web` with `action: sync`, path `app/public`, target `/usr/src/app/public`.
- The image **`chai-22-web`** has been built.
- The `web` container (project `chai-22`) is running and `http://localhost:8022` serves the landing page.

The verifier checks your declared config and the running stack — it doesn't run `watch` itself, and it can't tell whether you enjoyed step 4. Do it anyway.
