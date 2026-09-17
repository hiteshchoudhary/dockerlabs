# Exercise

**46.1 — Push the platform to a registry, then boot it from nothing but pulls.**

Work from `workspace/ch46/`. You need the Chapter 45 images as your starting point — if you've cleaned up since, rebuild them: `docker build -t chai-45-api ../ch45/api && docker build -t chai-45-web ../ch45/web`.

1. Run your own registry: a `registry:2` container named exactly **`chai-46-registry`**, published on host port **`8146`**. Confirm it's alive: `curl http://127.0.0.1:8146/v2/_catalog`.
2. Give both platform images real release names — registry host, repo, semver tag:
   - **`127.0.0.1:8146/chai-46-api:1.0.0`**
   - **`127.0.0.1:8146/chai-46-web:1.0.0`**

   and `docker push` both. Check the catalog again — two repositories.
3. Now make your laptop the "fresh machine". Take the platform down **keeping its volumes** (`docker compose -p chai-45 down`), then delete every local copy of the custom images: the `chai-45-api` and `chai-45-web` build tags *and* both registry-named tags you just pushed. `docker images` must show none of them — the registry now holds the only copies.
4. Write the deploy file: **`workspace/ch46/compose.registry.yaml`**. Same platform as Chapter 45 — same `name: chai-45`, same five services, container names, networks, volumes, healthchecks and hardening — with exactly two differences: `web` and `api` use `image: 127.0.0.1:8146/...:1.0.0` instead of `build:`, and the db's seed mount becomes `../ch45/seed.sql` (paths resolve relative to the compose file). No `build:` keys anywhere — a deploy file must work on a machine with no source.
5. Boot the company from the registry:

   ```
   docker compose -f compose.registry.yaml up -d --wait
   ```

   Watch the `Pulled` lines — that's your platform arriving over the wire, exactly as it would on any server.

**You pass when:**

- **`chai-46-registry`** (a `registry:2` container) is running and answering on port 8146.
- The registry catalog lists **`chai-46-api`** and **`chai-46-web`**, each with tag `1.0.0`.
- All five platform containers are running again and the api is healthy.
- The running `web` and `api` containers were created **from the registry-named images** (`127.0.0.1:8146/...`).
- The local build tags **`chai-45-api`** and **`chai-45-web`** do not exist — the registry is the source of truth.
- `http://localhost:8045` serves the site and `/api/status` shows db, cache and qdrant connected.

As always, the verifier interrogates live state — the registry's HTTP API, image references, container health — not the commands that got you there.
