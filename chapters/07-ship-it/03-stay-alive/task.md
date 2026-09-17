# Exercise

**26.1 — Put a container in its production harness.**

1. Run a detached `nginx:alpine` container named exactly **`chai-26-app`** wearing the full harness:
   - restart policy **`unless-stopped`**,
   - a hard memory cap of **64 MiB** (`--memory 64m`),
   - at most **half a CPU core** (`--cpus 0.5`).
2. Confirm the harness took — the settings live in the container's config, not your shell history: `docker inspect -f '{{.HostConfig.RestartPolicy.Name}} {{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' chai-26-app` should print `unless-stopped 67108864 500000000`.
3. Peek at where the limits really live: `docker exec chai-26-app cat /sys/fs/cgroup/memory.max` — the same `67108864`, straight from the kernel.

**You pass when:**

- `chai-26-app` is running from `nginx:alpine`.
- Its restart policy is `unless-stopped`.
- Its memory limit is exactly 64 MiB (`Memory` = `67108864`).
- Its CPU limit is exactly half a core (`NanoCpus` = `500000000`).

As always, the verifier reads the container's actual configuration — any command sequence that leaves this state passes.
