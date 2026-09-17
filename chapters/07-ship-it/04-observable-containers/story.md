# Observable Containers

Chapter 3 gave you `docker logs` and you've leaned on it ever since. Time to look at what's underneath — because on a real server, the default behavior of that innocent command is a slow-motion disk-space incident, and the fix is three flags long. This chapter is logging done right, plus the daemon's own diary: `docker events`.

## The rule first: log to stdout, full stop

Pre-container apps wrote log *files* — `/var/log/app.log`, rotated by cron, tailed over SSH. Containerized apps don't, and shouldn't: a container's filesystem dies with it, and nobody SSHes into containers. The convention (the "twelve-factor" rule, if you've met it) is: **an app writes its logs to stdout/stderr and treats them as a stream; the platform deals with the rest.** Every image you've used follows it — nginx even symlinks its "log files" to `/dev/stdout` and `/dev/stderr` inside the image so legacy config keeps working. `exec` into any nginx container and look:

```
$ docker exec web ls -l /var/log/nginx/
access.log -> /dev/stdout
error.log -> /dev/stderr
```

The payoff: the *platform* — Docker — becomes the single log pipeline for every container, no matter the language or framework inside.

## Logging drivers: where the stream lands

What Docker does with the stream is pluggable: a **logging driver**. The default, `json-file`, writes every line as a JSON record to one file per container on the host; `docker logs` just reads that file back. Others ship the stream elsewhere: `syslog`, `journald`, `fluentd`, `awslogs`, `gelf`… and `local` — a compact binary format that (unlike `json-file`) rotates by default and is the better choice when nothing else reads the raw files. Check what any container uses:

```
$ docker inspect -f '{{.HostConfig.LogConfig.Type}}' chai-27-app
json-file
```

Here's the incident hiding in the default: **plain `json-file` never rotates**. A chatty container — a debug logger, a crash loop, a health check printing every second — appends to that one file forever. I've seen a forgotten staging box fill 40 GB of disk with a single container's log file; when the disk fills, *every* container on the host starts failing in creative ways. The fix is per-container **log options**:

```
$ docker run -d --name chai-27-app \
    --log-driver json-file \
    --log-opt max-size=1m --log-opt max-file=3 \
    my-chatty-image
```

`max-size=1m` caps each file at 1 MB; `max-file=3` keeps at most three (current + two rotated). Hard ceiling: 3 MB per container, forever, and `docker logs` transparently reads across the rotation. On a real host you'd set this once for everything in `/etc/docker/daemon.json` (`"log-opts": {...}`) — but per-container flags override the daemon and are what you can practice here. The settings land where you'd now expect:

```
$ docker inspect -f '{{json .HostConfig.LogConfig}}' chai-27-app
{"Type":"json-file","Config":{"max-file":"3","max-size":"1m"}}
```

:::notebook The json-file format, and the cost of a log line
On the host (inside Docker Desktop's VM on a Mac), each container logs to `/var/lib/docker/containers/<id>/<id>-json.log`, one JSON object per line: `{"log":"GET /health 200\n","stream":"stdout","time":"2026-07-13T..."}`. That wrapper is why `docker logs -t` can print timestamps it never asked your app for, and how stdout and stderr stay distinguishable (`docker logs` reprints them to the matching stream — that's why some output survives `2>/dev/null` and some doesn't). It's also why logging isn't free: every line is a write syscall, a JSON encode, and disk I/O. A container logging thousands of lines a second measurably taxes the daemon — one more reason production logs are *structured and deliberate*, not printf-confetti.
:::

## The daemon's diary: `docker events`

`docker logs` shows what your *app* said. `docker events` shows what *Docker itself* did — a live, timestamped feed of every lifecycle action on the host: create, start, stop, die, kill, OOM, pull, network connect, volume mount…

```
$ docker events
2026-07-13T14:02:11 container start 6f1c9a8b... (image=nginx:alpine, name=chai-27-app)
2026-07-13T14:02:40 container kill 6f1c9a8b... (name=chai-27-app, signal=15)
2026-07-13T14:02:40 container die 6f1c9a8b... (exitCode=0, name=chai-27-app)
2026-07-13T14:02:40 container stop 6f1c9a8b... (name=chai-27-app)
```

Run bare, it blocks and streams forever (Ctrl-C to leave). The professional form asks about a *window* and exits — with filters so you're not drinking from the firehose:

```
$ docker events --since 10m --until 0s --filter container=chai-27-app
```

Read that `stop` sequence again, because it answers a Chapter 2 mystery with receipts: a polite `docker stop` is really **kill(signal=15)** → the app exits → **die(exitCode=0)** → **stop**. A `docker stop` that hits the 10-second grace timeout shows a second `kill` with `signal=9`. And last chapter's OOM? It shows up here as an `oom` event on the container. When you're reconstructing *why* a container restarted at 3 AM — was it OOM? a deploy? a human? — `events` is the timeline you read first.

:::notebook Same feed, machine-readable
Everything `events` prints comes from the daemon's API (`/events`), and orchestrators live on this stream — it's how they notice a container died and schedule its replacement. You can consume it the same way: `--format '{{json .}}'` emits one JSON object per event, ready for a script or a `while read` loop. Combined with `--filter` (by container, image, event type, label...), "page me whenever any chai-* container dies" is a five-line shell script. Restart policies react; the events stream explains.
:::

## The rest of the kit

Two commands from Chapter 3 complete the observability picture, now with production eyes: `docker stats` (live cgroup numbers — watch MEM % against the limits you set last chapter) and `docker top` (the container's processes, host view). Logs for what the app says, events for what the platform did, stats for what it's consuming — that triangle is your first fifteen minutes of any incident.

Now make a container chatty, cap its logs like you mean it, and catch the daemon writing its diary.
