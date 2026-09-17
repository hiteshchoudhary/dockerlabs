# The Full Wire-Up

Time to combine the last two chapters into the topology you'll actually run for the rest of your career. Almost every real application reduces to the same shape: a **front door** that the outside world may knock on, and a set of **back rooms** — databases, caches, queues — that only the application itself should ever see. Chapter 16 gave you the door (`-p`, chosen deliberately); Chapter 17 gave you the back rooms (a user-defined network with DNS). This chapter wires up the whole house.

## The topology

Three containers, one private network, exactly one published port:

```
$ docker network create app-net

$ docker run -d --name db --network app-net \
    -e POSTGRES_PASSWORD=secret postgres:16-alpine

$ docker run -d --name cache --network app-net redis:alpine

$ docker run -d --name api --network app-net -p 8080:80 nginx:alpine
```

Look hard at what's *missing*: no `-p` on the database, no `-p` on the cache. This is the single most important line of defense you'll build in this book. Postgres listens on 5432 and Redis on 6379 — *inside the network*. The `api` container reaches them by name, courtesy of the embedded DNS:

```
$ docker exec api getent hosts db
172.20.0.2        db
$ docker exec api nc -z -w 2 db 5432 && echo reachable
reachable
$ docker exec api nc -z -w 2 cache 6379 && echo reachable
reachable
```

Meanwhile, from the host — and from everything beyond it — those services simply don't exist:

```
$ nc -z -w 2 127.0.0.1 5432; echo $?
1
```

Your application config becomes beautifully boring: `DB_HOST=db`, `REDIS_HOST=cache`, and it never changes again — not across restarts, not across machines. That's the payoff of Chapter 17's names combined with Chapter 16's restraint.

## Why "just don't publish it" is the whole security model

It's tempting to think an unpublished database is a small optimization. It isn't — it's the difference between "attacker needs to compromise the api first" and "attacker needs a laptop." Shodan (a search engine for exposed services) indexes hundreds of thousands of open databases at any given moment, and a good share of them are Docker containers where someone typed `-p 5432:5432` out of habit, on a machine whose firewall Docker quietly bypassed (Chapter 16). The unpublished container has *no host port at all* — nothing to firewall, nothing to scan, nothing to brute-force. The `.HostConfig.PortBindings` map is empty, and empty is the strongest thing it can be.

The mental checklist for any new service from now on: **does anything outside the network need this?** For the api: yes → publish, deliberately, on a chosen interface. For everything else: no → attach to the network and stop. When you meet Compose in Part 6, you'll see this exact topology expressed in a dozen lines of YAML — same network, same names, same single `ports:` entry — so the thinking you do here transfers one-to-one.

:::notebook Veth pairs and bridges — trace your container's cable
The word "attach" has been doing a lot of work, so here's the physical reality. When a container joins a bridge network, the kernel creates a **veth pair** — two virtual ethernet interfaces joined back-to-back, a literal virtual patch cable: packets in one end come out the other. Docker puts one end *inside* the container's network namespace and renames it `eth0` — that's the interface your app binds. The other end stays on the host, named `veth`-something, and gets plugged into a **bridge** — a virtual switch (`docker0` for the default network; `br-<id>` for each network you create).

So `docker network create` builds a switch, and every `docker run --network` crimps a new cable from a container into that switch. Containers on the same bridge talk through it directly, at memory speed; separate bridges are separate switches with no cable between them — that's why networks isolate. On a Linux host you can see the whole loom: `ip link` lists the `veth` ends and which bridge each is enslaved to (on Docker Desktop, look inside the VM). And the container's route to the internet? The bridge's own address is the container's default gateway, and outbound traffic is masqueraded (NAT again) so replies find their way home.
:::

:::notebook The modes that skip the wiring: host and none
Two special network modes replace all of the above. `docker run --network host` skips the namespace entirely — the container shares the *host's* network stack. No veth, no bridge, no NAT, no `-p` (publishing is meaningless; the container's ports simply *are* host ports). It buys raw performance and hands back all the isolation this Part taught you to value — rare, deliberate uses only. Historically it was Linux-only; Docker Desktop supports it too since 4.34, as an opt-in setting.

The opposite extreme, `docker run --network none`, gives the container a network namespace containing *only* a loopback interface. No cable at all: it can't reach the internet, other containers, or the host, and nothing can reach it. It sounds useless until the day you need to run untrusted code, or a batch job that must provably touch nothing — then it's the sharpest tool in the drawer. Part 9's agent-sandboxing chapter leans on exactly this.
:::

## Proving a topology, not eyeballing it

The habit this chapter should leave you with: every claim about your wiring is checkable from state. Attached to the network? `.NetworkSettings.Networks` has the key. Isolated from the host? `{{len .HostConfig.PortBindings}}` prints `0`. Reachable by name from a neighbor? `docker exec` a probe. The exercise's verifier does precisely these checks and nothing else — build the topology any way you like, and let the state speak.

Wire up the full stack.
