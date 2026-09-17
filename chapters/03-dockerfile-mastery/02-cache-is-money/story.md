# Cache Is Money

The ChaiCode API grew up overnight: `workspace/ch08/app/` now has a `package.json`, a lockfile, and a real dependency. That means the recipe needs a `RUN npm install` step — and the moment a build contains a slow step, *where you put it* starts costing real money. I've seen teams whose CI spent forty minutes a day reinstalling identical dependencies because two lines in a Dockerfile were in the wrong order. This chapter is about never being that team.

## How the cache thinks

`docker build` doesn't blindly re-execute your Dockerfile. For each instruction it asks: *have I built this exact step, on top of this exact parent, before?* If yes, it reuses the stored layer — a **cache hit**, effectively free. You can watch it happen: build twice without changing anything and the second run flies by with `CACHED` on every step.

The rules that decide hit-or-miss are simple and worth memorizing:

- For most instructions (`RUN`, `ENV`, `WORKDIR`…): the instruction *text* must be identical.
- For `COPY` and `ADD`: the instruction text **and the content of the copied files** must be identical. Docker hashes the files — touch one byte of one file and that `COPY` misses.
- **First miss poisons everything after it.** Once one layer must be rebuilt, every subsequent layer rebuilds too, because each layer's identity includes its parent.

That last rule is the whole game. Consider the obvious Dockerfile:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

Every edit to `server.js` changes the content going into `COPY . .` → cache miss → `npm install` re-runs from scratch. Your dependencies didn't change. Doesn't matter — the step below the miss always rebuilds. Ten-second code change, two-minute penalty, hundreds of times a week.

## Deps first: the ordering that pays rent

Dependencies change rarely; code changes constantly. So copy them in *separately*, slow-and-stable before fast-and-volatile:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

Now edit `server.js` and rebuild: `COPY package*.json ./` still matches (those files didn't change), so `RUN npm install` is **CACHED** — the miss happens only at `COPY . .`, after the expensive work. Time it yourself: `time docker build ...` cold, then warm after a code edit. On this little app it's seconds; on a real app it's your inner loop back.

The pattern generalizes to every ecosystem — `requirements.txt` before `pip install` before code; `go.mod` before `go mod download` before code. Order Dockerfile instructions by *rate of change*, slowest first. That one sentence is most of Dockerfile performance.

## .dockerignore: don't ship the kitchen

Chapter 7's notebook warned that the build context — everything in the directory you build from — gets sent to the builder. `COPY . .` then copies all of it into the image. Run `npm install` locally even once and your context contains `node_modules`: thousands of files that (a) bloat the transfer, (b) invalidate `COPY . .` every time a local install touches them, and (c) can genuinely break the image — your machine's binaries aren't Alpine's.

**`.dockerignore`** is the fix: a file at the context root listing what never gets sent, same syntax family as `.gitignore`:

```
node_modules
npm-debug.log
.git
*.env
```

Every project you Dockerize gets one, written *before* the first build. `node_modules` and `.git` are non-negotiable; secrets patterns like `*.env` are cheap insurance you'll be glad of in Part 8 — anything COPY'd into a layer is trivially extractable by anyone who gets the image, so the safest secret is one that never enters the context at all.

:::notebook BuildKit — how cache keys actually work
The builder behind modern `docker build` is **BuildKit**, and it doesn't see your Dockerfile as a list — it builds a dependency *graph* (that's why independent stages in Chapter 11 will build in parallel). Each node's cache key is roughly: parent layer's identity + the instruction +, for `COPY`/`ADD`, a content hash of the source files. Metadata like file modification times doesn't enter the hash — content does — which is why `touch server.js` alone won't bust the cache but a one-character edit will.

Two power features to file away. **Cache mounts** give a `RUN` step a persistent scratch directory that survives across builds *without* becoming a layer: `RUN --mount=type=cache,target=/root/.npm npm ci` keeps npm's download cache warm, so even when the deps layer legitimately misses (lockfile changed), packages aren't re-downloaded. And `--mount=type=secret` passes credentials to a build step without ever writing them into a layer. Both appear again in Parts 8 and 10; `docker buildx du` shows what the cache is costing you in disk.
:::

One more habit for the lockfile era: in Dockerfiles, prefer **`npm ci`** over `npm install` when a `package-lock.json` exists — it installs *exactly* what the lockfile pins, fails loudly on drift, and is built for clean-room environments like image builds. (`npm install` also works and the verifier accepts either; `ci` is what production Dockerfiles use.)

Time to make the cache work for you: same API, new recipe, and this time the ordering is the exercise.
