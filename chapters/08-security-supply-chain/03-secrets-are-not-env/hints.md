Dockerfile shape (in `workspace/ch32`): `FROM node:22-alpine`, `WORKDIR /app`, `COPY server.js install-deps.sh ./`, then the secret-mounted step, then `EXPOSE 3000` and `CMD ["node", "server.js"]`. The secret step is one line: `RUN --mount=type=secret,id=apitoken sh ./install-deps.sh`. Do NOT copy `token.txt` — that would put it in a layer forever.

---

The build command wires the id to the file: from `workspace/ch32`, `docker build --secret id=apitoken,src=token.txt -t chai-32-api:v1 .`. If the build fails with the script's FATAL message, the `--secret` flag and the `id=` in the Dockerfile don't match up. Audit afterwards: `docker history --no-trunc chai-32-api:v1 | grep chai_live` should find nothing.

---

Challenge (from `workspace/`): `docker run -d --name chai-32-app -p 8032:3000 -v "$PWD/ch32/token.txt:/run/secrets/apitoken:ro" chai-32-api:v1` — the `:ro` suffix makes the mount read-only. Check with `curl localhost:8032`: `secretLoaded` should be `true` and `fingerprint` should equal `buildFingerprint`. No `-e` flags anywhere near a token.
