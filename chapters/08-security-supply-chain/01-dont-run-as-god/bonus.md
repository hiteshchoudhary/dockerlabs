# Challenge

You won't always own the Dockerfile. Prove you can de-god an **official image at runtime**.

The official `node:22-alpine` image runs as root by default, but ships a ready-made unprivileged account named `node` (uid 1000). Run a container named **`chai-30-flag`** from `node:22-alpine` that:

- is forced to run as the `node` user via **`--user`** (name or uid — your call),
- stays alive long enough to be inspected (give it something long-running to do).

Then compare for yourself: `docker exec chai-30-flag id` versus the same command in `chai-30-api`. Two different roads — build-time `USER` versus runtime `--user` — to the same place: uid ≠ 0.

**You pass when:** `chai-30-flag` is running from `node:22-alpine`, its inspect config shows a user override, and `id -u` inside it returns a non-zero uid.
