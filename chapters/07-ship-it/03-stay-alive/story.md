# Stay Alive

A container on your laptop dies, you shrug and restart it. A container on a server dies at 3 AM, and nobody is there to shrug. Production has two non-negotiables that your lab work so far has quietly ignored: processes must come back when they fall over, and no process may eat the machine. Docker covers both with a pair of run-time settings — **restart policies** and **resource limits** — and this chapter is where you stop deploying without them.

## Restart policies: who picks the process back up?

By default: nobody. A container that exits stays exited (`docker ps -a` is full of the evidence — Chapter 2 called it the graveyard). The `--restart` flag hands that job to the daemon:

```
$ docker run -d --restart unless-stopped nginx:alpine
```

Four policies exist, and the differences are exactly the things that bite:

- **`no`** — the default. Dies, stays dead.
- **`on-failure[:N]`** — restart only if the exit code is non-zero, optionally give up after N tries. Right for batch jobs: a clean exit means *finished*, not *failed*.
- **`always`** — restart no matter what, including after a daemon reboot. The trap: even when you `docker stop` it, a daemon restart resurrects it. Containers you can't seem to kill are almost always this policy.
- **`unless-stopped`** — like `always`, with the sane exception: if a human deliberately stopped it, it stays stopped across daemon restarts. **This is the production default in practice.**

Two behaviors worth knowing before you trust this. First, restarts use an **exponential backoff** (100ms, 200ms, 400ms…) so a crash-looping container doesn't hammer the CPU. Second, watch a crash-loop live and you'll see `Restarting (1) 2 seconds ago` in `docker ps` — with `docker inspect -f '{{.RestartCount}}'` counting the attempts. A high `RestartCount` is your cheapest production alarm: the app is dying and being resuscitated in a loop, and `docker logs` (which survives every restart) will tell you why.

The policy lives in the container's config, not in your shell history: `docker inspect -f '{{.HostConfig.RestartPolicy.Name}}'` — which is precisely where the verifier will look.

## Resource limits: no container eats the machine

Containers share the host kernel, and by default they share it *without table manners* — any one of them may take all the memory and all the CPU. On a shared server that's how one leaky app takes down five healthy ones. Two flags set the ceilings:

```
$ docker run -d --memory 64m --cpus 0.5 nginx:alpine
```

- `--memory 64m` — a hard cap. The container's processes can never hold more than 64 MiB of RAM.
- `--cpus 0.5` — at most half a CPU core's worth of time, enforced by the scheduler. Unlike memory, CPU overuse doesn't kill anything; the process is simply **throttled** — it runs slower.

Inspect stores them in raw units, and it pays to recognize them: `--memory 64m` becomes `Memory: 67108864` (bytes), `--cpus 0.5` becomes `NanoCpus: 500000000` (billionths of a core). `docker stats` then shows usage *against the limit* — `3.9MiB / 64MiB` — which finally makes its MEM % column meaningful.

How big should the ceilings be? Measure first (`docker stats` under real load), then set the limit comfortably above steady-state — the limit is a circuit breaker for runaways, not a diet plan for healthy apps.

:::notebook cgroups v2 — where the limits actually live
The flags are a UI over **control groups**, the kernel feature from Chapter 1's notebook. Every container gets a cgroup directory, and the limits are literally files in it. From inside the container:

```
$ docker exec chai-26-app cat /sys/fs/cgroup/memory.max
67108864
$ docker exec chai-26-app cat /sys/fs/cgroup/cpu.max
50000 100000
```

`memory.max` is your `--memory` in bytes. `cpu.max` reads "50,000 µs of CPU time per 100,000 µs window" — i.e. 0.5 cores. Current consumption sits alongside in `memory.current`, and `memory.events` counts how often the kernel had to intervene (its `oom_kill` counter is about to matter). `docker stats` is just these files, polled and formatted. The "v2" matters historically: the old v1 hierarchy scattered these knobs across a dozen mount points; v2 unified them, and every modern Docker runs it.
:::

## The OOM kill: what a memory limit does when it triggers

CPU throttles; memory **kills**. There's no way to "run slower" on RAM you don't have — so when a process exceeds `memory.max`, the kernel's **OOM killer** (out-of-memory) terminates it with `SIGKILL`. From the outside, the container just dies with exit code **137** (128 + signal 9 — Chapter 2's exit-code arithmetic), and Docker sets a dedicated flag you can query:

```
$ docker inspect -f '{{.State.OOMKilled}} {{.State.ExitCode}}' chai-26-oom
true 137
```

That `OOMKilled: true` is the difference between "the app crashed" and "the app hit its memory ceiling" — two very different 3 AM diagnoses. You'll trigger one deliberately in the challenge, with a one-line memory hog: `head -c 100m /dev/zero | tail`. It works because `tail` must buffer its *entire* input to find the last lines — a guaranteed 100 MB balloon inside whatever cap you set.

One flag pairs with `--memory` for a clean demonstration: `--memory-swap`. Set it *equal* to `--memory` and the container gets no swap at all — the cap is a hard wall and the kill is immediate and deterministic. Leave it unset and Docker may grant swap on top of RAM, letting the hog wheeze along before dying.

:::notebook Exit 137 is not always an OOM
Reflex worth installing: `137` means SIGKILL, and *two* culprits send SIGKILL — the kernel's OOM killer, and `docker stop` giving up after its 10-second grace period. `.State.OOMKilled` distinguishes them: `true` means the kernel did it (and `memory.events` inside the cgroup will show `oom_kill 1`); `false` with 137 means someone killed it from outside. Orchestrators surface the same distinction — Kubernetes literally prints `OOMKilled` in `kubectl describe` — so this habit transfers straight to the next lab.
:::

Restart policy plus resource limits — that's the minimum harness any container must wear before it's allowed near a server. Strap one in, then push one over the memory cliff on purpose.
