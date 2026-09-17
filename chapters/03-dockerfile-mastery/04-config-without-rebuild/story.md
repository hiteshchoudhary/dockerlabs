# Config Without Rebuild

Here's a deployment smell you'll meet in the wild: a team with `api-demo.dockerfile`, `api-staging.dockerfile`, and `api-prod.dockerfile`, three near-identical images rebuilt for every release, drifting apart one hotfix at a time. When the investor demo works and production doesn't, nobody can say why — they're not running the same artifact.

The fix is a principle worth tattooing somewhere visible: **build once, configure at runtime**. One image, promoted unchanged from laptop to demo to prod; everything environment-specific — mode flags, database URLs, log levels — arrives from *outside* the image when the container starts. This is factor III of the twelve-factor app methodology, and Docker gives you exactly two knobs for it. They look like twins. They live on opposite sides of the build/run divide.

## ENV: runtime configuration with defaults

**`ENV`** sets an environment variable that exists *in the image* — every `RUN` step after it sees it during the build, and every container started from the image inherits it at runtime:

```dockerfile
ENV MODE=demo
```

The app just reads `process.env.MODE` (or `os.environ`, or `os.Getenv` — the pattern is language-agnostic, which is precisely its charm: the same mechanism configures your Node API and the Postgres image next to it).

The power move is that `ENV` is only a *default*. At `docker run` time, `-e` overrides it, no rebuild anywhere:

```
$ docker run -e MODE=prod my-api            # override
$ docker run --env-file ./prod.env my-api   # a file full of overrides (Part 6 territory)
```

You've been using this all along without ceremony — `POSTGRES_PASSWORD`, `NODE_ENV` — every well-built image on Docker Hub is a menu of documented `ENV` knobs.

## ARG: build-time only, then gone

**`ARG`** declares a variable that exists *only while the image is being built*:

```dockerfile
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine
```

You feed it with `docker build --build-arg NODE_VERSION=23 ...`, it steers the build — picking a base version, passing a private registry mirror, stamping a build ID — and then it **evaporates**. It is not in the final config, not in the container's environment, invisible to your app at runtime. (Not *cryptographically* gone, mind — `docker history` can show the values `ARG`s took, so they're for build *parameters*, never for passwords. Real build secrets use the `--mount=type=secret` you glimpsed in Chapter 8.)

The two-line summary your future self will thank you for:

| | `ARG` | `ENV` |
|---|---|---|
| Exists during | `docker build` only | build **and** every container |
| Set from outside by | `--build-arg` | `-e` / `--env-file` |
| App can read it at runtime | no | yes |
| Good for | base versions, build stamps | mode flags, URLs, tunables |

The classic combo is an `ARG` *promoted into metadata*: a CI pipeline passes `--build-arg GIT_SHA=$(git rev-parse HEAD)`, and the Dockerfile bakes it into a `LABEL` — so every image carries a permanent, inspectable record of exactly which commit built it, without polluting the runtime environment. That's your challenge today.

## One image, two personalities

In `workspace/ch10/app/` the ChaiCode API has learned to read `MODE` from its environment and change behavior accordingly — verbose demo answers versus terse prod ones. Your job: **one** build, two containers with different personalities, and not a byte of difference between what they run.

```
$ curl -s localhost:8010    # the demo one
{"service":"chaicode-api","mode":"demo","message":"Demo mode: sample data, ..."}
$ curl -s localhost:8110    # the prod one — same image
{"service":"chaicode-api","mode":"prod","message":"Prod mode: real data, ..."}
```

When this clicks, "how do we deploy to staging?" stops being a build question at all.

:::notebook Where an env var actually lives
`-e MODE=prod` doesn't inject anything magical — it lands in the container's config (`docker inspect -f '{{.Config.Env}}'` shows the merged result: image `ENV` defaults plus your overrides, last write wins), and when runc starts PID 1 it simply passes that list as the process's environment, the same `envp` every Unix process gets. Children inherit it; that's the whole mechanism.

Two consequences. First, *anyone who can inspect the container reads every value* — and most log aggregators happily print environments in crash dumps. Fine for `MODE=prod`; a career-limiting place for database passwords, which is why Part 8 exists (mounted secret files, not env). Second, the environment is fixed at `docker run`: you can't change a running container's env — you stop it and start a new one with different flags. That's not a limitation, that's the model: containers are cheap; *reconfiguration is replacement.*
:::

:::notebook ARG scope has sharp edges
Two gotchas that cost real debugging hours. An `ARG` declared *before* `FROM` is only in scope for the `FROM` line itself — to use it after, re-declare it (a bare `ARG NODE_VERSION` inside the stage). And changing an `ARG`'s value busts the build cache from the first instruction that *consumes* it — which is why build stamps belong near the *bottom* of the Dockerfile, next to the `LABEL` they feed: stamp every build with a fresh ID and you'll still get cache hits on everything above it.
:::

The app's in `workspace/ch10/app/`, already env-aware. Build once; run twice.
