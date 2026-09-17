Both env files use the same `KEY=value` format, one per line, no quotes needed — but they land in different places: `.env` is read automatically for `${...}` substitution in the YAML; `web.env` only does anything because the service lists it under `env_file:`. If a value looks wrong, `docker compose config` shows you exactly what resolved.

---

The web service needs: `build: ./app`, `ports: ["8021:3000"]`, `env_file: [web.env]`, and `environment:` with `CHAI_MODE: ${CHAI_MODE:-prod}`. First build-and-start is one command: `docker compose up -d --build`. If curl shows `(CHAI_MESSAGE not set)`, the env_file isn't listed on the service; if mode says `prod`, your `.env` isn't next to the compose file.

---

The debug service is three lines: `image: alpine`, `command: sleep infinity`, `profiles: ["debug"]`. A plain `up -d` will skip it — that's the pass condition, not a bug. For the challenge: `docker compose --profile debug up -d`, then `docker compose ps` shows both containers.
