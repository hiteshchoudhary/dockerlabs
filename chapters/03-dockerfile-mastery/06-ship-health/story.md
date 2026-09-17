# Ship Health

A container's status says `Up 4 hours`. The process is alive, PID 1 is humming — and the app inside stopped answering requests three hours ago. "Running" and "working" are different claims, and so far everything we've built only proves the first. This chapter closes Part 3 by making images that *testify about themselves*: a built-in health probe, and labels that say what the thing is and where it came from. The difference between an image that runs and an image you'd ship.

## HEALTHCHECK: teach the image to take its own pulse

**`HEALTHCHECK`** bakes a periodic self-test into the image. The daemon runs your test command *inside* the container on a schedule; pass means healthy, fail (repeatedly) means unhealthy:

```dockerfile
HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
```

Reading the knobs: every 5 seconds (`--interval`), run the command; give it 3 seconds to answer (`--timeout`); flip to `unhealthy` only after 3 consecutive failures (`--retries`) — one slow garbage-collection pause shouldn't page anyone. There's also `--start-period` to hold fire while a slow app boots. Defaults are production-flavored (30s interval); in this lab we use fast timings so you can *watch* the state machine move.

The exit code is the whole protocol: `0` healthy, `1` unhealthy. The command runs inside the container, so it must exist in the image — Alpine-based images have busybox's `wget`; images with Node but no wget can use `node -e` with `fetch`; and on `scratch` (Chapter 11) there's nothing to run a check *with*, which is one reason health checks usually live in richer bases or move up to the orchestrator.

Once an image has a health check, its containers carry a third answer beyond running/exited. `docker ps` shows it inline — `Up 10 seconds (health: starting)` → `Up 30 seconds (healthy)` — and inspect exposes the state machine directly:

```
$ docker inspect -f '{{.State.Health.Status}}' chai-12-api
healthy
```

What should the check actually test? The endpoint it hits matters more than the plumbing. A good `/health` answers cheaply but honestly — the ChaiCode API in `workspace/ch12/app/` now ships one, and it can even be made to lie sick on command (`FAIL_HEALTH=1`), which is exactly how you'll rehearse a failure in the challenge. The app keeps serving; only its pulse goes bad — the sneakiest kind of production incident, now reproducible on your laptop.

:::notebook What the daemon does with your pulse — and what it doesn't
Each probe is essentially a `docker exec`: the daemon spawns your test command inside the container's namespaces, collects exit code and output, and keeps the last five results in `.State.Health.Log` (gold for debugging: `docker inspect` shows what the failing probe actually printed). After `--retries` consecutive failures, the daemon flips `.State.Health.Status` and emits an `unhealthy` **event** — `docker events` streams it live.

Here's the part that surprises everyone: **plain Docker takes no action.** An unhealthy container is not restarted, not stopped — restart policies (Part 7) react to *exit*, not to health. HEALTHCHECK is a sensor, not an actuator. The actuators come later: Compose gates dependencies on it (`condition: service_healthy` — Part 6's "Order Matters" leans on today's work), Swarm/Kubernetes replace unhealthy replicas, load balancers pull them from rotation. No sensor, no actuator — which is why an image without a health check is, to an orchestrator, a black box that's always "fine".
:::

## Labels: the shipping manifest

You've met labels twice (Chapters 7 and 10); now the full discipline. The **OCI image annotations** are the standard key set every registry, scanner, and supply-chain tool understands:

```dockerfile
LABEL org.opencontainers.image.title="chai-12-api" \
      org.opencontainers.image.description="ChaiCode API with a built-in health probe" \
      org.opencontainers.image.authors="you@chaicode.com"
```

There are more — `.source` (repo URL), `.version`, `.revision` (the git SHA you stamped via `ARG` in Chapter 10), `.licenses` — and the payoff compounds with fleet size: two years from now, `docker image inspect` on a mystery image answers *what is this, whose is it, which commit built it* in one command. Unlabeled images become archaeology.

## Borrow taste: `docker init` and the linting mindset

Everything this Part taught by hand, Docker can now scaffold: run **`docker init`** in a project and it interviews you (language? version? port?) and generates a `Dockerfile`, `.dockerignore`, and `compose.yaml` following current best practice — deps-first ordering, multi-stage where sensible, non-root user, health check included. Genuinely good output, worth running on your next fresh project. The reason this book made you write everything manually first: generated files are a *starting point*, and you can now review one line by line instead of cargo-culting it. Same mindset for linters — **hadolint** reviews Dockerfiles like a strict senior engineer ("pin that version", "consolidate those RUNs"), and Docker Desktop's **Docker Scout** flags vulnerable bases. Cheap tools, expensive mistakes avoided.

One exercise stands between you and a completed Part 3: ship the ChaiCode API with a pulse and a manifest, then deliberately poison one and watch `docker ps` tell on it.
