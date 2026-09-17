# The Recipe

Everything so far used images other people built — `hello-world`, `alpine`, `nginx`. Useful, but the real promise of Part 1 was *ship your own app with its whole environment*. Today you cash that in. There's a small Node API sitting in `workspace/ch07/app/` — the ChaiCode API, one file, zero dependencies — and by the end of this chapter it will be an image with your name on it, running like any other container.

You saw `docker commit` in Part 2: run a container, poke it into shape by hand, snapshot it. And you saw why nobody ships that way — it's an artifact with no memory of how it was made. A **Dockerfile** is the opposite: a plain text file that states, step by step, how to assemble an image. Check it into git, and every build from it is reproducible, reviewable, and repeatable on any machine. It's a recipe, and `docker build` is the cook.

## The four instructions that carry most images

Open `workspace/ch07/app/server.js` and look at what it needs: Node, itself, and nothing else. The Dockerfile for that is four ideas long:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY server.js .
CMD ["node", "server.js"]
```

Line by line, because each one earns its place:

- **`FROM`** picks the starting point — every image is built *on top of* another. `node:22-alpine` is the official Node image on Alpine Linux: a full OS filesystem plus a pinned Node runtime, ~130 MB instead of the ~1 GB Debian-based `node:22`. Pin the major version. `FROM node` means "whatever was latest that day", and you learned in Part 2 what `latest` is worth.
- **`WORKDIR`** sets the directory every later instruction (and the running container) starts in — creating it if needed. Without it you'd be dumping files into `/`, which works and is wrong, like keeping your code on the desktop.
- **`COPY`** takes files from *your machine* and bakes them into the image. Left side: path relative to the build context (more on that below). Right side: path in the image, here relative to `WORKDIR`.
- **`CMD`** declares what runs when a container starts from this image. It doesn't run at build time — it's a note pinned to the image for later. That bracket syntax is deliberate; Chapter 9 is entirely about it.

There's a fifth instruction you'll meet the moment your app needs anything installed: **`RUN`** executes a command *during the build* (`RUN npm install`, `RUN apk add curl`) and snapshots the result into the image. Our zero-dependency app doesn't need it yet — Chapter 8 is where `RUN` starts to matter, and where it starts to cost.

One more, because it separates images you can trace from images you find in a haystack two years later: **`LABEL`** attaches metadata. There's an open standard for the key names — the OCI image annotations — and this book uses it from day one:

```dockerfile
LABEL org.opencontainers.image.title="chai-07-api"
```

Labels ride inside the image; `docker image inspect` reads them back. Chapter 12 builds this into a full shipping discipline.

## Build it, tag it, run it

From the directory containing the Dockerfile:

```
$ docker build -t chai-07-api:v1 .
[+] Building 2.1s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load build context
 => [1/3] FROM docker.io/library/node:22-alpine
 => [2/3] WORKDIR /app
 => [3/3] COPY server.js .
 => exporting to image
 => => naming to docker.io/library/chai-07-api:v1
```

`-t` names and tags the result — the same `name:tag` scheme you used pulling images in Part 2, now applied to one you made. Each `[n/3]` step became a **layer**, exactly the layers you dissected with `docker history`. Watch what *didn't* happen: `CMD` and `LABEL` produced no steps worth timing — they only write metadata.

Then run it like any image, publishing the container's port 3000 onto your host:

```
$ docker run -d --name chai-07-api -p 8007:3000 chai-07-api:v1
$ curl http://localhost:8007
{"service":"chaicode-api","status":"ok","hostname":"3f9a1c...","node":"v22.x.x"}
```

That JSON is the whole book in one line: your code answering from inside an environment you defined, froze, and can now start anywhere.

## That dot at the end

The `.` in `docker build ... .` is the most misread character in Docker. It is not "where the Dockerfile is". It's the **build context** — the directory whose contents get handed over to the builder.

:::notebook The build context — what actually gets sent to the daemon
Remember the client/daemon split from Chapter 1: your terminal doesn't build anything — the daemon does, and the daemon may not even be on your machine. So `docker build` packs the context directory into a tar archive and *sends* it to the builder. Only files inside that archive exist as far as `COPY` is concerned — you cannot `COPY ../secrets.env`, and that's a feature.

The classic self-inflicted wound is running `docker build` from a huge directory — home folder, monorepo root, a project with `node_modules` and `.git`. Every byte gets tarred and shipped before step one, and worse, it can silently end up inside your image. BuildKit (the default builder since Docker 23) softens this by sending files lazily and prints the context size in its output — `transferring context: 2.1kB` is what health looks like; `1.2GB` means stop. The surgical fix, `.dockerignore`, is the star of the next chapter.
:::

Two habits to start now, while the stakes are small. First: keep the Dockerfile *next to the app*, at the root of what it needs, and build from there — context stays tiny. Second: tag every build (`:v1`, not nothing); untagged builds become the `<none>` graveyard you met in Part 2.

The ChaiCode API is waiting in `workspace/ch07/app/`. Write the recipe, cook it, serve it.
