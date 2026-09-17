The Dockerfile is a plain text file named exactly `Dockerfile` (no extension) inside `workspace/ch07/app/`. Four instructions from the chapter plus the label: `FROM node:22-alpine`, `WORKDIR /app`, `LABEL org.opencontainers.image.title="chai-07-api"`, `COPY server.js .`, `CMD ["node", "server.js"]`.

---

Build from inside the app directory so the context is just your app: `cd ch07/app` (the lab terminal opens in `workspace/`), then `docker build -t chai-07-api:v1 .` — the trailing dot is the build context. Rebuilding after an edit? Same command; the tag moves to the new image.

---

Run and check: `docker run -d --name chai-07-api -p 8007:3000 chai-07-api:v1`, then `curl http://localhost:8007`. Name already taken from an earlier attempt: `docker rm -f chai-07-api` first. Challenge: `docker run -d --name chai-07-copy -p 8107:3000 chai-07-api:v1`.
