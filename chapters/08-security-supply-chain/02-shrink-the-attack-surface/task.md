# Exercise

**31.1 — Run nginx in full armor.**

Run a container named **`chai-31-app`** from **`nginx:alpine`**, serving on host port **8031**, hardened with all four cuts:

1. **Read-only root filesystem** — plus the tmpfs mounts nginx needs to boot (the chapter shows the detective method; nginx has two writable spots: its cache directory and its runtime/pid directory).
2. **Capabilities on allowlist** — drop `ALL`, then add back *only* the three nginx actually needs: `CHOWN`, `SETGID`, `SETUID`. Not one more.
3. **No privilege escalation** — `no-new-privileges`.
4. **Process ceiling** — a pids limit of `100`.

Then prove the armor to yourself:

- `curl localhost:8031` still serves the welcome page — hardening changed nothing for legitimate traffic.
- `docker exec chai-31-app touch /etc/pwned` fails with *Read-only file system*.

**You pass when:**

- `chai-31-app` is running from `nginx:alpine` and answers on port 8031.
- Its root filesystem is read-only (and a write attempt inside really fails).
- `CapDrop` contains `ALL` and `CapAdd` contains exactly `CHOWN`, `SETGID`, `SETUID`.
- `no-new-privileges` is set.
- The pids limit is `100`.

The verifier reads these straight out of `docker inspect` — the flags you typed are invisible to it; only the container's actual configuration counts.
