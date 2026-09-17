# The Warehouse

Every image you've run so far — `hello-world`, `alpine`, `nginx` — came from somewhere. That somewhere is a **registry**: a warehouse of images that `docker pull` fetches from and (later, in Part 7) `docker push` ships to. Docker Hub is the default one, the way npmjs.com is npm's default. This chapter is about how you *refer* to things in that warehouse — because sloppy references are one of the most expensive habits in this industry, and almost everyone starts with one.

## Pulling, and what a tag really is

`docker run` pulls automatically, but you can pull explicitly and watch what arrives:

```
$ docker pull nginx:alpine
alpine: Pulling from library/nginx
9824c27679d3: Pull complete
6e102a3adf12: Pull complete
...
Digest: sha256:54f2a904c251d5a34adf545a72d32515a15e08418dae0266e23be2e18c66fefa
Status: Downloaded newer image for nginx:alpine
```

The full name of an image is `registry/repository:tag`. You usually type only a fragment and Docker fills in defaults: `nginx` means `docker.io/library/nginx:latest`. The part after the colon is the **tag** — and here's the thing nobody tells beginners: a tag is just a *sticker*. A movable, reusable, human-friendly label that the publisher can peel off one image and slap onto a completely different one tomorrow. `nginx:alpine` today and `nginx:alpine` next month are, more often than not, different images.

## `latest` is a lie

The tag `latest` is the worst offender, because it sounds like a promise and isn't one. Three things people believe about `latest`, all false:

- **"It's the newest version."** No — `latest` is only the default tag, the one used when a publisher pushes without naming a tag. Plenty of images have a `latest` that's *older* than their versioned tags.
- **"It updates itself."** No — `docker run` won't re-pull a tag you already have locally. Your `latest` is frozen at whatever it meant the day you pulled it.
- **"Everyone on the team has the same one."** No — each machine has whatever `latest` meant on *its* pull day. I've watched a team lose two days to a bug that only existed on one laptop, because that laptop had pulled `node:latest` a month before everyone else. "Works on my machine," image edition.

The fix is discipline, in increasing strength: use versioned tags (`nginx:1.25-alpine`) instead of floating ones — and when it truly must not move, pin the **digest**.

## Digests: the name that cannot lie

Look back at the pull output — that `Digest: sha256:...` line. A digest is the SHA-256 hash of the image's manifest: a fingerprint of the image's *content*. Two consequences:

- If the content changes in any way, the digest changes. A digest can't be re-pointed the way a tag can.
- You can pull and run by digest, skipping tags entirely:

```
$ docker pull nginx@sha256:516475cc129da42866742567714ddc681e5eed7b9ee0b9e9c015e464b4221a00
```

Tags are for humans; digests are for guarantees. Production systems, security audits, and reproducible builds pin by digest — you'll meet this again in Part 8, where an unpinned base image is an audit finding. To see the digests of what you have:

```
$ docker images --digests
REPOSITORY   TAG           DIGEST          IMAGE ID       SIZE
nginx        alpine        sha256:54f2a…   54f2a904c251   80.9MB
nginx        1.25-alpine   sha256:51647…   516475cc129d   77.5MB
```

Same repository, two tags, two different digests — two different images.

:::notebook What an image really is
There is no single "image file" in the warehouse. An image is three kinds of objects, linked by hashes:

- a **manifest** — a small JSON document listing, by digest, everything below;
- a **config blob** — JSON holding the metadata: default command, env vars, exposed ports, layer history;
- **layer blobs** — gzipped tarballs of filesystem changes (next chapter's whole subject).

`docker pull` fetches the manifest first, then downloads only the blobs it doesn't already have — that's why some `Pull complete` lines say `Already exists`. And the image's *digest* is simply the hash of the manifest: since the manifest names every blob by *its* hash, one top hash transitively fingerprints the entire image. This scheme is **content addressing** — the same idea as git commits: names derived from content, so identical content is stored once and nothing can be silently swapped.
:::

## Retagging: stickers are yours to place

`docker tag` puts a new sticker on an existing image:

```
$ docker tag nginx:1.25-alpine chai-04-api:pinned
```

Nothing is copied, built, or downloaded — this is instant. You now have two names for one image; `docker images` shows both with the *same* IMAGE ID. Teams retag constantly: pull a public image, retag it under the internal name; tag a tested build as `:staging`; promote the exact same image to `:prod` by adding a sticker, not rebuilding. The rule that makes this safe is the digest — however many stickers an image wears, its fingerprint never changes.

One caution while we're here: `docker rmi` with a tag only *peels that sticker off*. The image itself is deleted only when its last tag goes.

:::notebook Where "one image" becomes several
Pull `nginx:alpine` on your Mac and on an old Intel server and you get *different bytes* — arm64 in one place, amd64 in the other. The tag actually points at a **manifest list**: an index of per-architecture manifests, and the daemon picks the one matching its CPU. So even a digest-pinned reference can resolve to different blobs on different machines — the digest you pin is usually the *list's* digest, which covers all of them. You'll build one of these multi-arch lists yourself in Part 7.
:::

Time to work the warehouse: pull two variants, retag one, and write down a fingerprint the verifier can hold you to.
