# Challenge

The API hides an admin endpoint on container port **9090** — bound inside, never published. From your host, `curl localhost:9090` gets you nothing. The sidecar pattern gets you in.

Run a throwaway `busybox` probe **joined to `chai-43-api`'s network namespace** (`--rm`, so it vanishes), fetch `http://127.0.0.1:9090/` with `wget -qO-` from in there, and save the response to **`workspace/ch43/probe.txt`**.

**You pass when:** `probe.txt` contains exactly what the admin endpoint serves — the verifier runs its own namespace-joined probe and compares. There is no way to produce this file from the host side; only a probe standing *inside the container's network* can see port 9090.
