# The Audit

Audit day. Four chapters of hardening skills, one artifact to apply them to, and an auditor who doesn't take your word for anything. This chapter adds exactly one new idea — that security is a *checklist discipline*, not a collection of tricks — and then gets out of your way.

Here's the thing I want you to internalize before you start: every finding in a real container audit is boring. Nobody gets breached by an exotic zero-day nearly as often as by the container that ran as root with a writable filesystem because someone was in a hurry in 2023. The defense is equally boring: a list, applied to every image and every container, every time, enforced by a machine. Boring is the goal. Boring scales.

## The auditor's checklist

Everything below is a skill you already have; the only novelty is seeing them as one document. This is worth pinning above your desk:

**The image:**

1. **Pinned base** — `FROM` carries an `@sha256:` digest (Chapter 33). Nobody re-points your foundation.
2. **Non-root `USER`** — a dedicated user, created at build time, owning what it needs to own — including the `WORKDIR` itself (Chapter 30).
3. **`HEALTHCHECK`** — the image knows how to prove it's alive (Chapter 12). Without it, orchestrators fly blind and `docker ps` says "Up" about a corpse.
4. **OCI labels** — `org.opencontainers.image.title`, `version` and friends (Chapter 12). Provenance for humans; every serious registry and scanner reads them.
5. **No secrets in layers or env** — nothing sensitive in `docker history`, nothing in baked-in `ENV` (Chapter 32).

**The container:**

6. **Read-only rootfs** — with `tmpfs` only where genuinely needed (Chapter 31).
7. **Capabilities: drop `ALL`** — add back only what's proven necessary; for a well-built non-root app, that's *nothing* (Chapter 31).
8. **`no-new-privileges`** — the escalation ladder, welded (Chapter 31).
9. **Memory limit** — a runaway app OOMs alone instead of taking the host (Chapter 26).
10. **Pids limit** — fork bombs hit a fence (Chapter 31).
11. **Secrets as files, env clean** — `_FILE` pointers only (Chapter 32).

Read it once more and notice: items 1–5 are *build-time* facts frozen into the image; items 6–11 are *run-time* facts declared at `docker run`. That split matters organizationally — the image list is enforced in CI where images are built, the container list wherever containers are launched (compose files, deploy scripts, admission controllers). Two gates, both automatable.

## How the auditor reads your work

Not by watching you type. Every item above leaves a fingerprint in Docker's state, and by now you know exactly where:

```
$ docker image inspect -f '{{.Config.User}}' chai-34-api:v1
chai
$ docker image inspect -f '{{.Config.Healthcheck.Test}}' chai-34-api:v1
[CMD-SHELL wget -q --spider http://127.0.0.1:3000/healthz || exit 1]
$ docker inspect -f '{{.HostConfig.ReadonlyRootfs}} {{.HostConfig.CapDrop}} {{.HostConfig.Memory}}' chai-34-api
true [ALL] 268435456
$ docker inspect -f '{{.State.Health.Status}}' chai-34-api
healthy
```

This is why the whole Part kept hammering `inspect` templates: the security conversation with an auditor — or a Kubernetes admission controller, which is the same checklist wearing production clothes — happens entirely in this JSON. If it's not in the state, it didn't happen.

:::notebook Why the checklist compounds
Each item looks modest alone; the security comes from the *product*, not the sum. Trace an actual attack through the stack: the attacker exploits your app → wants to drop a payload, but the rootfs is read-only → wants to escalate via a setuid binary, but no-new-privileges is on → wants to use root powers, but the process is uid 100 holding zero capabilities → wants to fork-bomb or memory-starve the host out of spite, but cgroup fences hold → wants to steal credentials from env, but env holds only a file path, and the file is mounted read-only → wants to persist a backdoored base image for the next build, but your FROM is pinned by digest and the swap won't resolve. Six independent walls, and they had to beat *all* of them; you only had to type six flags. Defense in depth is the one place in engineering where the house always wins — provided every wall is actually up, which is what checklists (and this chapter's verifier) are for.
:::

## Your assignment

The scaffold is in `workspace/ch34/app` — the ChaiCode API, audit edition: stateless (it writes nothing, so read-only costs no tmpfs), a `/healthz` endpoint for the healthcheck to probe, and built-in support for the `_FILE` secret convention you'll need in the challenge. `workspace/ch34/partner.key` is the secret material a "partner integration" requires — the challenge is delivering it in a way that survives an env scan.

Build `chai-34-api:v1` to satisfy image items 1–5. Run `chai-34-api` on port 8034 to satisfy container items 6–11. The verifier is the auditor: one assertion per checklist line, all green or no sign-off. Nothing here is new — that's the point. It's the final exam where every question appeared on a previous test, at the same time, on one artifact, like production.

Go get the sign-off.
