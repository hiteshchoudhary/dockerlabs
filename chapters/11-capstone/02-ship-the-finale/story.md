# Ship the Finale

Chapter 45 left you with a running platform. There's one honest test left, and it's the same question this book opened with, pointed the other way: forget "works on my machine" — does it work on a machine that has *nothing of yours on it*? A machine with no source code, no build cache, no `workspace/ch45/` — just Docker and a network connection. That's what shipping means, and everything you need for it you already built in Chapter 24: a registry.

## Images are the deliverable

The compose file you wrote in Chapter 45 has two `build:` keys in it. That's a development file — it assumes the source tree sits next to it. Sharma Institute's server doesn't have your source tree, and shouldn't: what you ship is the **image**, the frozen artifact from Chapter 4, not the recipe. So the finale is a supply chain in miniature:

1. Build and tag the platform's images properly.
2. Push them to a registry.
3. Prove the point: delete every local copy, then boot the whole platform from registry pulls alone.

For the registry we stay offline-friendly, exactly like Chapter 24: `registry:2`, running as a container, published on port `8146`. Pushing to Docker Hub is the same motion with a different hostname and a `docker login`.

## Tags that mean something

You've known since Chapter 4 that `latest` is a lie — it's just a default string, it doesn't mean newest, and it tells an operator nothing. Nobody who survived Chapter 29's 3 AM deploy ships `latest`. So the finale uses **semver**: the api ships as `127.0.0.1:8146/chai-46-api:1.0.0`. Read the full reference right to left, because every part earns its place:

```
127.0.0.1:8146 / chai-46-api : 1.0.0
└── registry ──┘ └── repo ──┘ └─ tag ─┘
```

The registry host is *part of the image name* — that's how `docker push` knows where to send it, no flag needed. And when someone reports a bug, "which version?" has an answer that `latest` could never give. A `docker tag` costs nothing (it's a new name for the same content-addressed layers), so cutting `1.0.0` from your existing build is instant.

:::notebook What a registry actually stores
A registry is a content-addressed blob store with a tiny HTTP API on top. Push an image and Docker uploads its **layers** as blobs (each named by the sha256 of its content), the **config** blob, and finally a **manifest** — the small JSON that ties them together. The tag is just a mutable pointer to a manifest digest; that's the entire mechanics of "retagging costs nothing" and also of Chapter 44's build-once-promote-the-digest pattern. It's why your second push finishes in a second — every blob already exists, so the registry answers "already have it" layer by layer. You can talk to the API yourself: `curl 127.0.0.1:8146/v2/_catalog` lists repos, `/v2/chai-46-api/tags/list` lists tags. (And yes, plain HTTP: Docker requires TLS for every registry host *except* localhost — that carve-out is what makes local registries painless.)
:::

## The fresh-machine proof

Here's the part that separates believing from knowing. After pushing, you'll run:

```
$ docker compose -p chai-45 down          # keep the volumes — data is not code
$ docker rmi chai-45-api chai-45-web 127.0.0.1:8146/chai-46-api:1.0.0 ...
```

Every local copy of the platform's custom images: gone. Your laptop is now, imagewise, the fresh machine. Then a new compose file — a **deploy file**, with `image:` keys where the `build:` keys used to be and not a single bind-mounted line of code — brings the whole company back:

```
$ docker compose -f compose.registry.yaml up -d --wait
 ✔ api Pulled
 ✔ web Pulled
 ...
 ✔ Container chai-45-api  Healthy
```

Watch for the word **Pulled**. The images crossed the wire from the registry, layer by layer, exactly as they would onto any server on earth. Note what *didn't* move: `chai-45-pgdata` was never deleted, so the data — including your Challenge marker from Chapter 45 — is waiting when the pulled containers attach to it. Code travels in images; state lives in volumes. That one sentence is most of production operations.

## What you can now do

Take stock, without ceremony, of what this book leaves in your hands. You can package any application with its entire environment and prove it identical everywhere (Parts 1–3). You can keep state alive through any teardown, and back it up (Part 4). You can wire services into segmented private networks where the database physically cannot be reached from outside (Part 5), boot the whole arrangement with one command (Part 6), and ship it through registries with tags an operator can trust (Part 7). You can harden all of it until a security checklist goes green (Part 8), run models and vector stores next to your app and sandbox untrusted code (Part 9), and give every human and AI teammate the same dev environment (Part 10). Chapter 1 you: staring at `docker version`. This chapter you: shipping a five-service platform to a bare machine, versioned, healthchecked, and verified.

Where next? Notice what compose *doesn't* do: it runs one machine. It won't spread your services across three servers, reschedule a container when a machine dies, or roll out `1.0.1` gradually across ten replicas. The tool for that is **Kubernetes** — and here's the thing you're now positioned to appreciate: Kubernetes runs *these exact images*. Registries, healthchecks (it calls them probes), non-root policies, segmented networks, liveness vs readiness, labels — you've hand-built every concept it automates. That's the next lab. Bring your images.

One last push first.
