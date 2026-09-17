# Exercise

**39.1 — Build a jail for untrusted code, then prove it holds.**

The untrusted program is scaffolded at `workspace/ch39/untrusted.py` — read it; each attack reports `BLOCKED` or `ESCAPED` so the jail's effect is visible.

1. Run it in a container named exactly **`chai-39-sandbox`** from **`python:3.12-alpine`**, hardened with **all** of these:
   - `--network none`
   - `--read-only` **and** `--tmpfs /tmp` (so legit code can still write scratch)
   - `--cap-drop ALL`
   - `--pids-limit 64`
   - `--memory 128m`
   - a **non-root** user (e.g. `--user 65534:65534`)
   - the script mounted read-only (e.g. `-v <abs path>/untrusted.py:/code/untrusted.py:ro`)
2. Capture everything the container prints to **`workspace/ch39/output.txt`** (from `workspace/`: `./ch39/output.txt`). Do **not** use `--rm` — the verifier inspects the exited container's jail settings.

**You pass when:**

- An exited container `chai-39-sandbox` from `python:3.12-alpine` exists with **every** bar in place: NetworkMode `none`, read-only rootfs, `CapDrop` includes ALL, PidsLimit 64, Memory 128 MB, non-root user.
- `workspace/ch39/output.txt` shows the legitimate `RESULT: 42` **and** the write to `/tmp` succeeding.
- The output proves all three attacks were **BLOCKED** (network, filesystem, and fork-bomb) — the jail didn't just run the code, it defeated the mischief.

The verifier inspects the container's actual runtime config and reads your captured output — it re-checks every bar independently.
