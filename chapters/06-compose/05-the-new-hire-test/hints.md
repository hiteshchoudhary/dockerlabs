Build it incrementally, exactly like the Part taught: db + cache with healthchecks first (`docker compose up -d`, wait for `(healthy)` in `docker compose ps`), then api, then web. Don't forget the top-level `volumes:` block declaring `pgdata:` — mounting it in `db` isn't enough, it must be declared too.

---

The healthchecks: db → `test: ["CMD-SHELL", "pg_isready -U postgres"]`; cache → `test: ["CMD-SHELL", "redis-cli ping | grep PONG"]`; api → `test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:3000/health || exit 1"]`; web → `test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:80/ || exit 1"]`. Each with `interval: 5s`, `timeout: 3s`, `retries: 5`, `start_period: 10s`. api's `depends_on` is a map with TWO keys, `db:` and `cache:`, each carrying `condition: service_healthy`.

---

If `--wait` hangs: `docker compose ps` shows which service is stuck, `docker compose logs <svc>` says why (usually a missing `POSTGRES_PASSWORD` or a healthcheck tool that isn't in the image). If the api answers `"db":"down"`, the service names must be exactly `db` and `cache` — that's what the scaffolded server dials. Challenge: `adminer` needs just `image: adminer` and `profiles: ["debug"]`; start everything with `docker compose --profile debug up -d --build --wait`.
