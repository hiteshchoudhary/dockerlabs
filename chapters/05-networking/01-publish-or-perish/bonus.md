# Challenge

Prove to yourself that `EXPOSE` is documentation, not a door.

Run a third detached `nginx:alpine` container named exactly **`chai-16-hidden`** with **no ports published at all** — no `-p`, no `-P`. The image's Dockerfile says `EXPOSE 80`, and nginx inside is genuinely listening on 80 — yet no host port will reach it.

Check your work: `docker inspect -f '{{json .Config.ExposedPorts}}' chai-16-hidden` still shows `80/tcp` (the documentation), while `.HostConfig.PortBindings` is empty (the reality).

**You pass when:** `chai-16-hidden` is running from `nginx:alpine`, its image metadata exposes `80/tcp`, and its `.HostConfig.PortBindings` is completely empty — the verifier then sneaks into the container's own network namespace to confirm nginx really is serving in there, unreachable from outside.
