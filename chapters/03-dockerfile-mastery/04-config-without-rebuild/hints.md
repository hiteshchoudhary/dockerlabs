Dockerfile in `workspace/ch10/app/`: `FROM node:22-alpine` → `WORKDIR /app` → `ENV MODE=demo` → `COPY server.js .` → `CMD ["node", "server.js"]`. Build once: `cd ch10/app && docker build -t chai-10-api:v1 .`

---

The two runs: `docker run -d --name chai-10-demo -p 8010:3000 chai-10-api:v1` (no `-e` needed — the ENV default is demo) and `docker run -d --name chai-10-prod -p 8110:3000 -e MODE=prod chai-10-api:v1`. Check what each believes: `docker inspect -f '{{.Config.Env}}' chai-10-prod`. Old attempts in the way? `docker rm -f chai-10-demo chai-10-prod`.

---

Challenge — add at the bottom of the Dockerfile: `ARG BUILD_ID` then `LABEL org.opencontainers.image.version=$BUILD_ID`, and build: `docker build -t chai-10-api:stamped --build-arg BUILD_ID=chai-2026-07-13 .` Read it back: `docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.version"}}' chai-10-api:stamped`.
