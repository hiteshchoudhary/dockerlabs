Work in `workspace/ch30/app` (from the lab terminal: `cd ch30/app`). The Dockerfile skeleton is: `FROM node:22-alpine`, `WORKDIR /app`, create the user, `COPY` the app, `USER`, `EXPOSE 3000`, `CMD ["node", "server.js"]`. On Alpine the user-creation spell is `RUN addgroup -S chai && adduser -S -G chai chai`.

---

The trap is ownership — twice. `COPY . .` leaves files owned by root: fix it in the COPY itself with `COPY --chown=chai:chai . .`, not a `RUN chown -R` afterthought (that duplicates every file into a new layer). And `WORKDIR /app` created the directory itself as root, so the server still can't `mkdir /app/data` — chown the empty dir when you create the user: `RUN addgroup -S chai && adduser -S -G chai chai && chown chai:chai /app`. If the container exits instantly, `docker logs chai-30-api` shows the `EACCES` crash — that's the ownership bug talking.

---

Full flow from `workspace/ch30/app`: `docker build -t chai-30-api:v1 .` then `docker run -d --name chai-30-api -p 8030:3000 chai-30-api:v1`. Check with `docker exec chai-30-api id -u` and `curl localhost:8030`. Challenge: `docker run -d --name chai-30-flag --user node node:22-alpine sleep 3600`.
