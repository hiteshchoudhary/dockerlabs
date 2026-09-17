# Backup Like You Mean It

Chapter 13 ended with a comforting fact: volumes survive their containers. Here's the uncomfortable follow-up — surviving a `docker rm -f` is not the same as being backed up. A volume still lives on exactly one disk. Laptop stolen, disk dies, `docker volume prune` on a sleepy Friday, or the classic: "I upgraded Docker Desktop and reset to factory defaults." Any of those, and *volumes* turn out to have been a single point of failure with better marketing.

So: how do you get data *out* of a volume, into a boring file you can copy anywhere — and back in again?

## You can't just copy the directory

Your first instinct is probably `cp` — find where the volume lives and copy it. On a Mac or Windows machine that path is inside Docker Desktop's VM (Chapter 13's notebook), so there's nothing to `cp` from Finder's point of view. On Linux you *can* reach `/var/lib/docker/volumes/.../_data` as root, but you shouldn't build habits on it: you'd be sneaking behind the daemon's back, permissions and all, and the habit dies the moment you touch a Mac, a CI runner, or a remote host.

`docker cp`? Closer — but it copies between a *container* and the host, not a *volume* and the host, and it needs a container that already mounts the volume. In real incidents the container is often gone; that's why you're restoring.

The portable answer uses only things you already own: any container can mount any volume, and a container can also bind-mount a host directory. Mount both into one throwaway container, and it becomes a bridge.

## The tar pattern

Say the data lives in a volume named `appdata`. Back it up like this:

```
$ docker run --rm \
    -v appdata:/data:ro \
    -v "$(pwd)":/backup \
    alpine tar czf /backup/appdata.tar.gz -C /data .
```

Read it mount by mount, because this line is the whole chapter:

- `--rm` — a **throwaway container**: it exists for one command, then removes itself. No name, no residue. This is peak container thinking — five megabytes of alpine as a disposable power tool.
- `-v appdata:/data:ro` — the volume, mounted **read-only**. A backup must never be able to mutate what it's backing up.
- `-v "$(pwd)":/backup` — a bind mount (Chapter 14) of your current host directory. This is the bridge out of Docker's world onto your disk.
- `tar czf /backup/appdata.tar.gz -C /data .` — create (`c`) a gzipped (`z`) archive file (`f`), after **c**hanging into `/data`, of everything there (`.`).

When it exits, `appdata.tar.gz` is sitting in your host directory: an ordinary file. Copy it to S3, another machine, a USB stick — it's not Docker's problem anymore, which is the point.

:::notebook Why `-C /data .` and not `/data`?
`tar czf backup.tar.gz /data` would store every path *with the `/data` prefix* — restore that into a volume mounted at `/data` and you get `/data/data/...`, the single most common restore bug in existence. `-C /data .` says "step inside first, archive relative paths". Restores then land exactly where the new volume is mounted, whatever that mount point is called. The paired restore flag is `-C /data` on extraction. Muscle-memory both, together, as one unit.
:::

## Restoring — into a fresh volume

Restore is the mirror image: new (or empty) volume mounted read-write, host dir mounted in, extract:

```
$ docker volume create appdata-restore
$ docker run --rm \
    -v appdata-restore:/data \
    -v "$(pwd)":/backup \
    alpine tar xzf /backup/appdata.tar.gz -C /data
```

And here's the professional habit that separates "we have backups" from "we can restore": **verify the copy with its own throwaway container.**

```
$ docker run --rm -v appdata-restore:/data:ro alpine ls -laR /data
$ docker run --rm -v appdata-restore:/data:ro alpine cat /data/some-file
```

A backup you've never restored is a rumor. Restore drills — actually extracting into a scratch volume and reading the files back — are how you find out the tarball was empty *before* the night you need it. The restored volume is also genuinely **independent**: it shares no storage with the original, so you can mount it into a new Postgres, poke at it, even corrupt it, and the source volume never feels a thing. (You'll prove that in the challenge.)

One correctness note for databases: tarring a volume underneath a *running* Postgres can catch files mid-write. For real database backups, either stop the container first (cold copy) or — better — use the engine's own tool (`pg_dump` through `docker exec`, the same pattern you used in Chapter 13). The tar pattern is the universal, engine-agnostic layer underneath; know both.

:::notebook Scheduled-backup thinking
Nobody remembers to run tar at 2 AM, and the 2 AM backup is the one that matters. Once the pattern is one command, scheduling it is whatever you already use: a cron line on the host calling this exact `docker run --rm ... tar` command, a CI job on a timer, or — very Docker-brained — a tiny container running `crond` with the backup script baked in, spawning throwaway siblings on schedule. Whichever you pick, apply three rules: timestamp the filenames (`appdata-$(date +%F).tar.gz`), ship them *off the machine* (a backup on the disk it protects is half a backup), and schedule a periodic **restore drill** — automation can rot silently for months. Part 7's restart policies and health checks give you the operational vocabulary to keep such a sidecar honest.
:::

## Where this fits

You now hold the complete data story: the writable layer for nothing you care about (13), volumes for state the app owns (13), bind mounts as the bridge between host and container worlds (14), tmpfs for the deliberately forgetful (14), and now — using volumes and bind mounts *together* — a backup and restore path that works on any machine Docker runs on, with no plugins and a five-megabyte toolbox.

Time for a full drill: seed a volume, archive it, restore it into a second volume, and prove the copy stands on its own.
