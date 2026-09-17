# Challenge

A load balancer must be able to say "I'm alive" without asking anyone behind it.

Add a **`/health`** endpoint that nginx answers **itself** — no trip to the upstream. Edit your `ch28/nginx.conf` (the template's comments point the way: a `location` block with a plain `return`), respond with body `ok`, then recreate the proxy container so the new config loads (`docker rm -f chai-28-proxy` and run it again — config is part of the deployment, and Chapter 29 is about to make that philosophy official).

Prove the difference to yourself: `curl http://127.0.0.1:8028/health` says `ok` instantly and identically every time, while `/` keeps alternating hostnames.

**You pass when:** `http://127.0.0.1:8028/health` returns HTTP 200 with body `ok` — straight from the proxy — while `/` still round-robins across both replicas.
