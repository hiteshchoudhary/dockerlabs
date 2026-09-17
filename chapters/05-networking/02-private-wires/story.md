# Private Wires

Chapter 16 wired containers to the outside world. This chapter wires them to *each other* — and that turns out to be the more important skill, because real applications are conversations: an API talks to a database, the database talks to no one, a cache sits in the middle. None of that should go through published host ports.

## The wrong way first

Every container you've run so far without a `--network` flag landed on Docker's **default bridge** — the network called `bridge` in `docker network ls`, sitting on the `docker0` interface on Linux. Containers on it *can* reach each other, but only by IP:

```
$ docker run -d --name red alpine sleep 3600
$ docker run -d --name blue alpine sleep 3600
$ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' blue
172.17.0.3
$ docker exec red ping -c 1 172.17.0.3     # works
$ docker exec red ping -c 1 blue           # fails: bad address 'blue'
```

That IP is a trap. Container IPs are assigned at start, in order — restart `blue` after some other container has taken its slot and it comes back with a *different* address, and everything that memorized the old one breaks. Hardcoding a container IP is hardcoding a coincidence. In the very early days people patched over this with `--link`, which injected entries into `/etc/hosts` — it's still in old tutorials and it's been deprecated for years. Skip it entirely; Docker's real answer is better.

## The right way: a user-defined network

Create your own network and the whole problem dissolves:

```
$ docker network create chai-net
$ docker run -d --name red  --network chai-net alpine sleep 3600
$ docker run -d --name blue --network chai-net alpine sleep 3600
$ docker exec red ping -c 1 blue
PING blue (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.128 ms
```

On a **user-defined bridge network**, every container is reachable **by its name**. That single feature changes how you configure software: your app's config says `host: blue`, and it keeps working no matter how many times `blue` is restarted, recreated, or moved to a different IP. The name is the stable interface; the IP is an implementation detail you stop caring about.

Why doesn't the default bridge do this? History and safety. The default bridge predates Docker's DNS machinery and is kept dumb for backwards compatibility — and since *every* container lands there by default, automatic name-resolution between them would let unrelated containers discover each other by name. A network you created is an explicit statement: "these containers belong together." Docker rewards that explicitness with DNS, and it's one reason the docs flatly recommend user-defined networks for anything real.

:::notebook The embedded DNS server at 127.0.0.11
Where do those names actually resolve? Step into any container on a user-defined network and look:

```
$ docker exec red cat /etc/resolv.conf
nameserver 127.0.0.11
```

`127.0.0.11` is a loopback address *inside the container's own network namespace* — there is no DNS server process in your container. The daemon plants that address and quietly redirects anything sent to it (with NAT rules, same trick as Chapter 16) out to a small DNS resolver **built into dockerd itself**. That resolver knows every container name and network alias on the container's networks and answers those instantly; anything else — `hub.docker.com`, say — it forwards to the DNS servers your host uses. So container names resolve *and* the internet still works, with zero configuration. On the default bridge, `resolv.conf` instead points at an ordinary upstream resolver — which is exactly why `ping blue` finds nothing there: nobody who knows the name gets asked.
:::

## Networks are live, not set-in-stone

A container's networks aren't fixed at `docker run`. You can plug and unplug a *running* container like a patch cable:

```
$ docker network connect chai-net green      # green joins; DNS works immediately
$ docker network disconnect chai-net green   # unplugged; the name stops resolving
```

No restart, no downtime — the interface appears and disappears inside the container while its process keeps running. A container connected to two networks has two interfaces and two IPs, one per network, and can talk to both sides. That's a genuinely useful pattern: a reverse proxy with one foot in a `frontend` network and one in `backend` is the classic, and it's exactly how Compose lays out multi-network stacks in Part 6.

Inspection completes the toolkit. `docker network ls` lists networks; `docker network inspect chai-net` shows the subnet, the gateway, and — most usefully — a `Containers` map of everyone currently attached. From the container side, the same fact lives under `.NetworkSettings.Networks`, keyed by network name:

```
$ docker inspect -f '{{json .NetworkSettings.Networks}}' green
{"bridge":{...,"IPAddress":"172.17.0.4"},"chai-net":{...,"IPAddress":"172.19.0.4"}}
```

Two keys, two networks, two IPs — a multi-homed container at a glance.

One habit before the exercise: networks are cheap, so create one per application stack, named after it. Isolation comes free — containers on different user-defined bridges can't reach each other at all — and cleanup is one `docker network rm` after its containers are gone. The default bridge should eventually feel like what it is: a legacy landing pad you only use when you haven't said where a container belongs.

Now build a private wire and prove the names work.
