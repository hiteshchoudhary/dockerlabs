# Order Matters

Here's a bug I've seen take down more first deploys than anything else in this book. The stack from last chapter grows a database. Someone adds `depends_on`, deploys, and the app crashes on boot with `ECONNREFUSED` — *sometimes*. On the laptop it's fine. In CI it fails one run in five. The team adds a `sleep 10` to the startup script, and now the stack works, slowly, until the day the database takes eleven seconds.

The root cause is a single misreading, so let's kill it precisely.

## What `depends_on` actually promises

```yaml
services:
  web:
    image: nginx:alpine
    depends_on:
      - db
  db:
    image: postgres:16-alpine
```

This short form promises exactly one thing: Compose will *start* `db` before it *starts* `web`. That's an ordering of `docker start` calls — nothing more. And "started" is not "ready". Postgres's container is `running` the instant its process launches, but for the next several seconds that process is busy: initializing a data directory, replaying WAL, binding its socket. Any client connecting during that window gets `connection refused` — from a container that `docker ps` cheerfully reports as `Up 2 seconds`.

**A running container is not a ready service.** The container state machine you learned in Chapter 2 knows `created`, `running`, `exited` — it has no idea what the process *inside* means by "ready". If you want Docker to know that, you have to teach it.

## Teaching Docker what "ready" means

You met `HEALTHCHECK` in the Dockerfile back in Chapter 12. Compose lets you attach one per service, no image rebuild needed:

```yaml
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: chai
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
```

The `test` runs *inside* the container on the `interval`; `pg_isready` is the tool Postgres ships for exactly this question — it exits `0` only when the server accepts connections. `retries` failures in a row flips the container to `unhealthy`; `start_period` is grace time at boot during which failures don't count against it. Watch it live:

```
$ docker compose ps
NAME            ...   STATUS
chai-20-db-1    ...   Up 4 seconds (health: starting)
$ docker compose ps
chai-20-db-1    ...   Up 11 seconds (healthy)
```

That `(healthy)` is new machine-readable truth: not "the process exists" but "the service answered its own readiness probe".

## Wiring order to readiness

Now `depends_on` can ask for more than start order, via its long form:

```yaml
  web:
    image: nginx:alpine
    depends_on:
      db:
        condition: service_healthy
```

With `condition: service_healthy`, Compose starts `db`, polls its health status, and only when it reports `healthy` does `web` get created and started. Run `docker compose up` on a stack like this and you can *see* the wait:

```
 ✔ Container chai-20-db-1   Healthy    10.7s
 ✔ Container chai-20-web-1  Started    11.0s
```

There are three conditions: **`service_started`** (the old short-form behavior), **`service_healthy`** (wait for the healthcheck), and **`service_completed_successfully`** (wait for a one-shot service — a migration container, say — to exit `0`). That third one quietly solves the "run migrations before the app" problem that teams bolt entire scripting frameworks onto.

:::notebook Where health actually lives
The healthcheck runs as a `docker exec` fired by the daemon on your interval; the result feeds a tiny state machine stored on the container itself — `docker inspect -f '{{.State.Health.Status}}' chai-20-db-1` shows `starting`, `healthy`, or `unhealthy`, and `.State.Health.Log` keeps the last few probe outputs, which is gold when a check misbehaves. Two sharp edges. First, the test runs *inside* the container, so the tool it calls must exist in the image — `pg_isready` ships with postgres, `curl` does not ship with most slim images (alpine-based ones have busybox `wget`). Second, an `unhealthy` container is *not* restarted by Docker — health is a signal, not an action. Compose reads the signal for `depends_on`; acting on it in production is Part 7 territory.
:::

## Belt, meet suspenders: restart policies

`depends_on` guards *startup* order. It does nothing later: if `db` crashes at 2 p.m., nobody stops or restarts `web` — dependency conditions are evaluated once, at `up`. For long-running resilience you add per-service **restart policies**, same semantics as the `--restart` flag:

```yaml
  db:
    restart: unless-stopped
```

`no` (default), `always`, `on-failure`, `unless-stopped` — the last is the sane production default: come back after crashes and daemon restarts, but stay down when a human deliberately stopped you. A well-written service also retries its own connections, because in real systems dependencies *will* blink. Healthchecks get you clean startups; retry loops keep you alive after them. You need both, and neither is a `sleep 10`.

:::notebook Why not just make the app wait?
You might object: shouldn't the app retry until the DB answers, making all this unnecessary? In an ideal world, yes — and good clients do. But you don't always own the code (third-party images), crash-looping on boot pollutes logs and monitoring, and "container is up but erroring" is much harder to alert on than "container never became healthy". The compose-level contract also *documents* the dependency graph: a new engineer reads `condition: service_healthy` and knows the topology without opening the source. Do both: readiness at the orchestration layer, retries in the application layer.
:::

The exercise stack is small — one database, one web front — but the pattern is the one you'll use on every real stack from here to the capstone: healthcheck on the dependency, `service_healthy` on the dependent.

Go make startup deterministic.
