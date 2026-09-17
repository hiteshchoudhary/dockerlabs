Everything is a previous chapter. Dockerfile skeleton: pinned FROM (ch33: `docker pull node:22-alpine` then `docker image inspect -f '{{index .RepoDigests 0}}' node:22-alpine`), `WORKDIR /app`, `RUN addgroup -S chai && adduser -S -G chai chai && chown chai:chai /app` (ch30 — don't forget the workdir chown), `COPY --chown=chai:chai . .`, the two `LABEL`s, `USER chai`, `EXPOSE 3000`, `HEALTHCHECK`, `CMD ["node", "server.js"]`.

---

The healthcheck line: `HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 CMD wget -q --spider http://127.0.0.1:3000/healthz || exit 1`. Build from `workspace/ch34/app`, then run with the full ch31 armor: `docker run -d --name chai-34-api -p 8034:3000 --read-only --cap-drop ALL --security-opt no-new-privileges --memory 256m --pids-limit 100 chai-34-api:v1`. Give it ~10 seconds to turn (healthy) in `docker ps`.

---

Challenge — same run command plus two flags (from `workspace/`): `-v "$PWD/ch34/partner.key:/run/secrets/partner.key:ro" -e PARTNER_KEY_FILE=/run/secrets/partner.key`. Remove the old container first (`docker rm -f chai-34-api`). Check `curl localhost:8034` shows `partnerKeyLoaded: true`; then audit yourself like the verifier will: `docker inspect -f '{{.Config.Env}}' chai-34-api` — only a path in there, never a value.
