# Shrink the Attack Surface

Chapter 30 fixed *who* the process is. This chapter fixes *what it's allowed to do*. The audit finding reads: "containers run with a writable filesystem, the default capability set, privilege escalation enabled, and no process limits." Translated: if the app is ever compromised, the attacker inherits a comfortable workshop. Today we take the workshop away — four flags at a time.

**Attack surface** is everything an attacker can reach once they're in. A container's default surface is generous because Docker optimizes defaults for "any random image boots." Production hardening is the art of handing the process exactly what it needs and nothing more — and Docker makes each cut a single flag.

## Cut one: a filesystem that can't be rewritten

An attacker's first moves after breaking into a process are usually writes: drop a tool, patch a script, add a cron entry. **`--read-only`** mounts the container's entire root filesystem read-only — the image becomes untouchable at runtime:

```
$ docker run -d --name web --read-only nginx:alpine
$ docker exec web touch /etc/pwned
touch: /etc/pwned: Read-only file system
```

Beautiful. Except most real software assumes it can scribble *somewhere* — and nginx is a perfect specimen. Run it exactly as above and it dies on boot:

```
$ docker logs web
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)
```

nginx buffers request bodies in `/var/cache/nginx` and writes its pid file under `/run`. The answer is *not* to give up on read-only — it's **`--tmpfs`**: an in-memory filesystem (Part 4's third mount type) grafted onto exactly the paths that need to be writable:

```
$ docker run -d --read-only --tmpfs /var/cache/nginx --tmpfs /run nginx:alpine
```

Now the image is immutable, the scratch space is RAM (gone at container stop), and nothing an attacker writes survives. Finding a program's writable paths is honest detective work: run it read-only, read the error, add a tmpfs, repeat until it boots clean.

## Cut two: drop the capabilities

Even after Chapter 30, plenty of images (nginx included) start as root and then shed privilege. What does that root actually hold? Not a single almighty bit — since Linux 2.2, root's power is split into ~40 **capabilities**: `CAP_CHOWN` (change file owners), `CAP_NET_BIND_SERVICE` (bind ports below 1024), `CAP_SYS_ADMIN` (a grab-bag so wide it's nicknamed "the new root"), and so on.

Docker already strips containers down to a default set of about a dozen. Hardening flips the logic from denylist to allowlist:

```
$ docker run --cap-drop ALL --cap-add CHOWN --cap-add SETGID --cap-add SETUID ...
```

**`--cap-drop ALL`** removes everything; each **`--cap-add`** grants one power back. Which ones does nginx actually need? The empirical method again — drop ALL, read the crash:

```
nginx: [emerg] chown("/var/cache/nginx/client_temp", 101) failed (1: Operation not permitted)
```

That's `CAP_CHOWN`. Add it, next crash names the next one. For `nginx:alpine` the full list is exactly three: `CHOWN`, plus `SETGID` and `SETUID` — the master process runs as root and must switch its workers to the `nginx` user, which is literally the setuid/setgid pair. Notice what's *not* needed: `NET_BIND_SERVICE`, the classic "port 80 needs root" capability — inside Docker containers, unprivileged low-port binding is switched on, so even port 80 is free.

:::notebook What root really is — capabilities and the seccomp floor
When the kernel checks "may this process do X?", it doesn't ask "is uid 0?" — it asks "does the process hold capability Y?". Traditional root is just a process holding all of them. This is why nginx's master can run as uid 0 yet be harmless with only three capabilities: uid is a name, capabilities are the actual keys. See a live container's set with `docker exec <c> grep Cap /proc/1/status` — the `CapEff` bitmask is the truth (decode it on any Linux with `capsh --decode=<mask>`). Below capabilities sits a second, quieter layer: **seccomp**. Docker's default seccomp profile blocks ~44 of Linux's ~350+ syscalls outright — `mount`, `reboot`, `kexec_load`, `ptrace` of other processes — before capability checks even happen. Every container you've ever run wore this armor without you noticing. The two layers compose: seccomp decides *which syscalls exist*, capabilities decide *what privileged syscalls succeed*. `--privileged` — a flag you should treat as radioactive — turns both off at once.
:::

## Cut three: no promotions

Capabilities can be *gained* as well as dropped — the classic route is a **setuid binary** like `sudo` or `passwd`: a file marked so that executing it grants the owner's (root's) identity. Compromised process finds a vulnerable setuid binary → uid 0. One flag welds the ladder shut:

```
$ docker run --security-opt no-new-privileges ...
```

With **no-new-privileges**, the kernel guarantees this process and all its children can never acquire more privilege than they started with, setuid bits be damned. There is no legitimate reason for a well-built service to escalate at runtime; set it everywhere.

## Cut four: a ceiling on processes

A **fork bomb** — a process that does nothing but clone itself — will freeze a whole host in seconds, from inside a container, without needing any privilege at all. The defense is a cgroup limit you met cousins of in Chapter 26:

```
$ docker run --pids-limit 100 ...
```

One hundred processes is a fortune for nginx (a master plus a few workers). The 101st `fork()` simply fails. Set it to a number comfortably above your app's honest needs, and a runaway — malicious or buggy — stops at the fence.

## The assembled armor

Each flag lands in `docker inspect` under `.HostConfig` — `ReadonlyRootfs`, `CapDrop`, `CapAdd`, `SecurityOpt`, `PidsLimit` — which is how the audit (and this chapter's verifier) reads your work without watching you type. All four cuts stack into one run command, and the app on top behaves *identically*: same content, same speed, same logs. Security that costs a longer command line and nothing else.

Your turn — armor an nginx until the crashes stop naming missing pieces.
