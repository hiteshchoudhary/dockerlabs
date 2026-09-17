Both files live in `workspace/ch08/app/`. `.dockerignore` needs at least one line: `node_modules`. The Dockerfile's shape: `FROM node:22-alpine` → `WORKDIR /app` → `COPY package*.json ./` → `RUN npm ci` → `COPY . .` → `CMD ["node", "server.js"]`.

---

Build from the app directory: `cd ch08/app && docker build -t chai-08-api:v1 .` then `docker run -d --name chai-08-api -p 8008:3000 chai-08-api:v1`. If the verifier says the order is wrong, check that the package-files `COPY` comes *before* `RUN npm ci`, and `COPY . .` comes *after*. Rebuild after any Dockerfile edit — and `docker rm -f chai-08-api` before rerunning.

---

Challenge: `echo "API_KEY=super-secret-chai" > secret.env` inside `ch08/app/`, add `secret.env` (or `*.env`) as a new line in `.dockerignore`, rebuild the same tag. Check yourself with `docker run --rm chai-08-api:v1 ls /app` — no secret.env should appear.
