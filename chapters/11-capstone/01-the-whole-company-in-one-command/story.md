# The Whole Company in One Command

Forty-four chapters ago you typed `docker run hello-world` and read the output like a foreign language. Today you're going to boot an entire company — web front door, API, relational database, cache, vector database — with one command, and every piece of it will be something you already know cold. This chapter adds no new flags and no new concepts. That's the point. A capstone isn't where you learn; it's where you find out that you already have.

Here's the platform you're assembling, and where each piece came from:

- **web** — nginx serving the static site *and* reverse-proxying `/api` to the API by its DNS name. One front door, exactly as Chapter 28 taught: app containers are never published directly.
- **api** — the ChaiCode API, a zero-dependency Node service. It gets built from a Dockerfile (Chapter 7), runs as a non-root user (Chapter 30), on a read-only root filesystem (Chapter 31), with a real healthcheck (Chapter 12).
- **db** — `postgres:16-alpine`, its data on a named volume so it survives anything short of `docker volume rm` (Chapter 13 — remember the night the demo database died?), seeded on first boot via `/docker-entrypoint-initdb.d`.
- **cache** — `redis:alpine`, healthchecked with a one-word conversation: `PING` → `PONG`.
- **qdrant** — the vector database from Chapter 36, because it's 2026 and the AI memory is part of the standard stack now.

And underneath them, the two-network layout from Chapter 18: a **frontend** network where only `web` and `api` live, and a **backend** network for `api`, `db`, `cache` and `qdrant`. The API is the only citizen of both worlds. The database is not on the frontend network, is not published to the host, and cannot be reached from anywhere except the API — not because a firewall says so, but because no wire exists.

## The scaffolding is ready — the architecture is yours

Look inside `workspace/ch45/`. The application code is written for you:

```
ch45/
├── api/          # Dockerfile + server.js (zero deps, stdlib only)
├── web/          # Dockerfile + nginx.conf + the static site
└── seed.sql      # menu data + a deploy_log table
```

What's *deliberately missing* is `compose.yaml`. That file — the services, the networks, the volumes, the health conditions, the startup ordering — is the exam. You've written every line of it before, just never all on the same page.

One design decision to know before you start: the API is **not** published on a host port. Port `8145` stays dark on purpose. The nginx config in `web/` already proxies `/api/` to `http://api:3000`, so the *only* way into the platform is `http://localhost:8045`, and the only reason that works is compose DNS (Chapter 17) resolving the name `api` on the frontend network.

The API's `/api/status` endpoint is worth reading in `server.js` — it doesn't *claim* its dependencies are fine, it proves it, on every request:

```
$ curl -s localhost:8045/api/status
{
  "service": "chaicode-api",
  "version": "1.0.0",
  "db": "connected",
  "cache": "connected",
  "qdrant": "connected"
}
```

The `db` check speaks the actual Postgres wire protocol — it opens a socket and sends a StartupMessage, no client library involved. The `cache` check sends a literal `PING\r\n` and reads `+PONG`. If you ever wondered what "connecting to the database" physically is, it's in that file, in eighty lines of stdlib.

:::notebook Liveness vs readiness — why the API has two endpoints
`/health` answers instantly and checks nothing but the process itself: *am I alive?* That's what the container healthcheck hits, because a healthcheck that interrogates the database punishes the API for the database's problems — a restart loop that fixes nothing. `/api/status` is the opposite: *am I actually useful right now?* It connects to every dependency on every call. Kubernetes formalizes this exact split as liveness and readiness probes, and you've now built both by hand — remember this paragraph when you get there.
:::

## Order matters, still

Five services, real dependencies. nginx resolves `api` at startup and exits if it can't; the API is pointless before Postgres accepts connections. This is Chapter 20's whole lesson in production form: `depends_on` with `condition: service_healthy`, driven by per-service healthchecks. Postgres brings `pg_isready`, redis brings `redis-cli ping`, your API image has busybox `wget` for its own `/health`. Qdrant's image ships no curl and no wget — bash's `/dev/tcp` trick works, or settle for `service_started`. Then one flag ties it together:

```
$ docker compose up -d --wait
 ✔ Network chai-45_frontend    Created
 ✔ Network chai-45_backend     Created
 ✔ Volume "chai-45-pgdata"     Created
 ✔ Container chai-45-db        Healthy
 ✔ Container chai-45-cache     Healthy
 ✔ Container chai-45-qdrant    Started
 ✔ Container chai-45-api       Healthy
 ✔ Container chai-45-web       Started
```

`--wait` doesn't return until every healthcheck is green — it's the difference between "I ran the command" and "the platform is up," and it's what you'd put in a deploy script.

:::notebook What compose actually did with your one command
No magic, just sequencing you could do by hand — and did, in Parts 5 and 6. Compose read the file, computed a dependency graph from `depends_on`, created two bridge networks (each with its own embedded DNS at `127.0.0.11`), created the named volumes, then started containers in topological order, gating each edge on the target's healthcheck. Every container got labels (`com.docker.compose.project=chai-45`, `...service=api`) — that's how `compose ps`, `compose down`, and this chapter's verifier find the pieces. The runtime underneath is the same `containerd` → `runc` chain from Chapter 1. Compose is an orchestrator of things you already know, which is also the honest one-line description of Kubernetes.
:::

Five services, two networks, two volumes, four healthchecks, zero unnecessary open ports. When the verifier goes green on this one, it's not checking a chapter — it's checking a book.

Time to write the file. All of it.
