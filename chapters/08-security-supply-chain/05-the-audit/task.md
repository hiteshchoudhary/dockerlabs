# Exercise

**34.1 — Pass the audit.**

The scaffold is in **`workspace/ch34/app`** (`server.js`, `package.json` — stateless, `/healthz` endpoint, listens on 3000).

1. Write a `Dockerfile` in `workspace/ch34/app` and build **`chai-34-api:v1`** so the image satisfies:
   - **pinned base**: `FROM node:22-alpine` **by digest** (pull it, extract its repo digest, pin it — Chapter 33 method),
   - **non-root**: dedicated user, correct ownership including the workdir itself (Chapter 30 — remember the directory gotcha),
   - **`HEALTHCHECK`**: probe `http://127.0.0.1:3000/healthz` (busybox `wget --spider` is right there in the image; a 5s interval keeps the audit snappy),
   - **OCI labels**: `org.opencontainers.image.title="chai-34-api"` and a non-empty `org.opencontainers.image.version`.
2. Run it as **`chai-34-api`**, publishing **8034**:3000, hardened per the container checklist:
   - read-only rootfs (the app is stateless — no tmpfs needed),
   - `--cap-drop ALL`, adding back **nothing**,
   - `no-new-privileges`,
   - a memory limit (256 MB is plenty),
   - a pids limit of `100`.
3. Wait for `docker ps` to show **(healthy)**, then take the audit.

**You pass when** — one assertion per checklist line, all green:

- Image: exists · base pinned by a genuine local digest · non-root `USER` · `HEALTHCHECK` present · both OCI labels set.
- Container: running from `chai-34-api:v1` · reports **healthy** · process uid ≠ 0 · rootfs read-only (a real write attempt fails) · `CapDrop ALL` with empty `CapAdd` · `no-new-privileges` · memory limit set · pids limit set · answers on 8034 as a non-root process.

The auditor never saw your terminal — every line above is read from image config and container state, which is the only testimony that counts.
