# One Front Door

Count the published ports in a real production deployment and you'll usually find exactly one: 443. Behind it: five, fifty, five hundred containers, none of them reachable from outside. Everything enters through a single **reverse proxy**, and it forwards traffic inward. This chapter builds that shape on your machine, because it's the shape every serious deployment takes — and because it finally answers a question that's been hanging since Part 5: if app containers don't publish ports, how does anyone reach them?

## Why not just publish the app?

You've been doing `-p 8080:3000` since Part 1 and it works fine — for one container. Production needs more from its front door:

- **One entry point, many apps.** You can't publish two containers on port 443. A proxy can route `/`, `/api`, `/admin` to three different services behind one port.
- **Load balancing.** One replica of an API is a single point of failure. Run three, and *something* must spread requests across them.
- **TLS termination.** Certificates, renewals, cipher configuration — done once at the proxy, instead of inside every app container in five languages.
- **A control point.** Timeouts, request size limits, rate limiting, security headers, gzip: enforced at the door, uniformly, no app code changed.

A **reverse proxy** is a server that does all of this: it accepts the client's request and makes its *own* request to a backend, then relays the answer. ("Reverse" because a regular proxy sits in front of *clients* going out; this one sits in front of *servers*, facing in.) We'll use **nginx** — the one you'll meet most in the wild. Traefik auto-discovers containers via labels and Caddy brings automatic HTTPS; both are excellent, but nginx's explicit config teaches the mechanics the others automate — learn it first and the others feel obvious.

## The topology

Three containers, one network, one published port:

```
                        chai-28-net (user-defined bridge)
  browser ──▶ :8028 chai-28-proxy ──▶ chai-28-api1:3000
                                  └─▶ chai-28-api2:3000
```

The api replicas are built from the scaffold in `workspace/ch28/` — a ten-line Node server whose every response names its own hostname. That's deliberate: when two identical replicas answer in turn, the changing hostname is your *proof* the load balancer is working. Neither replica gets a `-p` flag. They're unreachable from the host — try `curl` directly and there's simply no door. Only the proxy is published, and it reaches the replicas the same way containers found each other in Part 5: **Docker's DNS on a user-defined network**, where the container name *is* the address.

## nginx as a container

The config (scaffolded as `ch28/nginx.conf.template`) has two working parts. First, a named pool of backends:

```
upstream chai_api {
    server chai-28-api1:3000;
    server chai-28-api2:3000;
}
```

nginx distributes requests across an upstream's servers **round-robin by default** — no flag needed. (Other strategies exist when you need them: `least_conn`, `ip_hash` for sticky sessions.) Second, a server block that forwards everything to the pool:

```
server {
    listen 80;
    location / {
        proxy_pass http://chai_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

`location /` matches every path; add a second block like `location /api/` and you've got path routing — several apps behind one door. The `proxy_set_header` lines matter more than they look: a proxied backend otherwise sees every request coming from the proxy's IP. These headers forward the original client's identity — skip them and, months later, your API logs swear every user on earth shares one address (I've debugged that "attack" more than once; it was nginx, being honest by default).

The stock `nginx:alpine` image loads any config at `/etc/nginx/conf.d/default.conf`, so running the proxy is a Part 4 move — bind-mount your copy over it, read-only:

```
$ docker run -d --name chai-28-proxy --network chai-28-net -p 8028:80 \
    -v "$PWD/ch28/nginx.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine
```

Then watch the door do its job:

```
$ curl http://127.0.0.1:8028/
hello from 3f9a1c2b4d5e
$ curl http://127.0.0.1:8028/
hello from 7e8d0a9f6c1b
```

Two hostnames, alternating. That's two machines pretending to be one — the whole trick, visible.

:::notebook What the proxy actually changes about a request
This isn't traffic "passing through" — the proxy runs **two separate TCP connections**: client↔proxy and proxy↔backend. The backend request is one nginx composed itself, which is exactly why the forwarding headers must be set explicitly, and why the proxy is such a natural enforcement point: it can time out a slow backend (`proxy_read_timeout`), retry the *other* replica if one refuses the connection (upstreams do this for free), buffer a huge response, or reject an oversized upload — all invisible to both ends. It's also why the replicas can stay unpublished: the proxy's request to `chai-28-api1:3000` is ordinary container-to-container traffic on the bridge network. The only "port publishing" that exists is the proxy's own `-p 8028:80`.
:::

:::notebook DNS round-robin vs a real upstream
Compose fans sometimes skip the upstream block: scale one service to three replicas and `proxy_pass http://api:3000` — Docker's DNS itself rotates the answers (Part 6 used this). It works, but nginx caches resolved IPs, so it can pin to dead backends and skip fresh ones until re-resolve. An explicit `upstream` gives nginx the full member list: per-request rotation, connection retries against the next member, and health-aware balancing (`max_fails`). Rule of thumb: DNS rotation for demos, upstreams (or a discovering proxy like Traefik) for anything real.
:::

One more habit this chapter installs: the proxy can *answer some paths itself* — no backend involved. A `location /health { return 200 "ok\n"; }` is served straight from nginx in microseconds, which is what a load balancer's own health endpoint should be. That's your challenge.

Build the door, hide the apps behind it, and catch the hostnames alternating.
