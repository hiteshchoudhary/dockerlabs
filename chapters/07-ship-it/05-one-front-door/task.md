# Exercise

**28.1 — Two hidden replicas behind one published proxy.**

1. Create a user-defined network named exactly **`chai-28-net`**.
2. Build the api image from the scaffold: **`chai-28-api:1.0`** from `workspace/ch28/` (context `./ch28` in the lab terminal).
3. Run **two replicas** from it — **`chai-28-api1`** and **`chai-28-api2`** — detached, on `chai-28-net`, and **without publishing any ports**. No `-p`. The host cannot reach them, and that's the point.
4. Prepare the proxy config: copy `ch28/nginx.conf.template` to **`ch28/nginx.conf`** (your working copy — the template stays pristine).
5. Run **`chai-28-proxy`** from `nginx:alpine`, detached, on `chai-28-net`, published on host port **`8028`**, with your `nginx.conf` bind-mounted (read-only) to `/etc/nginx/conf.d/default.conf`.
6. Knock on the front door repeatedly — `curl http://127.0.0.1:8028/` several times — and watch the hostname change as the upstream round-robins.

**You pass when:**

- `chai-28-net` exists, and `chai-28-api1` + `chai-28-api2` are running on it from your `chai-28-api` image with **no published ports**.
- `chai-28-proxy` is running on `chai-28-net`, published on `8028`.
- Repeated requests to `http://127.0.0.1:8028/` are answered by **at least two different hostnames** — load-balancing, observed.

The verifier probes the running topology from outside, exactly like a client would — it never sees your commands.
