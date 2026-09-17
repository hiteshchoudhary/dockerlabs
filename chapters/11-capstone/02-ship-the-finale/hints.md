Step 1 is Chapter 24 verbatim: `docker run -d --name chai-46-registry -p 8146:5000 registry:2`. Step 2 is two `docker tag` + two `docker push` commands — the registry host being part of the name (`127.0.0.1:8146/chai-46-api:1.0.0`) is what routes the push; localhost registries are exempt from the TLS requirement, so no config needed. If the Chapter 45 images are missing, rebuild: `docker build -t chai-45-api ../ch45/api && docker build -t chai-45-web ../ch45/web`.

---

The teardown order matters: `docker compose -p chai-45 down` (no `-v` — volumes stay) *before* `docker rmi`, because you can't remove images that running containers use. Then remove all four tags: `docker rmi chai-45-api chai-45-web 127.0.0.1:8146/chai-46-api:1.0.0 127.0.0.1:8146/chai-46-web:1.0.0`. For the deploy file: copy your ch45 `compose.yaml` to `ch46/compose.registry.yaml`, replace `build: ./api` with `image: 127.0.0.1:8146/chai-46-api:1.0.0` (same for web), and change the seed mount to `../ch45/seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro`. Keep `name: chai-45`, the volume `name:` keys, and everything else — then `docker compose -f compose.registry.yaml up -d --wait` pulls and boots.

---

Challenge, in full: `docker build -t 127.0.0.1:8146/chai-46-api:1.0.1 --build-arg APP_VERSION=1.0.1 ../ch45/api` then `docker push 127.0.0.1:8146/chai-46-api:1.0.1`, change the api line in `compose.registry.yaml` from `1.0.0` to `1.0.1`, and re-run `docker compose -f compose.registry.yaml up -d --wait`. Confirm with `curl -s localhost:8045/api/status` — the version field should read `1.0.1`. If it still says `1.0.0`, you edited the file but didn't re-run `up`, or you set the version at run time instead of `--build-arg` (the verifier checks the image, not just the words).
