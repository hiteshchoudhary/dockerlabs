# Builds at Scale

`docker build -t app .` was fine when you had one image. Real platforms don't have one image — they have an API, a worker, a frontend, a migrations job, each × arm64 and amd64, each needing the same labels, the same build args, the same base versions. The shell-script answer (`build && build && build`) rots fast: flags drift apart, someone updates one Dockerfile's version label and forgets the other three, and CI takes forever because everything builds serially. The 2026 answer is to treat the *build itself* as declared configuration: **`docker buildx bake`**.

## The bake file

Bake reads a file — HCL by convention (`docker-bake.hcl`), JSON or even your existing `compose.yaml` work too — describing **targets** (each one a build) and **groups** (named sets of targets):

```hcl
group "default" {
  targets = ["api", "worker"]
}

target "api" {
  context    = "."
  dockerfile = "Dockerfile.api"
  tags       = ["chai-44-api:v1"]
  args       = { APP_VERSION = "v1" }
  labels     = { "com.chaicode.project" = "chai-44" }
}

target "worker" {
  context    = "."
  dockerfile = "Dockerfile.worker"
  tags       = ["chai-44-worker:v1"]
  args       = { APP_VERSION = "v1" }
  labels     = { "com.chaicode.project" = "chai-44" }
}
```

Every key maps to a `docker build` flag you already know: `context` is the build's path argument, `dockerfile` is `-f`, `tags` is `-t`, `args` is `--build-arg`, `labels` is `--label`; `platforms` (Part 7's multi-arch) fits right in. Then one command builds the world:

```
$ docker buildx bake                # builds the "default" group — in PARALLEL
$ docker buildx bake api            # or just one target
$ docker buildx bake --print        # dry-run: show the fully-resolved plan as JSON
```

`--print` deserves a habit: it resolves inheritance, variables, and defaults into the exact JSON plan BuildKit will execute — your bake file's equivalent of `docker compose config`. CI systems lint bake files with it; so does this chapter's verifier.

:::notebook Why bake is fast: one graph, not N commands
Sequential `docker build` calls can't share work within a run. Bake hands *all* targets to BuildKit as a **single build graph**, and BuildKit — a dependency solver at heart — walks the whole graph concurrently: independent targets build in parallel, and identical subtrees (same base image, same `COPY package.json` + `RUN npm ci` prefix) are **deduplicated and built once**, even when they appear in five Dockerfiles. This is the same engine that runs your multi-stage builds; bake just widens the graph from one image to the whole platform. Compose users get a taste for free: `docker compose build` accepts bake as its backend.
:::

Repetition in a bake file has a cure, too — targets **inherit**. Shared settings live once in a base target; real targets pull them in with `inherits` and add their specifics. (A target can also declare a **matrix** — one definition stamped out across a list of values, e.g. multiple base versions.) That refactor is your Challenge. There are also two magic inheritable names: variables (`variable "TAG" { default = "v1" }`) referenced as `${TAG}`, overridable from the environment at bake time — your one lever for "same file, different release".

## Caching: the difference between 40 minutes and 4

Part 3 taught you layer caching on one machine. CI runners are *fresh* machines — no cache, every build from zero. BuildKit fixes this by making cache **exportable and importable**:

```
$ docker buildx build \
    --cache-to   type=registry,ref=registry.example.com/app:buildcache,mode=max \
    --cache-from type=registry,ref=registry.example.com/app:buildcache \
    -t app:ci .
```

`--cache-to` pushes the build's layer cache somewhere durable (a registry, or `type=gha` for GitHub Actions' cache service); `--cache-from` lets the next run — on a *different* machine — start warm. `mode=max` caches intermediate stages too, not just final layers; for multi-stage builds that's where the treasure is. In a bake file these are just `cache-to`/`cache-from` keys per target, shared via inheritance like everything else.

## The CI pattern: build once, promote the digest

Now the discipline that ties Part 7 and Part 8 together. The cardinal sin of CI/CD is building the "same" image twice — once for staging, again for production. Two builds are never provably identical (base images move, package registries move). The professional pattern:

1. **Build once**, in CI, push, and record the **digest** — the immutable `sha256:...` content address (Part 2), not the movable tag.
2. **Test that digest** in staging.
3. **Promote the digest** to production — deploy `app@sha256:...` verbatim. No rebuild. Optionally re-tag it (`app:prod`), but the deploy pins the digest.

The bits that survived testing are — bit for bit — the bits that ship. Signing and provenance attestations from Part 8 ride along, because the digest they signed never changed. A GitHub Actions sketch of the whole shape:

```yaml
jobs:
  build:
    steps:
      - uses: docker/setup-buildx-action@v3
      - uses: docker/bake-action@v6        # runs your docker-bake.hcl
        with: { push: true }
        # cache-to/cache-from: type=gha in the bake file
      # capture the pushed digest -> pass to the deploy job, promote as-is
```

One paragraph on **Docker Build Cloud**, because you'll meet it: Docker's hosted BuildKit builders. Your `docker buildx bake` runs unchanged, but the graph executes on beefy cloud machines with a **persistent shared cache** — every teammate and every CI job starts warm from everyone else's builds, and native arm64+amd64 builders replace slow QEMU emulation for multi-arch. Same files, same commands, rented muscle: `docker buildx create --driver cloud` and you're on it.

:::notebook Tags move, digests don't
A tag is a mutable pointer — `:v1` can point at different bytes tomorrow, and `:latest` does so habitually. A digest is the SHA-256 of the manifest itself: `app@sha256:...` can only ever mean one exact image, forever. That asymmetry is the entire theory of promotion pipelines — and of supply-chain security. Humans read tags; deploy systems should trust digests. After a bake, `docker buildx bake --print` plus `docker image inspect -f '{{index .RepoDigests 0}}'` tells you exactly what to promote.
:::

Your turn: declare the two-image build for this chapter's little platform, bake it in one shot, then refactor the duplication away with inheritance.
