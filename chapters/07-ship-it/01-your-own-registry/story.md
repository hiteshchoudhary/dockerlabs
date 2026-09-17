# Your Own Registry

Everything you've built so far lives in one place: your machine. `docker images` shows a nice collection, and exactly zero other computers can use any of it. Shipping software means moving images between machines, and the thing that moves them is a **registry** — a server that stores images and speaks a standard HTTP API for `push` and `pull`.

You've been using one since Chapter 1: Docker Hub is just the registry Docker points at by default. But Hub is somebody else's computer. Companies run their own — for speed, for privacy, for air-gapped servers that never touch the public internet. And here's the part most people don't realize: the registry itself is *just a container*. The reference implementation, `registry:2`, is a single image you can run anywhere. So before we push anything, let's own the whole pipeline.

```
$ docker run -d --name registry -p 5000:5000 registry:2
$ curl http://127.0.0.1:5000/v2/_catalog
{"repositories":[]}
```

That's a real, working image registry — empty, waiting, and entirely yours. The `/v2/` endpoints are the **Distribution API**, the same protocol Docker Hub, GitHub Container Registry, and AWS ECR all speak.

## Where an image's name really points

Time to be honest about image names, because until now we've been using the short form. A full image reference is:

```
[registry-host[:port]/]repository[:tag]
```

`nginx:alpine` is actually `docker.io/library/nginx:alpine` — the registry part was silently defaulted to Docker Hub. **The registry address lives inside the image name.** That's the whole routing system: there is no `--registry` flag on `docker push`, the name *is* the destination.

So to push to your own registry, you don't configure anything — you re-tag:

```
$ docker tag chai-24-api:1.0 127.0.0.1:8124/chai-24-api:1.0
$ docker push 127.0.0.1:8124/chai-24-api:1.0
```

`docker tag` doesn't copy a byte. It adds a second name to the same image — same ID, same layers, an alias. Cheap and instant. One image commonly wears several names: the local build name, the registry name, maybe two registries during a migration.

One convenience to know: registries normally require TLS, but Docker treats `127.0.0.1` and `localhost` as **insecure-allowed** by default — plain HTTP is fine for loopback. That's why a local lab registry needs zero certificate ceremony.

:::notebook What a registry actually stores
A registry is a **content-addressable blob store** with a thin naming layer on top. Every layer and every config file is stored as a blob named by the SHA-256 **digest** of its own bytes. A **manifest** — a small JSON document, also stored by digest — lists which blobs make up one image. A **tag** is the only mutable thing in the building: a named pointer to a manifest digest, exactly like a git branch pointing at a commit. `docker push` uploads only the blobs the registry doesn't already have (that's why pushing a rebuilt image with one changed layer is fast), then writes the manifest, then points the tag at it. When you pull "by digest" (`image@sha256:...`) you bypass tags entirely and get bit-for-bit reproducibility — no one can change what a digest means.
:::

## Tagging strategy: `latest` is not a strategy

The tag is the only mutable pointer in the system, which makes it the only place where discipline matters. I've watched teams lose entire weekends to this, so here is the strategy, condensed:

- **Semver tags for humans** — `1.0`, `1.4.2`. A human reading a deploy log should instantly know what shipped and how big the change was.
- **Git SHA tags for machines** — `a3f9c12`. CI builds one image per commit and tags it with the commit that produced it. Any running container can be traced back to the exact source tree in one lookup. Most teams push *both* tags to the same image (remember: tags are free aliases).
- **Digests for production pinning** — where it absolutely must not drift, reference `@sha256:...` directly.

And `latest`? It's not "the newest version" — it's merely the default tag name Docker uses when you don't type one. Nothing keeps it current, nothing defines what it means, and two machines that pulled `latest` a week apart are silently running different software while claiming the same name. The rule: **a tag you deploy from should never be reused for different bytes.** Build, tag immutably, push, and deploying becomes "run this exact artifact" instead of "run whatever the pointer means today." That idea — the immutable artifact — is the spine of this whole part, and Chapter 29 turns it into a deploy ritual.

## Talking to the registry directly

The Distribution API is plain HTTP, so `curl` is a perfectly good registry client:

```
$ curl http://127.0.0.1:8124/v2/_catalog
{"repositories":["chai-24-api"]}
$ curl http://127.0.0.1:8124/v2/chai-24-api/tags/list
{"name":"chai-24-api","tags":["1.0"]}
```

Those two endpoints answer the everyday questions — *what's in this registry, and which versions of this thing exist?* A third trick worth knowing: ask for a manifest with a `HEAD` request and the registry returns a `Docker-Content-Digest` header — the image's true, content-addressed identity. You'll use exactly that in the challenge to prove that what you pull is byte-identical to what you pushed.

:::notebook Where do the pushed images live?
Inside the registry container, under `/var/lib/registry` — blobs in a `blobs/sha256/` tree, tag pointers under `repositories/`. Run it as-is and a `docker rm` deletes your images along with the container; real deployments mount a volume there (Part 4 reflexes) or point the registry at S3-style object storage. For today's lab, ephemeral is fine — and if you `exec` in and poke around, you'll see the content-addressed store from the notebook above, live on disk.
:::

Your registry, your image, your names on everything. Let's ship the first artifact.
