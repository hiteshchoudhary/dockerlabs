# The 3 AM Deploy

It's 3 AM, production is broken, and version 2.0 — deployed six hours ago — is the suspect. What happens next depends entirely on a decision made long before tonight: are your deployments **mutable** or **immutable**?

The mutable shop SSHes into the server and starts *editing* — copying patched files into the running container, hot-fixing config, restarting processes inside it. Maybe it works. But that container is now a **snowflake**: its contents match no image in any registry, no commit in any repo. It can't be reproduced, can't be rolled back cleanly, and the next `docker rm` erases the only copy of tonight's fix. I've watched a team spend a week reverse-engineering what a 3 AM `docker cp` had changed, because the "fix" lived nowhere but inside one container on one machine.

The immutable shop types three boring commands and goes back to bed. This chapter makes you the second shop.

## Containers are cattle, images are truth

The whole discipline hangs on one rule: **a running container is disposable; the image is the unit of truth.** You never change a deployed container — you *replace* it with one made from a different image. Which means every deploy, upgrade, and rollback is the same four-step ritual:

```
pull → stop → rm → run
```

New version? Ritual, with the new tag. Rollback? *Same ritual, with the old tag.* There is no special rollback machinery — that symmetry is the superpower. And it only works because of what you built in this part: a registry holding every version (Chapter 24), tags that are never reused for different bytes (Chapter 24's other lesson), and containers that carry no precious state — data lives in volumes (Part 4), config comes from the environment or mounts, logs go to stdout (Chapter 27). A container that holds nothing unique is a container you can delete without a thought — *that* is what makes 3 AM boring.

The scaffold app makes versions visible: its Dockerfile takes a **build argument** and bakes it into the response —

```
FROM nginx:alpine
ARG APP_VERSION=dev
RUN echo "chai-29-app version ${APP_VERSION}" > /usr/share/nginx/html/index.html
```

`--build-arg APP_VERSION=1.0` at build time, and the running container answers `chai-29-app version 1.0` forever after. No environment variable to tweak at runtime, deliberately: the version is *in the artifact*, and the only way to serve different bytes is to build — and deploy — a different artifact.

## The release, then the deploy

Two builds, two pushes — the registry becomes your version history:

```
$ docker build --build-arg APP_VERSION=1.0 -t 127.0.0.1:8129/chai-29-app:1.0 ./ch29
$ docker push 127.0.0.1:8129/chai-29-app:1.0
$ docker build --build-arg APP_VERSION=2.0 -t 127.0.0.1:8129/chai-29-app:2.0 ./ch29
$ docker push 127.0.0.1:8129/chai-29-app:2.0
$ curl http://127.0.0.1:8129/v2/chai-29-app/tags/list
{"name":"chai-29-app","tags":["1.0","2.0"]}
```

In real life the two builds are two CI runs from two commits; on a lab machine, two `--build-arg`s stand in fine. Note what we did *not* build: `latest`. A deploy names its exact version or it isn't a deploy.

Version 1.0 goes live:

```
$ docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0
$ curl http://127.0.0.1:8029/
chai-29-app version 1.0
```

Then 2.0 ships, by ritual:

```
$ docker pull 127.0.0.1:8129/chai-29-app:2.0     # fetch BEFORE touching prod
$ docker stop chai-29-app
$ docker rm chai-29-app
$ docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:2.0
$ curl http://127.0.0.1:8029/
chai-29-app version 2.0
```

The `pull` comes first for a reason: it's the only slow, failure-prone step (network, disk, a typo'd tag), and it doesn't touch the running service. Do it while v1 is still serving and your worst case is "the upgrade didn't start" — never "the app is down and the new image won't come." With the image already local, the stop→rm→run gap is under a second. (For zero seconds, you'd start v2 *alongside* v1 and flip a reverse proxy between them — blue-green, and you built the proxy for it in Chapter 28. Same principle, two doors.)

And when 2.0 turns out to be the 3 AM suspect: same ritual, old tag, done. Verify with `curl` and `docker inspect -f '{{.Config.Image}}' chai-29-app` — the tag in the config and the marker in the response should *always* agree. When they don't, someone mutated a container, and you're back in snowflake country.

:::notebook Why not docker cp the fix in?
Mechanically, `docker cp app.js chai-29-app:/app/` into a running container works — that's what makes it dangerous. Three things are now true: **the container lies** (`inspect` says `:2.0`, but it isn't 2.0 anymore — monitoring, teammates, and tomorrow-you all deceived); **the fix is mortal** (it lives in the container's writable layer — Chapter 2 territory — and dies with the container; the next restart-from-image silently *un*fixes production); and **the fleet forks** (with three replicas, you just patched one — now you have two versions in production simultaneously, which no dashboard on earth will explain). `docker cp` *out* of containers is great debugging (Chapter 3). Copying *in* is for experiments on your laptop — never for anything that must stay fixed. The honest path is embarrassingly close: edit source, build `:2.1`, push, ritual.
:::

:::notebook What "rollback" really rolls back
Rolling back the *code* is trivial — that's the ritual. What the ritual can't roll back is **state**: if 2.0 wrote new-format rows into a Part 4 volume or migrated a database schema, 1.0 may face data it never understood. That's why careful teams ship schema changes that both versions can live with (expand first, contract later), and why "roll forward" — a quick 2.1 with the fix — is sometimes safer than rolling back. The deploy mechanics you're practicing are the easy 90%; knowing where the other 10% hides is what the pager teaches.
:::

Registry, two versions, one ritual practiced in both directions — that's tonight's drill. Ship it, break a sweat upgrading it, then roll it back like it's nothing.
