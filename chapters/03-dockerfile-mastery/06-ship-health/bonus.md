# Challenge

You've seen healthy. Now manufacture the opposite — on purpose, on your laptop, instead of by surprise, in production.

The ch12 server has a saboteur switch: with the environment variable **`FAIL_HEALTH`** set (any non-empty value), it keeps serving `/` normally but answers `/health` with a `503`. The process stays up; only the pulse goes bad — the exact failure mode that fools a plain `docker ps`.

From the same **`chai-12-api:v1`** image, run a second detached container named **`chai-12-sick`** with that variable set (no published port needed). Then watch `docker ps`: it starts at `(health: starting)`, and after three failed probes (~15 seconds with your lab timings) flips to **`(unhealthy)`** — while STATUS still proudly says `Up`. Peek at `docker inspect -f '{{json .State.Health}}' chai-12-sick` to read the failing probes' own output.

**You pass when:** `chai-12-sick` runs from `chai-12-api:v1` with `FAIL_HEALTH` set, is **still running**, and its health status reads `unhealthy` — living proof that "Up" and "working" are different claims.
