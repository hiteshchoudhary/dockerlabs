# Layers

Last chapter I told you an image's blobs are "tarballs of filesystem changes" and moved on. That sentence is the entire economics of Docker — disk, bandwidth, and build speed all hang off it — so this chapter we slow down and look properly. An image is not one big filesystem snapshot. It's a **stack of layers**, each recording only what *changed* relative to the one below.

## Reading the stack: `docker history`

Every image will tell you its own construction story:

```
$ docker history nginx:alpine
IMAGE          CREATED       CREATED BY                                   SIZE
54f2a904c251   3 weeks ago   CMD ["nginx" "-g" "daemon off;"]             0B
<missing>      3 weeks ago   ENTRYPOINT ["/docker-entrypoint.sh"]         0B
<missing>      3 weeks ago   COPY docker-entrypoint.sh / # buildkit       4.62kB
<missing>      3 weeks ago   RUN /bin/sh -c set -x && apkArch=…           4.5MB
<missing>      3 weeks ago   ADD alpine-minirootfs-…tar.gz / # buildkit   8.3MB
```

Read it bottom-up: a base Alpine filesystem, then a layer that installed nginx, then a copied script, then a couple of zero-byte metadata entries (`CMD`, `ENTRYPOINT` change *configuration*, not files — no layer needed). Each row with a SIZE is one of those content-addressed blobs from Chapter 4.

## Why layers, and why order matters

Layers exist for one reason: **reuse**. Every layer is named by the hash of its content, so when two images are built on the same base, that base is stored once on disk and downloaded once over the network. Pull ten different images that all start from `alpine` and you fetch the Alpine layer a single time — that's the `Already exists` you see during pulls. On a real machine running fifty containers from a dozen images, layer sharing is routinely the difference between 5 GB and 50 GB.

The catch: a layer can only be reused if *everything below it* is identical — a layer's meaning depends on the stack under it, so change one layer and every layer above it must be rebuilt and re-shipped. That's why ordering matters, and it becomes the core skill of Part 3: stable things (OS packages, dependencies) go low in the stack, volatile things (your code) go high. Get it backwards and every one-line code change invalidates the dependency layer above nothing — I've seen CI bills halved by reordering five lines of a Dockerfile.

## Layers meet containers: copy-on-write

Here's the puzzle: layers are **immutable** — they're content-addressed, so they can't change — yet inside a container you can write files anywhere. How?

When a container starts, Docker stacks the image's read-only layers and adds one fresh, empty, **writable layer** on top — the *container layer*. Every write lands there; the image below is never touched. Fifty containers from one image share every image layer and differ only in their thin writable layers on top. And when a container is removed, its writable layer is deleted with it — which Part 4 will teach you the hard way.

:::notebook OverlayFS — the trick under the stack
The stacking is done by **OverlayFS**, a Linux filesystem that presents several directories as one. Docker gives it the image layers as read-only **lowerdir**s, the container's writable layer as **upperdir**, and mounts the combined view as **merged** — the `/` your container sees. The rules:

- **Read** a file → served from the topmost layer that has it.
- **Write** a file that lives in a lower layer → the kernel first copies it up to the upperdir, then modifies the copy. This is **copy-on-write**: the lower layer keeps the original, the upper layer holds the container's version, and readers see the top one.
- **Delete** a lower-layer file → can't be done, so OverlayFS fakes it with a *whiteout* marker in the upperdir that hides the file below. This has a famous consequence: a `RUN rm` in a later layer hides a file but never reclaims its space — the bytes still ship in the lower blob. Secrets "deleted" this way are still in the image; Part 8 makes hay of that.

Copy-on-write is why containers start in milliseconds: "creating" a container's filesystem is just creating one empty directory and a mount.
:::

## The `docker commit` trap

So a running container's writable layer holds everything you've changed. Docker will happily freeze that layer into a new image:

```
$ docker commit chai-05-lab chai-05-snapshot:v1
sha256:a5c422ea8141...
```

The result is real — the base image's layers plus one new layer holding your manual edits, runnable like any other image. You're going to do this exactly once in this book, in the exercise below, because feeling it teaches the layer model better than any diagram. And then never again. Here's why every experienced team bans it:

- **Nobody knows what's inside.** `docker history` on a committed image shows one opaque layer. What got installed? Edited? Left behind in `/root/.bash_history`? No record.
- **It isn't reproducible.** The image exists; the *recipe* doesn't. When it needs rebuilding — new base image, security patch — someone gets to reverse-engineer it.
- **It captures garbage.** The whole writable layer comes along: temp files, caches, that `.deleted` secret from the notebook above.

A committed image is a binary with no source code. The civilized alternative — a written, versioned, repeatable recipe called a **Dockerfile** — is where Part 3 begins, and after this exercise you'll know exactly what problem it solves.

:::notebook Where the layers live on disk
On Linux, look under `/var/lib/docker/` — with the containerd image store, each layer blob sits in the content store and gets an unpacked "snapshot" directory that OverlayFS mounts from. On Docker Desktop (your Mac), all of this lives inside the Desktop's Linux VM, which is why you won't find these paths in Finder. Same mechanics, one VM removed. The verifiable part from the outside: `docker image inspect -f '{{json .RootFS.Layers}}'` lists an image's layer digests — two images sharing a digest there are sharing bytes on disk. Your challenge uses exactly this.
:::

Time to fall into the trap deliberately: build an image by hand, inspect the scar it leaves, and prove the sharing.
