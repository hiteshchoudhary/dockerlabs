# The Inner Loop, 2026 Edition

The **inner loop** is the cycle you live in all day: edit code, see the result, edit again. Before containers, it was fast — save the file, refresh the browser. Then we containerized everything, and the honest version of the loop became: edit, `docker compose build`, `docker compose up -d`, wait, refresh. Thirty seconds if the cache is kind, minutes if it isn't. Nobody stays in flow across that gap.

Part 4 gave you one escape hatch: bind-mount the source into the container. It works, and for plenty of projects it's fine. But you paid for it with the problems from Chapter 14 — host/container UID mismatches, `node_modules` written by the wrong side, macOS file-event weirdness across the VM boundary — and with something subtler: the container stops running *the image* and starts running *your desk*. The thing you test drifts from the thing you ship.

**`docker compose watch`** is the 2026 answer: the image stays authoritative, and Compose actively ferries your edits into the running container the moment you save.

## The `develop` section

Watch is configured per service, in YAML you now read fluently:

```yaml
services:
  web:
    build: ./app
    ports:
      - "8022:3000"
    develop:
      watch:
        - action: sync
          path: ./app/public
          target: /usr/src/app/public
        - action: rebuild
          path: ./app/package.json
```

Each entry under `watch:` is a rule: *when files under `path` change on the host, do `action`*. Two actions do most of the work:

- **`sync`** — copy the changed files into the running container at `target`. No rebuild, no restart; the file just appears, in milliseconds. Right for anything the app reads live: static assets, templates, and source under a hot-reloading dev server.
- **`rebuild`** — rebuild the image and recreate the container. Heavyweight and *correct* for changes the running process can't absorb: `package.json` means dependencies changed, and no amount of file-copying installs a dependency — the `RUN npm ci` layer has to run again.

There's a third, **`sync+restart`** — copy the files, then restart the container (not rebuild) — for apps that read config once at boot: a change to `nginx.conf` or an app's `config.yaml` is useless until the process starts over, but rebuilding the image for it would be waste. Choosing among the three is the actual skill; it's a map of *what kind of change* to *the cheapest action that makes it real*.

## Running it

```
$ docker compose up -d --build
$ docker compose watch
Watch enabled
```

(Or both at once: `docker compose up --watch`.) Now edit a file under `./app/public` and save:

```
Syncing service "web" after changes were detected: app/public/index.html
```

Refresh the browser — the change is live. Touch `package.json` instead and watch does the expensive-but-right thing:

```
Rebuilding service "web" after changes were detected: app/package.json
 ✔ Service "web"  Built    1.9s
 ✔ Container chai-22-web-1  Started
```

The loop is back to save-and-refresh, and yet at any moment `docker compose build` still produces the true production artifact from the same Dockerfile. That's the whole trade Part 4 couldn't offer: dev-speed feedback *and* image fidelity.

:::notebook sync vs rebuild vs sync+restart — what each actually does
`sync` never touches the image: Compose (long-polling the filesystem for events) copies changed files straight into the *container's* writable layer — the same layer you learned about in Chapter 13, so a `down`/recreate discards them. That's not a bug: the image remains the source of truth, and the next `up` starts clean. `rebuild` is the honest full path — `docker build` with your cache tricks from Chapter 8 doing the heavy lifting, then recreate; the container's writable layer (including anything previously synced) is discarded, which is exactly what you want after a dependency change. `sync+restart` copies files, then sends the restart signal — the process re-reads its config, the writable layer survives, and no build runs. One more rule worth knowing: `ignore:` lets a rule skip paths (classically `node_modules/`), and a path matched by a `rebuild` rule wins over a broader `sync` rule that also covers it.
:::

:::notebook Why not just bind-mount, again?
Because watch is a one-way ferry, not a shared folder, the failure modes of Chapter 14 disappear: the container never writes back to your host (no root-owned files in your repo), the host's `node_modules` never shadows the container's (sync just doesn't copy what you ignore), and file events don't have to cross the macOS/Windows VM boundary as a mounted filesystem — Compose watches on the host, where events are native, and pushes content over the API. The cost is honesty about direction: watch is for *dev feedback*, not for getting data out of containers. That's what volumes (Part 4) and `docker cp` (Chapter 3) remain for.
:::

The exercise scaffolds a tiny landing-page server in `workspace/ch22/app` — it re-reads its HTML on every request, so a `sync` rule is all it needs to feel instant. You'll declare the watch config, and the verifier reads your resolved config and the running stack; actually *running* `docker compose watch` and editing the page live is the part you should do for yourself, because seeing the sync line appear is the moment this chapter clicks.

Declare the loop.
