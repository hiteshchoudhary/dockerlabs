# Exercise

**1.1 — Verify Docker, then run your first container.**

1. **Check the install.** Confirm both the `Client` *and* the `Server` (daemon) sections answer. If `Server` errors, start Docker Desktop and wait for it to settle.
2. **Run your first container** from the `hello-world` image, naming the container exactly **`chai-01-hello`**. Read the output — it narrates its own trip through the daemon, the registry, containerd, and runc.

**You pass when:**

- The Docker daemon is up and answering.
- A container named `chai-01-hello` exists.
- It was created from the `hello-world` image.
- It ran and exited cleanly (exit code `0`).

*How* you get there is up to you — the verifier inspects the resulting Docker state, never the commands you typed.
