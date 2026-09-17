Skeleton first, details second. Start `workspace/ch45/compose.yaml` with `name: chai-45`, then five services (`web`, `api`, `db`, `cache`, `qdrant`), then top-level `networks:` (`frontend:` and `backend:`, no options needed) and `volumes:`. To get the exact volume names, use the `name:` key: `pgdata: { name: chai-45-pgdata }` — otherwise compose prefixes the project name (`chai-45_pgdata` would fail the check). Each service lists its networks: web `[frontend]`, api `[frontend, backend]`, the rest `[backend]`.

---

The healthchecks, exactly as Chapters 12 and 20 taught: db `test: ["CMD-SHELL", "pg_isready -U chai -d chaicode"]`, cache `test: ["CMD", "redis-cli", "ping"]`, api `test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/health"]` — each with `interval: 5s`, `retries: 10`, and `start_period: 5s` on the api. Hardening the api service: `read_only: true` (the Dockerfile already sets `USER node`). Gate startup: api gets `depends_on:` with `db: { condition: service_healthy }`, `cache: { condition: service_healthy }`, `qdrant: { condition: service_started }`; web gets `api: { condition: service_healthy }`. Seed mount on db: `- ./seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro`.

---

Full working file, if you're stuck (from `workspace/ch45/`, then `docker compose up -d --wait`):

```yaml
name: chai-45
services:
  web:
    build: ./web
    container_name: chai-45-web
    ports: ["8045:80"]
    networks: [frontend]
    depends_on:
      api: { condition: service_healthy }
  api:
    build: ./api
    container_name: chai-45-api
    read_only: true
    networks: [frontend, backend]
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/health"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s
    depends_on:
      db: { condition: service_healthy }
      cache: { condition: service_healthy }
      qdrant: { condition: service_started }
  db:
    image: postgres:16-alpine
    container_name: chai-45-db
    environment:
      POSTGRES_USER: chai
      POSTGRES_PASSWORD: chai-aur-docker
      POSTGRES_DB: chaicode
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro
    networks: [backend]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U chai -d chaicode"]
      interval: 5s
      timeout: 3s
      retries: 10
  cache:
    image: redis:alpine
    container_name: chai-45-cache
    networks: [backend]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10
  qdrant:
    image: qdrant/qdrant
    container_name: chai-45-qdrant
    volumes: [qdrant:/qdrant/storage]
    networks: [backend]
networks:
  frontend:
  backend:
volumes:
  pgdata: { name: chai-45-pgdata }
  qdrant: { name: chai-45-qdrant }
```

Challenge: `docker compose exec db psql -U chai -d chaicode -c "INSERT INTO deploy_log (note) VALUES ('survived-the-recreate');"` then `docker compose down && docker compose up -d --wait`. No `-v` on the down.
