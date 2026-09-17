# Secrets Are Not ENV

Since Chapter 10 you've been pushing configuration into containers with `-e` and `ENV`, and for configuration that's exactly right. Then one day the "configuration" is a database password or an API token, the same flag gets reused, and the audit lights up red. This chapter is about why environment variables are the wrong vehicle for secrets — provably, not as folklore — and what the right vehicles look like at build time and at run time.

## How env leaks

An environment variable feels private. It is anything but. Count the exits:

**Exit one: `docker inspect`.** Anyone who can talk to the Docker daemon can read every container's environment in plaintext:

```
$ docker run -d --name api -e DB_PASSWORD=chai$uper$ecret nginx:alpine
$ docker inspect -f '{{.Config.Env}}' api
[DB_PASSWORD=chai$uper$ecret PATH=/usr/local/sbin:...]
```

No privilege needed beyond daemon access — which, recall, is effectively root anyway. Your secret is now a `docker inspect` away for every person, script, and monitoring agent on the machine.

**Exit two: children.** Environment is *inherited*. Every process your app spawns — a shell for a quick `git` call, an ImageMagick resize, a curl — receives the entire environment, including secrets it has no business holding. A vulnerability in any of those inherits your database password.

**Exit three: logs and crash reports.** The oldest debugging move is dumping the environment; frameworks do it automatically when they crash. Error trackers famously scoop up `process.env` into their reports. The password ends up in a log file, then a log aggregator, then whoever can read dashboards.

**Exit four: the image itself.** The worst one. Bake a secret in at build time —

```dockerfile
ENV NPM_TOKEN=abc123          # forever
RUN echo "$SECRET" > /tmp/x   # in the layer, forever
ARG API_KEY                   # spoiler: also recorded
```

— and it's written into image metadata and layers, where **`docker history`** (Chapter 5) happily replays it:

```
$ docker history --no-trunc leaky:v1
... /bin/sh -c #(nop)  ENV NPM_TOKEN=abc123 ...
```

Push that image to a registry and you've published the secret to everyone who can pull. `ARG` is the trap that catches careful people: it feels build-scoped, but the value is recorded in the layer history all the same. Deleting the file in a later layer doesn't help either — layers are additive; the secret still sits in the earlier one.

## Build-time secrets, done right

The legitimate need is real: builds must authenticate — a private npm registry, a private Git dependency, an internal artifact server. BuildKit's answer is the **secret mount**:

```dockerfile
RUN --mount=type=secret,id=apitoken sh ./install-deps.sh
```

```
$ docker build --secret id=apitoken,src=token.txt -t api:v1 .
```

Two halves. The `--secret` flag names a secret (`id=apitoken`) and points at a file on your machine. The `--mount=type=secret` on a `RUN` instruction makes that secret appear — at **`/run/secrets/apitoken`**, by default — *for the duration of that one instruction only*. The next instruction can't see it. The finished image can't see it. It was never part of any layer, so `docker history` has nothing to replay and there's nothing to accidentally push.

:::notebook Where the secret lives during the build
BuildKit mounts the secret as a **tmpfs** — a RAM-backed filesystem — inside the build sandbox for exactly one `RUN` step, then tears it down. Contrast that with `COPY token.txt .`: COPY creates a layer, layers are content-addressed tar archives, and archives are forever. The secret mount sidesteps the layer system entirely, which is the whole trick — same reason the `--mount=type=cache` from Chapter 8 never bloats your image. The default path `/run/secrets/<id>` isn't arbitrary either: `/run` is conventionally tmpfs on Linux, and it's the same path Compose and Swarm use for runtime secrets, so tooling and habits transfer. One practical note: if the mounted secret is missing, the file simply isn't there — a well-written install script should check and fail loudly rather than build a half-configured image.
:::

## Run-time secrets, done right

At run time the same principle holds: **secrets travel as files, not as environment**. A file can be mounted read-only, has an owner and a mode, isn't inherited by child processes, doesn't appear in `docker inspect`, and doesn't get scooped into crash reports. The plainest form is a read-only bind mount into the conventional path:

```
$ docker run -d -v ./token.txt:/run/secrets/apitoken:ro api:v1
```

The app reads `/run/secrets/apitoken` at startup. In Compose this pattern is first-class — a `secrets:` block does exactly this mounting for you — and real secret managers (Vault, cloud secret stores) deliver to the same idea: a file or an in-memory API, never a `-e`.

The ecosystem even has a naming convention for the halfway world where an app *insists* on env config: the **`_FILE` suffix**. Official images like `postgres` accept `POSTGRES_PASSWORD_FILE=/run/secrets/db_pass` — the env var carries a *path* (harmless to leak), the file carries the value. When you write your own images, support the same convention and auditors will smile at you.

One honest caveat: a determined root user on the host can always extract a secret from a running container — read its memory if nothing else. Files-not-env isn't about making extraction impossible; it's about not *broadcasting* secrets through four wide-open exits to people and systems that were never even trying.

## This chapter's build

In `workspace/ch32` you'll find the ChaiCode API arranged as a working demo of both halves: `token.txt` (a stand-in for a real API token — in real life this file never enters git), `install-deps.sh` (simulates a private-registry install: it *dies* without the token, and records a **sha256 fingerprint** of the token it saw), and `server.js`, which reads its runtime secret from `/run/secrets/apitoken` and reports fingerprints — never values.

That fingerprint is the clever bit: it lets the verifier prove the secret *was* available during the build (the hash matches your `token.txt`) while simultaneously proving the token *value* is nowhere in the image. Cryptographic evidence, not vibes.

Build it so the token is used and never kept.
