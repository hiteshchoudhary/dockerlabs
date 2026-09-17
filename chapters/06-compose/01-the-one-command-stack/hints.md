The file structure: top-level `name: chai-19`, then `services:` with `web:` and `redis:` as keys under it. Each service needs at least `image:`. YAML is indentation-sensitive — two spaces per level, no tabs. Start it with `docker compose up -d` from inside `workspace/ch19/`.

---

The `web` service maps to flags you already know: `ports: ["8019:80"]` is `-p 8019:80`, and `volumes: ["./site:/usr/share/nginx/html:ro"]` is the bind mount from Part 4 — `./site` is relative to the compose file. If `up` complains the port is taken, some earlier attempt is still running: `docker compose down` and go again.

---

A minimal passing file: `name: chai-19`, `services:` → `web:` with `image: nginx:alpine`, `ports: ["8019:80"]`, `volumes: ["./site:/usr/share/nginx/html:ro"]`, and `redis:` with `image: redis:alpine`. For the challenge: change the port line to `"${WEB_PORT:-8019}:80"`, then `WEB_PORT=8119 docker compose -p chai-19-b up -d`.
