# Challenge

A platform you can boot is good. A platform that keeps its memory through a full teardown is the one you can operate.

1. Write a marker into the database *through the running stack*:

   ```
   docker compose exec db psql -U chai -d chaicode \
     -c "INSERT INTO deploy_log (note) VALUES ('survived-the-recreate');"
   ```

2. Now destroy every container: `docker compose down` — **without** `-v`, or you'll delete the very volume you're trying to prove. Networks gone, containers gone.
3. Bring the platform back: `docker compose up -d --wait`. Postgres finds `chai-45-pgdata` already populated, so `seed.sql` is skipped — and your marker row is still there.

**You pass when:** the `deploy_log` table contains `survived-the-recreate`, and that row's timestamp is **older than the current `chai-45-db` container's creation time** — hard proof that the data outlived the container that wrote it, because it lives on the volume, not in the writable layer.
