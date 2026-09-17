Dockerfile shape (in `workspace/ch12/app/`): `FROM node:22-alpine` → `WORKDIR /app` → three `LABEL org.opencontainers.image.*` lines (title must be exactly `chai-12-api`) → `COPY server.js .` → the `HEALTHCHECK` line → `CMD ["node", "server.js"]`.

---

The health probe line: `HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1:3000/health || exit 1`. Build and run: `cd ch12/app && docker build -t chai-12-api:v1 . && docker run -d --name chai-12-api -p 8012:3000 chai-12-api:v1`. Give it ~10 seconds, then `docker ps` should show `(healthy)`.

---

Challenge: `docker run -d --name chai-12-sick -e FAIL_HEALTH=1 chai-12-api:v1` — then watch `docker ps` flip to `(unhealthy)` after ~15-20 seconds. Not flipping? Your healthcheck may be on slow default timings (30s × 3 retries) — rebuild with `--interval=5s --retries=3` and rerun both containers.
