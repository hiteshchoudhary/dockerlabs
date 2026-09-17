Postgres refuses to boot without a password: give the `db` service `environment:` with `POSTGRES_PASSWORD: chai`. The healthcheck block sits at the same indent level as `image:`. Its `test` must be a command that exists inside the postgres image — `pg_isready` does.

---

Healthcheck shape: `test: ["CMD-SHELL", "pg_isready -U postgres"]` with `interval: 5s`, `timeout: 3s`, `retries: 5`, `start_period: 10s`. For the wait, `depends_on` must be the *long form* — a map, not a list: `depends_on:` → `db:` → `condition: service_healthy`. The short list form (`- db`) only orders starts.

---

Full db service: `image: postgres:16-alpine`, `environment: {POSTGRES_PASSWORD: chai}`, the healthcheck above. Full web service: `image: nginx:alpine`, `ports: ["8020:80"]`, `volumes: ["./site:/usr/share/nginx/html:ro"]`, long-form `depends_on`. Challenge: add `restart: unless-stopped` to both services and re-run `docker compose up -d`.
