# The Incident

Every team has one. Ours went like this: a demo Postgres had been running in a container for three weeks — seeded by hand, tweaked before every client call, never written down. The night before the biggest demo of the quarter, someone tidied up disk space with `docker rm -f $(docker ps -aq)`. The container died in forty milliseconds. So did every row in the database. There was no backup, because "it's just Docker, the data's in there somewhere, right?"

It wasn't. And understanding *why* it wasn't is the single most important thing in this part of the book.

## The writable layer is not storage

In Part 2 you learned that an image is a stack of read-only layers. So how can a running Postgres write anything at all? When Docker starts a container, it adds one extra layer on top of the image: the **writable layer** (also called the container layer). Every file the container creates or modifies lands there — the image layers below are never touched.

You've already met the tool that shows this. `docker diff` lists exactly what a container has changed relative to its image:

```
$ docker diff web
C /var
A /var/log/nginx/access.log
C /run
A /run/nginx.pid
```

Here's the trap: the writable layer belongs to the *container*, not to you. Its lifetime is the container's lifetime. `docker stop` keeps it; `docker rm` deletes it — instantly, silently, unrecoverably. Since containers are meant to be disposable (you've been `rm -f`-ing them since Chapter 2), anything you care about must live *somewhere else*.

:::notebook Copy-on-write, and why databases hate it
The writable layer works by **copy-on-write** (CoW): when a container modifies a file from an image layer, the storage driver (overlay2 on Linux) first copies the whole file up into the writable layer, then applies the change. That's cheap for a config file, brutal for a database rewriting pages inside multi-gigabyte files. So the writable layer isn't just ephemeral — it's also the *slowest* place to put heavy I/O. Volumes bypass CoW entirely: they're plain directories mounted straight into the container's filesystem. Faster *and* durable.
:::

## Volumes: storage with its own lifecycle

A **named volume** is a piece of storage that Docker manages *outside* any container. It has its own name, its own lifecycle, and its own commands:

```
$ docker volume create appdata
$ docker volume ls
$ docker volume inspect appdata
$ docker volume rm appdata
```

You attach a volume to a container at run time with `-v <volume-name>:<path-inside-container>`:

```
$ docker run -d --name db \
    -e POSTGRES_PASSWORD=secret \
    -v appdata:/var/lib/postgresql/data \
    postgres:16-alpine
```

Two things happen here. First, if `appdata` doesn't exist yet, Docker creates it on the spot — you rarely need `volume create` explicitly. Second, everything Postgres writes under `/var/lib/postgresql/data` (which is *all* of its data) now goes to the volume, not the writable layer.

Now the payoff. Remove the container — the violent way, even:

```
$ docker rm -f db
$ docker volume ls
DRIVER    VOLUME NAME
local     appdata
```

The container is gone; the volume isn't. Start a *new* container with the same `-v appdata:/var/lib/postgresql/data`, and Postgres wakes up with every table and row exactly where it left them. The container was cattle; the data never lived in it.

This inverts how you should think about stateful containers: the container is a disposable *process*, the volume is the *state*. Upgrading Postgres 16 → 17? Remove the container, run a new image, reattach the volume. That's the whole procedure.

:::notebook Where volumes actually live
On Linux, named volumes are ordinary directories under `/var/lib/docker/volumes/<name>/_data` — you can `ls` them as root. On Mac and Windows there's a twist that confuses everyone: Docker Desktop runs the engine inside a lightweight Linux **VM**, so that path exists *inside the VM*, not on your Mac. You won't find it in Finder, and that's by design — the supported ways in and out of a volume are mounting it into a container, or the backup pattern you'll learn in Chapter 15. `docker volume inspect` shows the path under `Mountpoint`, but remember whose filesystem that path is on.
:::

## The anonymous-volume gotcha

Run `docker inspect` on a Postgres container you started *without* `-v` and look at `.Mounts` — there's a volume there anyway, with a 64-character hex name. The `postgres` image declares `VOLUME /var/lib/postgresql/data` in its Dockerfile, so Docker silently creates an **anonymous volume** every time. It protects the data from CoW slowness, but it's a trap for durability: every new container gets a *fresh* anonymous volume (your old data is stranded in the previous one, findable only by hex name), and `docker rm -v` deletes them with the container. Anonymous volumes are why people *think* their data is safe until the day it isn't. Name your volumes. Always.

Two habits to pair with that one:

- `docker inspect -f '{{json .Mounts}}' <container>` is how you check, from the outside, exactly what storage a container has and where. You'll use it constantly.
- `docker volume rm` refuses to delete a volume that any container (even a stopped one) still references — and `docker volume prune` deletes every volume no container references. Read that twice before ever running it.

## The drill

You're going to re-run the incident, properly. Start Postgres with a named volume. Put data in. Then do the scariest thing you can do to a stateful container — `docker rm -f` — and prove, with a brand-new container, that the data outlived it. The verifier will even check the timestamps: your running container must be *younger* than its volume, because that gap is the whole lesson.

One practical note: you don't need a published port for this. `docker exec <db> psql -U postgres` runs the Postgres client *inside* the container over its local socket — no password prompt, no port mapping, no client install. For admin one-liners, `exec` is the professional's default.

Time to lose a container and keep the data.
