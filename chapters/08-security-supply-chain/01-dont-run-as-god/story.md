# Don't Run as God

Run any container you've built so far and ask it who it is:

```
$ docker exec chai-07-api id
uid=0(root) gid=0(root) groups=0(root)
```

Root. Every Dockerfile you've written runs its app as root, because that's the default and nothing forced you to think about it. This is the single most common finding in a container security audit, and it's finding number one on ours — this Part plays out as an enterprise security review of the ChaiCode platform, and by Chapter 34 an automated auditor will grade your work line by line.

## Why root in a container still matters

The reflex answer is "it's containerized, who cares?" — and it's wrong in an important way. A container is not a security wall; it's a set of namespaces and cgroups around an ordinary process (Chapter 1). The process inside shares your machine's kernel. When it runs as uid 0, it is *the same uid 0* the kernel knows about — merely with a restricted view and a trimmed set of privileges.

That matters the day something goes wrong:

- **Kernel or runtime exploit.** Container escapes exist; they get CVE numbers every year. An escape from a root container lands you as root on the host. An escape from uid 100 lands you as nobody-in-particular.
- **Bind mounts.** Mount a host directory into a root container (Part 4) and the container writes to your files *as root*. One sloppy `-v` and a compromised app owns whatever you mounted.
- **Everything inside.** Root inside the container can install tools, rewrite the app, bind any port, and read every file — a perfect base camp for an attacker who got in through your app's vulnerability.

The fix costs three lines in a Dockerfile. There is no excuse not to pay it.

## Creating a user at build time

Base images like `alpine` and `node:22-alpine` boot as root because *builds* need root — installing packages, writing to `/usr`. The pattern is: do root things first, then create an unprivileged user and switch to it as the last act:

```dockerfile
FROM node:22-alpine
WORKDIR /app

RUN addgroup -S chai && adduser -S -G chai chai && chown chai:chai /app

COPY --chown=chai:chai . .

USER chai
EXPOSE 3000
CMD ["node", "server.js"]
```

Three new things:

- **`adduser`** — on Alpine, `addgroup -S chai && adduser -S -G chai chai` creates a **system** group and user (`-S`): no password, no home-directory ceremony, a low uid. (Debian-family images spell it `groupadd`/`useradd`.)
- **`USER chai`** — every instruction after this line, *and the container's process itself*, runs as `chai`. Put it late: `apk add` and friends above it still need root.
- **`COPY --chown=chai:chai`** — files copied into an image are owned by root by default, *even after a `USER` line*. If your app only reads its files, you might not notice. The moment it writes — a cache, an upload, a log file — it dies with `EACCES`.
- **`chown chai:chai /app`** — the subtle one. `WORKDIR /app` *creates* the directory, as root. `COPY --chown` fixes the files you copy in, but not the directory they land in — so an app that creates *new* files or subdirectories in `/app` still crashes. Chowning it here is free: at this point `/app` is a single empty directory, so the layer costs nothing.

That `--chown` flag deserves a second look, because the obvious alternative is a trap:

```dockerfile
COPY . .
RUN chown -R chai:chai /app     # DON'T
```

It works, but remember Chapter 5: every instruction is a layer, and `chown` rewrites file metadata, which copies **every file into a new layer**. Your image just doubled the size of `/app` to change an owner field. `COPY --chown` sets ownership *while copying* — one layer, zero waste.

:::notebook What uid 0 in a container really is
User identity is just a number the kernel attaches to a process, and by default Docker does **no translation** of it: uid 0 in the container *is* uid 0 to the kernel. What makes container-root weaker than real root is everything Docker straps around the process — a capability set cut down to a dozen-odd entries (next chapter), a seccomp filter on syscalls, namespaces hiding the host's files and processes. Defense in depth, not identity change. The kernel does offer real translation — **user namespaces**, where uid 0 inside maps to, say, uid 100000 outside; Docker supports this (`userns-remap`, and rootless mode runs the whole daemon unprivileged) but it's not on by default because it complicates volume ownership. So the practical rule for the rest of this book: assume container-root is host-root with obstacles, and don't hand it to your app in the first place.
:::

## When you don't control the Dockerfile

You'll run plenty of images you didn't build. Two tools:

First, check what an image *wants* to run as — the `USER` instruction is recorded in image config:

```
$ docker image inspect -f 'user={{.Config.User}}' nginx:alpine
user=
```

Empty means root. Second, override it at runtime with **`--user`**:

```
$ docker run --user 1000:1000 some-image
```

This forces the process to that uid regardless of the Dockerfile — and it appears in `docker inspect` under `.Config.User`, which is exactly where an auditor (or a verifier) looks. Many official images ship a ready-made unprivileged account precisely for this: the `node` image includes a user called `node` (uid 1000), Postgres has `postgres`, nginx has `nginx`. The catch is the same as above: the image's directories must be writable by whoever you switch to, or the app falls over at the first write. That's why `--user` is a runtime patch, not a substitute for building the image right.

One port-related footnote before the exercise: historically, non-root processes couldn't bind ports below 1024, which is why so many old images cling to root. Inside Docker containers this restriction is switched off — and our API listens on 3000 anyway. One less excuse.

The scaffold for this chapter is in `workspace/ch30/app` — a small Node server that deliberately writes to disk at startup, so a wrong ownership setup crashes instantly instead of lurking. Build it right.
