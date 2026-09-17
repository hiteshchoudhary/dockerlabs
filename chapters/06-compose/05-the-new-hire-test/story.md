# The New-Hire Test

There's a benchmark I hold every team to, and I stole it from the best onboarding I ever saw: **a new hire, on a clean laptop, should have the entire platform running before their first chai goes cold.** Clone, one command, working stack. No wiki archaeology, no "ask Priya about the database password", no six-step README that was accurate two quarters ago. Five minutes, most of it download time.

That benchmark isn't about being nice to new hires (though it is). It's a forcing function: if a stranger can boot your platform blind, then your CI can, a fresh server can, and *you* can at 3 a.m. during an incident. The compose file becomes the single, executable source of truth for what your system *is* — and this chapter is where everything Part 6 taught you assembles into one.

## The shape of the full stack

Four services, and every line of this is a chapter you've already done:

```yaml
name: chai-23

services:
  web:        # nginx, static front — the only door for humans
  api:        # built from ./api — the only door for code
  db:         # postgres + named volume — state that survives
  cache:      # redis — fast and forgettable
```

The wiring rules come straight from Part 5 and Chapter 20, now stated as policy:

- **Publish only the front doors.** `web` gets `8023`, `api` gets `8123`. The database and cache get *no* `ports:` at all — they're reachable as `db:5432` and `cache:6379` on the project network, by every service and by nobody outside the machine. The verifier for this chapter actively checks that you *didn't* publish them; in Part 8 you'll meet the auditors who check it for a living.
- **Healthchecks on everything.** Not just the database this time. `pg_isready` for postgres, `redis-cli ping` for redis, and HTTP probes for your own services — nginx and the API both answer HTTP, so busybox `wget` (already inside every alpine-based image) is the probe:

```yaml
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:3000/health || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s
```

- **Dependencies wait for health, not for start.** The API needs both stateful services genuinely ready:

```yaml
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
```

- **State gets a named volume.** `pgdata:` declared at the top level, mounted at `/var/lib/postgresql/data` — Chapter 13's incident, permanently prevented. `docker compose down` leaves it; only `down -v` destroys it, deliberately.

The scaffolded API is worth a glance (`workspace/ch23/api/server.js`): it answers `/health` for its own probe, and on `/` it reports live TCP reachability of `db` and `cache` *by service name* — your Part 5 DNS knowledge, observable over HTTP.

## The one command

```
$ docker compose up -d --wait
 ✔ Network chai-23_default    Created
 ✔ Volume "chai-23_pgdata"    Created
 ✔ Container chai-23-db-1     Healthy
 ✔ Container chai-23-cache-1  Healthy
 ✔ Container chai-23-api-1    Healthy
 ✔ Container chai-23-web-1    Healthy
```

Read the order Compose chose: stateful services first, then the API the moment both report healthy, then the front. You declared a *graph*, and Compose walked it. The **`--wait`** flag is the production-grade detail: plain `up -d` returns once containers are *started*; `--wait` blocks until every service is *healthy* (or running, if it has no healthcheck) and exits non-zero otherwise. That one flag is the difference between a CI pipeline that tests a booted platform and one that races it.

```
$ curl -s http://localhost:8123/
{"service":"chaicode-api","db":"up","cache":"up"}
```

The new-hire test, passed by a machine.

:::notebook What `up` actually does with the graph
Compose builds a directed graph from `depends_on` and walks it in topological order — independent branches (`db`, `cache`) start *concurrently*, not sequentially, which is why big stacks don't boot in sum-of-parts time. Each `service_healthy` edge subscribes to the health state machine you met in Chapter 20; the dependent's create-and-start is simply deferred until the event fires. Everything else you've seen all book still applies underneath: it's ordinary containers, one bridge network, labels holding the project together. There is no orchestration magic to outgrow — which is exactly why these same YAML concepts carry almost unchanged into Kubernetes when a single machine stops being enough.
:::

:::notebook Compose in production — the honest answer
Can you *run* production on Compose? On a single server, plenty of teams do, happily: `restart: unless-stopped`, healthchecks, named volumes, a reverse proxy in front (Chapter 28), backups (Chapter 15) — that's a respectable small-scale deployment. What Compose deliberately doesn't do: spread services across multiple machines, self-heal a dead host, or roll updates with zero downtime. When those become real requirements, that's Kubernetes territory — a different lab. The skill that transfers completely is the one you just used: declaring a service graph with health semantics.
:::

One more habit before the exercise, because the payoff deserves it: after your stack is green, run `docker compose down` and then `up -d --wait` again, and time it. That full teardown-and-rebirth — the thing that used to be a wiki page and an afternoon — is now an idempotent command pair. *That* is what you're actually shipping to your team when you commit this file.

Now boot the whole company.
