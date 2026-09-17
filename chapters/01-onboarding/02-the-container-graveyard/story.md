# The Container Graveyard

Run `docker ps -a` on any machine that's been used for Docker work, and you'll find it: dozens of containers in the `Exited` state, accumulating like tombstones. Nobody planned this graveyard. It happens because most developers learn `docker run` on day one and don't learn the rest of the lifecycle until something breaks. This chapter is the rest of the lifecycle.

## Foreground and detached

In Chapter 1, your containers ran in the **foreground** — they held your terminal until they finished. Fine for `hello-world`, useless for anything long-running. A web server would hold your terminal hostage forever.

The `-d` flag runs a container **detached** — in the background:

```
$ docker run -d --name web nginx
6f1c9a8b7d2e...
```

Docker prints the container's ID and gives your prompt back. The container is now running; see it with:

```
$ docker ps
CONTAINER ID   IMAGE   STATUS         NAMES
6f1c9a8b7d2e   nginx   Up 8 seconds   web
```

Remember the distinction: `docker ps` shows *running* containers only. `docker ps -a` shows **all** of them — including every container that ever exited and wasn't removed. That's your graveyard.

## Why exited containers stick around

It looks like a bug — the container finished, why is it still here? It's deliberate. An exited container keeps its **filesystem** and its **logs** exactly as they were at the moment of death. When a production process crashes at 3 AM, that corpse is your crime scene: you can read its logs, inspect its final state, even copy files out of it. Docker never throws away evidence unless you tell it to.

The cost is disk space and clutter. The cure is knowing your verbs:

```
$ docker stop web        # graceful shutdown (we'll define "graceful" below)
$ docker start web       # start the SAME container again — same filesystem, same identity
$ docker restart web     # stop + start in one move
$ docker rm web          # delete an exited container (its filesystem and logs are gone)
$ docker rm -f web       # force: stop AND delete a running one
```

Note what `start` implies: stopping a container does not destroy it. It's the same container afterwards — same name, same writable filesystem, new process.

For containers you never want to keep, decide at creation time:

```
$ docker run --rm alpine echo "gone without a trace"
```

`--rm` auto-deletes the container the moment it exits. Perfect for one-off commands and experiments; it's why *my* `docker ps -a` stays clean.

## stop vs kill — and the ten-second story

`docker stop` is polite: it sends the process the **SIGTERM** signal — "please finish up" — then waits **10 seconds**. If the process is still alive after the grace period, Docker loses patience and sends **SIGKILL**, which no process can refuse. `docker kill` skips the courtesy entirely and SIGKILLs immediately.

This is worth internalizing, because the difference shows up in your data: a database that gets SIGTERM flushes to disk and closes connections; one that gets SIGKILL mid-write may corrupt state. If your app needs longer than ten seconds to shut down cleanly, raise the grace period: `docker stop -t 30 web`.

:::notebook PID 1, signals, and why some containers ignore `stop`
Inside its namespace, your containerized process runs as **PID 1** — the position init/systemd occupies on a normal Linux system. PID 1 is special in the kernel: signals that have default handlers for every other process (SIGTERM politely terminates them) have **no default behavior** for PID 1. If the app doesn't explicitly handle SIGTERM, the signal is silently ignored — and every `docker stop` takes the full 10 seconds before the SIGKILL hammer falls. You'll notice this as "why does stopping this container always take forever?" Now you know: its app never handles SIGTERM. We'll fix this properly in the Dockerfile chapters (exec form, `init: true`).
:::

## Reading exit codes

Every dead container carries its cause of death:

```
$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Exited (0) 2 minutes ago
worker    Exited (137) 5 minutes ago
```

- **0** — clean exit.
- **1–125** — the app's own error code, same as any shell command.
- **137** = 128 + 9 — killed by SIGKILL (a `docker kill`, the post-`stop` hammer, or the OOM killer — more on that in the production chapters).
- **143** = 128 + 15 — terminated by SIGTERM, shut down gracefully on request.

Reading `137` and immediately thinking *"something killed it — was it memory?"* is a skill that separates people who use Docker from people who operate it.

:::notebook The container state machine
A container moves through a fixed set of states: `created` (exists, never started — `docker create` gets you here) → `running` → `paused` (frozen via cgroups, rarely used) → `exited` → gone (after `rm`). Two details worth keeping: **restarting an exited container reuses its writable filesystem** — files your process wrote before dying are still there; and the **`Created` timestamp never changes** while `State.StartedAt` updates on every start — which is exactly how this chapter's verifier will know you really performed a stop/start cycle.
:::

Time to practice the full lifecycle on a real web server.
