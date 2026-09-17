# The One-Command Stack

Think back to the end of Part 5. To get one small stack running you typed a `docker network create`, then three `docker run` commands, each dragging its own `--name`, `--network`, `-p`, `-e`, and volume flags behind it. It worked — and it lived entirely in your shell history. Close the terminal and the knowledge of *how to start your own application* evaporates. Ask a teammate to run it and you're pasting commands into chat, in the right order, with a "wait, first create the network" correction halfway through.

I've watched teams keep that knowledge in a `run.sh`, a wiki page, and one senior engineer's head — usually all three, all slightly different. The fix isn't a better script. It's to stop describing *how* to start the stack and start declaring *what the stack is*.

## The compose file

**Docker Compose** reads one YAML file — by convention **`compose.yaml`** — that declares every service in your application, and makes the entire stack a single unit you can start, stop, and inspect with one command. Here's a complete, real one:

```yaml
name: chai-19

services:
  web:
    image: nginx:alpine
    ports:
      - "8019:80"
    volumes:
      - ./site:/usr/share/nginx/html:ro
  redis:
    image: redis:alpine
```

Read it against what you already know — that's the trick to learning Compose fast. Everything under a service is a `docker run` flag wearing YAML clothes: `image` is the image argument, `ports` is `-p`, `volumes` is `-v`, and later you'll meet `environment` (`-e`), `build`, and friends. Nothing new is happening at runtime; you're writing down the flags once instead of typing them forever.

Two things here have no `docker run` equivalent, and they're the whole point:

- **`services`** — each key (`web`, `redis`) names one container-to-be. That name is also its DNS name: `web` can reach Redis at `redis:6379` because Compose creates a user-defined bridge network for the project and attaches every service to it. Part 5's manual network ceremony, automated away.
- **`name`** — the **project name**, the namespace for the whole stack. Every container, network, and volume Compose creates is tagged and prefixed with it.

Paths like `./site` are relative to the compose file, not to wherever you happen to run the command — so the file works identically for everyone who clones the repo.

## One command up, one command down

From the directory holding `compose.yaml`:

```
$ docker compose up -d
[+] Running 3/3
 ✔ Network chai-19_default    Created
 ✔ Container chai-19-redis-1  Started
 ✔ Container chai-19-web-1    Started
```

`up` creates the network, then creates and starts every service, in one shot. `-d` detaches, same as `docker run -d`. Look at those names: `chai-19-web-1` is `<project>-<service>-<replica>`. The stack's status, as a unit:

```
$ docker compose ps
NAME              IMAGE          SERVICE   STATUS         PORTS
chai-19-redis-1   redis:alpine   redis     Up 5 seconds   6379/tcp
chai-19-web-1     nginx:alpine   web       Up 5 seconds   0.0.0.0:8019->80/tcp
```

Logs for everything, interleaved and color-coded per service — or for one service:

```
$ docker compose logs -f          # the whole stack, live
$ docker compose logs web         # just nginx
```

And the teardown:

```
$ docker compose down
```

`down` stops and removes the containers *and* the network — the full inverse of `up`. It deliberately leaves volumes alone (your data outlives the stack, exactly the Part 4 lesson); add `-v` when you truly want the volumes gone too. Get used to this rhythm: `up -d` when you sit down, `down` when you're done, and nothing accumulates — no container graveyard, ever.

:::notebook Compose is labels, not magic
There is no "stack" object inside the Docker daemon — the daemon still only knows containers, networks, and volumes. Compose is a client-side tool: it reads your YAML, computes what should exist, and issues the same API calls you've been making by hand since Chapter 1. The project survives your terminal because Compose stamps everything it creates with labels — inspect one: `com.docker.compose.project=chai-19`, `com.docker.compose.service=web`. Every later command (`ps`, `logs`, `down`) is just a label query. That's also why `docker compose up` is idempotent: it diffs *desired state in the file* against *actual labeled state in the daemon* and only touches what changed. Edit the file, run `up -d` again, and only the changed service is recreated. This chapter's verifier reads those same labels.
:::

## Project names are the namespace

If you don't set `name:`, Compose uses the directory name as the project — which is how you end up with a project called `app` colliding with another project called `app`. Set it explicitly. You can also override it per invocation with `-p`:

```
$ docker compose -p chai-19 ps
```

That's how you address a project from anywhere, without `cd`-ing to the file. And because *everything* is namespaced by project, one compose file can run twice on the same machine as two fully independent stacks — two projects, two networks, two sets of containers, zero interference. Teams use this for feature-branch environments and parallel test runs; you'll use it in this chapter's challenge.

One habit before the exercise. `docker ps` still works and still shows compose-managed containers — Compose doesn't replace anything you've learned, it orchestrates it. When something misbehaves, `docker compose logs` first, then everything from Chapter 3 (`exec`, `inspect`, `stats`) still applies to the individual containers.

Time to retire the run-script: declare your first stack.
