# Exercise

**17.1 — Two containers, first-name basis.**

1. Create a user-defined bridge network named exactly **`chai-17-net`**.
2. Run two long-lived detached `alpine` containers on it, named exactly **`chai-17-a`** and **`chai-17-b`** (alpine's default command exits instantly — give each something to do for an hour, like in Chapter 3).
3. From *inside* `chai-17-a`, reach `chai-17-b` **by name** — `ping` it or `wget` it, but type the name, not an IP. Then look at `/etc/resolv.conf` inside either container and meet the `127.0.0.11` resolver that made it work.

**You pass when:**

- A network `chai-17-net` exists and its driver is `bridge`.
- `chai-17-a` and `chai-17-b` are both running `alpine` containers attached to `chai-17-net`.
- Name resolution works both ways: `chai-17-a` can ping `chai-17-b` by name, and `chai-17-b` can ping `chai-17-a` by name.

The verifier doesn't watch you type — it inspects the network, then runs its own `docker exec ... ping` through your wiring. If the state is right, any road you took there passes.
