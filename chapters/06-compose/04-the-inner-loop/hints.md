Start from Chapter 21's shape: `name: chai-22`, one `web` service with `build: ./app` and `ports: ["8022:3000"]`. Get that running with `docker compose up -d --build` before touching watch — `curl http://localhost:8022` should show the landing page.

---

`develop:` sits inside the service, at the same level as `build:`. Under it, `watch:` is a *list* of rules; each rule is a map with `action`, `path`, and (for sync) `target`. Indentation: `develop:` → two more spaces → `watch:` → list items starting with `- action: sync`. Check your work with `docker compose config` — the develop section should survive into the resolved output.

---

The full rule set:
`develop:` → `watch:` → `- action: sync` / `path: ./app/public` / `target: /usr/src/app/public`, and for the challenge a second item `- action: rebuild` / `path: ./app/package.json` (rebuild rules take no target). Apply with `docker compose up -d`, then run `docker compose watch` and edit `app/public/index.html` to see it sync.
