# Break In, Look Around

Sooner or later — usually sooner — a container misbehaves and you need to see inside it. This chapter is your debugging toolkit: five commands that answer, for any running container, the questions *what is it saying, what is it doing, and what does it look like inside?* Professionals reach for these on reflex; by the end of the exercise, so will you.

## Read what it says: `docker logs`

By convention, containerized apps don't write log files — they write to **stdout and stderr**, and Docker captures everything:

```
$ docker logs web              # everything so far
$ docker logs -f web           # follow live, like tail -f
$ docker logs --tail 50 web    # just the last 50 lines
$ docker logs --since 10m web  # last ten minutes
$ docker logs -t web           # with timestamps
```

This works on **exited** containers too — a crashed container's last words are always available until you `rm` it. When something dies, `docker logs` is the first command you type, every time.

## Step inside: `docker exec`

`exec` runs an *additional* command inside a container that's already running. The one you'll use daily starts a shell — effectively stepping inside the box:

```
$ docker exec -it web sh
/ # ps aux
PID   USER   COMMAND
  1   root   nginx: master process
...
/ # exit
```

Look at that `ps` output from inside: the container sees a world where nginx is **PID 1** and almost nothing else exists. That's the process namespace from Chapter 1, seen from within.

You don't have to go interactive. One-shot commands are often better — they're scriptable:

```
$ docker exec web cat /etc/nginx/nginx.conf
$ docker exec web ls /usr/share/nginx/html
```

Two things to understand about `exec`. First, it's **not SSH** — nothing is listening for you inside the container. Second, it requires the binary you're invoking to exist *in the container's image*: if the image ships no shell (some minimal production images don't), `exec -it ... sh` simply fails. There's a modern answer to that — `docker debug` — which gets its own chapter in Part 10.

:::notebook What `-i` and `-t` actually do
Everyone types `-it` as a magic incantation; here's what the letters mean. **`-i`** (interactive) keeps stdin open, so what you type is piped into the process. **`-t`** allocates a **pseudo-TTY**, which makes the process believe it's talking to a real terminal — that's what gets you a prompt, line editing, and colored output. A shell without `-i` can't hear you; without `-t` it won't show a prompt. For scripted one-shots (`docker exec web cat file`) you want *neither* — there's no conversation, just output. And under the hood, `exec` works by asking the kernel to start a new process **joining the container's existing namespaces** (the `setns` syscall) — it's a door into the same isolated world, not a network connection.
:::

## The full truth: `docker inspect`

`ps` shows a summary; `inspect` shows *everything* Docker knows about a container, as one large JSON document — state, config, network, mounts, all of it:

```
$ docker inspect web
[ { "Id": "6f1c9a8b...", "State": { "Status": "running", ... }, ... } ]
```

Reading walls of JSON gets old, so `inspect` takes **format templates** with `-f` — surgical extraction of exactly one fact:

```
$ docker inspect -f '{{.State.Status}}' web
running
$ docker inspect -f '{{.Config.Image}}' web
nginx
$ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web
172.17.0.2
```

That last one — the container's IP address — uses `range` because a container can sit on several networks (Part 5 territory). Format templates look cryptic for a day and then become the sharpest tool you own: every verifier in this course is built on them, and so is half of real-world Docker automation.

## Watch it breathe: `docker stats` and `docker top`

```
$ docker stats --no-stream
NAME   CPU %   MEM USAGE / LIMIT     MEM %
web    0.00%   3.9MiB / 7.7GiB       0.05%
$ docker top web
```

`stats` is a live per-container resource meter (CPU, memory, network, disk I/O) — those numbers come straight from the cgroups you met in Chapter 1. `top` lists the container's processes *as the host sees them*. Between them, "is this container eating my machine?" takes five seconds to answer.

## Move files: `docker cp`

Copy files in either direction, running or exited:

```
$ docker cp web:/etc/nginx/nginx.conf ./nginx.conf   # container → host
$ docker cp ./index.html web:/usr/share/nginx/html/  # host → container
```

Post-mortems are the killer use: a container crashed, and its debug dump is trapped in the corpse — `docker cp` retrieves it. One warning so the habit never forms: copying files *into* running containers is for debugging, never for deployment. Changes made this way die with the container — the durable way to get files into containers is the image build (Part 3) and mounts (Part 4).

:::notebook Where logs actually live
The daemon's default logging driver, `json-file`, writes every container's stdout/stderr to a JSON file on the host — one per container (on Linux: `/var/lib/docker/containers/<id>/<id>-json.log`; on Mac/Windows, inside Docker Desktop's VM). `docker logs` just reads that file back. Two consequences worth knowing now: logs survive crashes but not `docker rm`, and an unrotated chatty container can eat gigabytes of disk. Log rotation and alternative drivers are a production concern we'll tackle properly in Part 7.
:::

Now break into one yourself.
