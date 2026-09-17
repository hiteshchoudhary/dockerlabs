# Debug Like It's 2026

Back in Chapter 3 I promised that `docker exec -it ... sh` would carry you far — and warned there's a class of container it can't touch. Welcome to that class. Production images in 2026 are increasingly **shell-less**: Google's **distroless** images (a runtime, your app, CA certs, and nothing else) and the ultimate version, **`FROM scratch`** — a completely empty base holding a single static binary. No `sh`, no `ls`, no `cat`, no package manager. Try to step inside and Docker tells you the truth bluntly:

```
$ docker exec -it chai-43-api sh
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH: unknown
```

Read that error the way Chapter 3 taught you: `exec` starts a *new process inside the container's namespaces*, using binaries **from the container's own filesystem**. There is no `sh` on that filesystem, so there is nothing to start. This isn't a permissions problem or a Docker bug — the tool you're asking for simply doesn't exist inside.

## Why we ship containers you can't enter

Because everything a debugger loves, an attacker loves more. A shell in a production image is a gift to anyone who achieves code execution; a package manager lets them install more gifts. Strip the image to the binary and:

- the **attack surface** approaches zero — you can't pop a shell that isn't there;
- **CVE scanners** stop crying about OS packages your app never calls (your Part 8 scanning habit gets dramatically quieter);
- images drop to a few megabytes — faster pulls, faster cold starts, cheaper registries.

A static Go binary on `scratch` is the canonical example, and it's what you'll build: a multi-stage Dockerfile (Part 3 muscle) where `golang:alpine` compiles and `scratch` ships. Final image: one layer, single-digit megabytes.

So how do you debug a sealed box? Two families of technique — and the key insight behind both is that **most of your Chapter 3 toolkit never needed a shell in the first place.**

## Family one: the daemon sees everything

`exec` is the only tool that runs *inside* the box. The rest of the break-in kit operates from the daemon's side, and the daemon doesn't care whether the image has a shell:

```
$ docker logs chai-43-api            # stdout/stderr — captured outside the container
$ docker inspect -f '{{.Path}}' chai-43-api        # what is PID 1? (the entrypoint binary)
$ docker top chai-43-api             # its processes, as the HOST sees them
$ docker stats --no-stream chai-43-api             # cgroup numbers, no shell required
$ docker cp chai-43-api:/chai-api ./binary-copy    # yes, cp works on scratch images too
$ docker diff chai-43-api            # what changed on its filesystem since start
```

Logs, config, process table, resource usage, file extraction — that's 80% of real debugging, available on the most locked-down image imaginable. When an incident hits a distroless service, this family answers "what is it, what is it doing, what did it write" before you reach for anything fancier.

## Family two: bring your own toolbox

For the remaining 20% — "I need to run a network probe *from where the container stands*" — you don't add tools to the image. You **attach a second container that carries the tools**, joined into the target's namespaces. Remember `--network container:` from Part 5? It's the whole trick:

```
$ docker run --rm --network container:chai-43-api nicolaka/netshoot ss -tlnp
$ docker run --rm --pid container:chai-43-api --network container:chai-43-api \
    nicolaka/netshoot ps aux
```

The probe container shares the target's **network namespace** — its `localhost` *is* the target's localhost, its interfaces are the target's interfaces. Add `--pid container:` and the probe sees the target's processes too. `nicolaka/netshoot` is the community's beloved kitchen-sink toolbox (tcpdump, ss, dig, curl, strace…); plain `busybox` covers the basics at 4 MB. The target image stays sealed; the tools live for one command and vanish with `--rm`.

This move has a superpower no published port can match: it reaches ports that were **never published**. An admin endpoint bound inside the container on `:9090` with no `-p`? Unreachable from your host — but a probe sharing the network namespace hits `127.0.0.1:9090` like it lives there. Because, for a moment, it does. That's your Challenge.

:::notebook `docker debug` — the official toolbox
Docker packaged family two as a product: `docker debug <container>` drops you into a fully-tooled shell (bash, vim, curl, htop, and an installable toolbox) *attached to* any container — even shell-less ones, even *stopped* ones — without modifying the image. Under the hood it mounts a tooling filesystem and joins the container's namespaces, exactly the sidecar pattern above with better ergonomics. It ships with Docker Desktop but sits behind a **paid subscription**, which is why this lab teaches the underlying pattern instead of requiring the command — pattern first, product when your employer pays for it. Kubernetes standardized the same idea as `kubectl debug` with **ephemeral containers**, so this technique transfers straight to your cluster future.
:::

:::notebook Why the error says "OCI runtime exec failed"
The chain from Chapter 1 explains the wording: the daemon asks containerd, containerd asks **runc** (the OCI runtime) to spawn a process in the existing namespaces. runc resolves `sh` against the container's own `$PATH`, on the container's own root filesystem, finds nothing, and reports up the chain — hence an *OCI runtime* error, not a Docker one. The same mechanism is why the sidecar works: namespaces are join-able by design (`setns`), so a new process can enter the target's world while keeping binaries from its *own* image. Filesystem from the probe, network from the target — mixed namespaces are the entire magic.
:::

## The 2026 posture

Build images too small to attack, and debug them from outside: daemon-side tools first, ephemeral tooling containers second, `docker debug` when it's available. What you give up is one command — `exec sh`. What you get back is a production fleet where there's nothing for an intruder to run.

Time to build a sealed box, fail to break into it, and debug it anyway.
