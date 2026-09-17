# Publish or Perish

You containerized a web app, it started clean, the logs say `listening on port 80` — and `http://localhost` gives you *connection refused*. Welcome to Part 5. Nothing is broken. The container is doing exactly what containers do: keeping to itself.

Back in Chapter 1 you met namespaces — the kernel feature that gives a container its own private view of the machine. That includes a **network namespace**: every container gets its own network stack, with its own interfaces, its own routing table, and its own IP address on a Docker-managed internal network. Ports it listens on are open *in there*, not on your machine. Your browser lives on the host. The two are different network worlds, and until you build a bridge between them, they can't hear each other.

## Publishing a port

That bridge is the `-p` flag — **publishing** a port:

```
$ docker run -d --name web -p 8080:80 nginx:alpine
$ curl http://localhost:8080
<!DOCTYPE html>
... Welcome to nginx! ...
```

Read `-p 8080:80` as *host:container*, left to right, outside to inside. Traffic hitting **host** port 8080 is forwarded to **container** port 80. The two numbers are independent: the container's nginx believes it owns port 80, and ten containers can all believe that simultaneously — as long as each maps to a *different* host port, because host ports are the one thing that can't be shared:

```
$ docker run -d --name web2 -p 8080:80 nginx:alpine
docker: ... Bind for 0.0.0.0:8080 failed: port is already allocated
```

`docker ps` shows the mappings in the `PORTS` column, and `docker port web` lists them for one container. For scripts and verifiers, the truth lives in inspect, under `.HostConfig.PortBindings`:

```
$ docker inspect -f '{{json .HostConfig.PortBindings}}' web
{"80/tcp":[{"HostIp":"","HostPort":"8080"}]}
```

## EXPOSE is documentation

Sooner or later you'll read a Dockerfile with `EXPOSE 80` in it and assume that's what opens the port. It isn't. **`EXPOSE` publishes nothing.** It's metadata — the image author's note saying "the process inside listens here." You can see it on any image or container:

```
$ docker inspect -f '{{json .Config.ExposedPorts}}' web
{"80/tcp":{}}
```

That entry exists whether or not you passed `-p`. Remove every `EXPOSE` from a Dockerfile and the container works exactly the same; add `EXPOSE 9999` and nothing listens there. The only runtime behavior it has: `docker run -P` (capital P) publishes all *exposed* ports onto random host ports. Useful for a quick poke, useless for anything you need to find again. The habit to build: `EXPOSE` in the Dockerfile as documentation, explicit `-p` at run time as the actual decision.

## 127.0.0.1 vs 0.0.0.0 — who else can reach your container?

Here's the part almost nobody reads until it hurts. `-p 8080:80` doesn't just open the port for *you* — it binds host port 8080 on **`0.0.0.0`**, meaning *every network interface the host has*. Your loopback, yes — and also your Wi-Fi address. Anyone on the same network — the office LAN, the coffee-shop Wi-Fi — can hit your laptop's IP on port 8080 and reach that container.

For a demo, fine. For the Postgres you just ran with a throwaway password, not fine. The fix is the full three-part form of `-p`:

```
$ docker run -d --name db -p 127.0.0.1:5432:5432 postgres:16-alpine
```

`ip:hostport:containerport` — now the bind is on **loopback only**. `localhost:5432` works; your laptop's Wi-Fi IP on 5432 answers nothing. The inspect output makes the difference visible:

```
"HostIp": "127.0.0.1"   ← loopback only
"HostIp": ""            ← 0.0.0.0, all interfaces (the default)
```

One extra reason to take this seriously on Linux servers: Docker programs the kernel's firewall *directly*, so a published port can bypass host firewalls like `ufw` — people have "firewalled" a database while Docker held the door open underneath. Real breaches have started exactly this way, with Redis and Mongo containers published to `0.0.0.0` on internet-facing hosts. The rule that keeps you safe is small: **default to `127.0.0.1` for anything that isn't meant for the public, and treat every `-p` as a security decision, not plumbing.**

:::notebook How a packet actually reaches the container
`-p` isn't magic forwarding dust — on Linux it's mostly **NAT**, the same trick your home router does. When you publish a port, the Docker daemon writes **iptables** rules into the kernel's `nat` table: a `DNAT` rule that says "TCP arriving on host port 8080 → rewrite destination to 172.17.0.2:80" (the container's IP on the Docker bridge). The kernel rewrites the packet's destination address and routes it across the bridge into the container's network namespace — the container just sees a normal connection to its port 80. Replies are un-rewritten on the way out.

One case iptables can't cover: connections from the host itself over loopback. For those, Docker runs a tiny userspace helper — **docker-proxy** — one process per published port, which literally `accept()`s on the host port and copies bytes to the container. Run `ps aux | grep docker-proxy` on a Linux box with published ports and you'll see them sitting there. On Docker Desktop (Mac/Windows) the containers live inside a lightweight VM, so the port must additionally be forwarded from your Mac into that VM — Desktop handles that hop invisibly, which is why everything here behaves the same on your machine.
:::

## Reading the bindings like an engineer

Two more inspect templates worth keeping — they extract one fact each from `PortBindings`, and the exercise's verifier uses exactly these:

```
$ docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostIp}}' web

$ docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostPort}}' web
8080
```

The double `index` is Go-template for "key `80/tcp` in the map, element `0` of the list" — a container port can be bound more than once. An empty `HostIp` is the `0.0.0.0` default you now know to distrust.

Time to publish one port carefully and one carelessly, and see the difference in the state.
