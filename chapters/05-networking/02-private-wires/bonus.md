# Challenge

Patch a cable into a *running* container.

1. Run a third long-lived `alpine` container named exactly **`chai-17-c`** — on the **default bridge** (no `--network` flag). From inside it, try `ping chai-17-a`: it fails. Different network, and no name-DNS anyway.
2. Without stopping `chai-17-c`, connect it to **`chai-17-net`** live. Ping `chai-17-a` by name again — now it answers.
3. Feel the unplug too: `docker network disconnect` it, watch the ping die, then **connect it back**. Leave it connected to *both* networks — that dual attachment is your proof the cable was patched in live, since `docker run` only ever plugs a container into one.

**You pass when:** `chai-17-c` is running, attached to **both** `bridge` and `chai-17-net`, and can reach `chai-17-a` by name.
