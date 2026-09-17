# Exercise

**13.1 — Kill the database container. Keep the database.**

1. Run a detached Postgres container named exactly **`chai-13-db`** from the **`postgres:16-alpine`** image, with:
   - the environment variable `POSTGRES_PASSWORD` set to anything (the image refuses to initialize without it),
   - the named volume **`chai-13-pgdata`** mounted at **`/var/lib/postgresql/data`**.

   No published port needed — you'll drive it entirely through `docker exec`.
2. Wait for Postgres to come up (`docker exec chai-13-db pg_isready -U postgres` should say *accepting connections*), then, using `psql` via `exec`, create a table named **`incident`** with a text column **`note`**, and insert one row whose `note` is exactly:
   ```
   data survives containers
   ```
3. Now cause the incident: **`docker rm -f chai-13-db`**. The container — and its writable layer — are gone.
4. Start a **new** detached container, again named **`chai-13-db`**, from the same image, reattaching the same **`chai-13-pgdata`** volume.
5. Query the `incident` table in the new container. Your row should be staring back at you.

**You pass when:**

- The volume `chai-13-pgdata` exists.
- A container named `chai-13-db` is running from `postgres:16-alpine`, with `chai-13-pgdata` mounted at `/var/lib/postgresql/data`.
- The `incident` table contains a row whose `note` is `data survives containers`.
- The running container is **younger than the volume** — timestamp proof that you really destroyed one container and attached a fresh one to the surviving data.

The verifier reads Docker state and runs its own `psql` query — it neither knows nor cares which commands got you here.
