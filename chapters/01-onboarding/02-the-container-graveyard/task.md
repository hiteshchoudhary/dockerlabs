# Exercise

**2.1 — Drive the full container lifecycle.**

1. Run an **nginx** web server container, **detached**, named exactly **`chai-02-web`**.
2. Let it run for a few seconds, then take it through a real stop/start cycle (`stop` + `start`, or `restart`). It must be **running** when you verify.
3. Make some graveyard junk on purpose: run a container named **`chai-02-junk`** from `alpine` (it will exit immediately) — then **remove it** properly.

**You pass when:**

- A container named `chai-02-web` exists, uses an `nginx` image, and is **running**.
- Its `StartedAt` is meaningfully later than its `Created` timestamp — proof of a genuine stop/start cycle (don't rush: wait a few seconds before restarting).
- No container named `chai-02-junk` exists — you cleaned your graveyard.
