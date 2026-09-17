# Exercise

**40.1 — Take your machine's acceleration inventory.**

No GPU required — this exercise reports the truth about *whatever* hardware you're on, and passes honestly either way.

1. Ask Docker for its runtime inventory and save it to **`workspace/ch40/runtimes.txt`**:
   ```
   docker info -f '{{json .Runtimes}}' > ./ch40/runtimes.txt
   ```
   (from `workspace/` — create `ch40/` if needed.)
2. Determine whether an **`nvidia`** runtime is present, and record your finding in **`workspace/ch40/nvidia.txt`** as a single word: **`yes`** or **`no`**. (On Apple Silicon the answer is `no`, and that's a passing answer — the verifier checks your finding against reality.)

**You pass when:**

- `workspace/ch40/runtimes.txt` matches your daemon's live runtime inventory (the verifier re-runs `docker info` and compares the runtime names).
- `workspace/ch40/nvidia.txt` says `yes` or `no`, and it **matches** whether the `nvidia` runtime actually exists on this daemon.

This is a field-notes chapter: the win isn't running a GPU, it's reading your platform correctly.
