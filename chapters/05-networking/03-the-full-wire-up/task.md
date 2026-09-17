# Exercise

**18.1 — One front door, two locked back rooms.**

1. Create a network named exactly **`chai-18-net`**.
2. Run the database: a detached `postgres:16-alpine` container named exactly **`chai-18-db`** on that network, with **no published ports**. (Postgres refuses to start without a password — set the `POSTGRES_PASSWORD` environment variable to anything, e.g. `chai`.)
3. Run the cache: a detached `redis:alpine` container named exactly **`chai-18-cache`** on the same network, **no published ports**.
4. Run the front door: a detached `nginx:alpine` container named exactly **`chai-18-api`** on the same network, published on host port **8018** (container port 80).
5. Prove the wiring from inside the api: `docker exec chai-18-api nc -z -w 2 chai-18-db 5432` and the same for `chai-18-cache 6379`. Then try `nc -z -w 2 127.0.0.1 5432` from your *host* — nothing there. That silence is the design.

**You pass when:**

- Network `chai-18-net` exists (bridge driver) with all three containers running and attached.
- `chai-18-db` (postgres) and `chai-18-cache` (redis) have completely **empty** `.HostConfig.PortBindings` — zero host exposure.
- `chai-18-api` (nginx) answers from the host on `http://127.0.0.1:8018`.
- From inside `chai-18-api`, both `chai-18-db:5432` and `chai-18-cache:6379` are reachable **by name**.

As always, the verifier never replays your commands — it inspects the network, reads the port bindings, curls the front door, and runs its own probes through your wiring.
