Order matters: network first (`docker network create chai-28-net`), then build (`docker build -t chai-28-api:1.0 ./ch28`), then the replicas: `docker run -d --name chai-28-api1 --network chai-28-net chai-28-api:1.0` (same for `chai-28-api2`). No `-p` on the replicas — the proxy will reach them by container name over the network's DNS.

---

Copy the template (`cp ch28/nginx.conf.template ch28/nginx.conf`), then: `docker run -d --name chai-28-proxy --network chai-28-net -p 8028:80 -v "$PWD/ch28/nginx.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine`. If curl gets `502 Bad Gateway`, the proxy can't reach the replicas — check they're running, on the SAME network, and named exactly chai-28-api1/chai-28-api2 (the upstream block addresses them by name).

---

Challenge: in your `ch28/nginx.conf`, uncomment (or add) inside the `server` block: `location /health { return 200 "ok\n"; }`. Then reload the deployment: `docker rm -f chai-28-proxy` and run the same `docker run` again. Test both doors: `curl http://127.0.0.1:8028/health` (always `ok`) and `curl http://127.0.0.1:8028/` (alternating hostnames).
