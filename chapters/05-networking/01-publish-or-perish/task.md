# Exercise

**16.1 — Publish one port privately, one publicly.**

1. Run a detached `nginx:alpine` container named exactly **`chai-16-web`**, publishing container port 80 **only on the host's loopback interface**, at host port **8016**. This is the careful bind — reachable from your machine, invisible to your network.
2. Run a second detached `nginx:alpine` container named exactly **`chai-16-open`**, publishing container port 80 on **all interfaces** (the default bind) at host port **8116**.
3. Curl both — `http://127.0.0.1:8016` and `http://127.0.0.1:8116` — and confirm nginx answers on each. Then compare the two in `docker ps`'s PORTS column: one says `127.0.0.1:8016->80`, the other `0.0.0.0:8116->80`. Same page served, very different audience.

**You pass when:**

- `chai-16-web` is running from `nginx:alpine`, its `80/tcp` binding has `HostIp` `127.0.0.1` and `HostPort` `8016`, and it answers on `http://127.0.0.1:8016`.
- `chai-16-open` is running from `nginx:alpine`, its `80/tcp` binding is on all interfaces (`0.0.0.0`) at `HostPort` `8116`, and it answers on `http://127.0.0.1:8116`.

The verifier reads `.HostConfig.PortBindings` straight out of `docker inspect` and curls both ports — it never sees what you typed, only what you built.
