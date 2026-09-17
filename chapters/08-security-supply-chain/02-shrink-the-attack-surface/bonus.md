# Challenge

nginx needed three capabilities back only because its master process starts as root and switches users itself. A process that *starts* unprivileged needs none at all — the strongest sandbox in this Part so far.

Run a container named **`chai-31-flag`** from **`alpine`** that:

- runs as uid **65534** (the traditional `nobody`) via `--user`,
- has a read-only root filesystem,
- drops **ALL** capabilities and adds back **none**,
- sets `no-new-privileges`,
- stays alive so it can be inspected (a long sleep will do).

Zero capabilities, zero writable paths, zero escalation routes, not even a real user account — and the process runs just fine. Most well-written services can live exactly like this.

**You pass when:** `chai-31-flag` is running with read-only rootfs, `CapDrop ALL`, an **empty** `CapAdd`, `no-new-privileges` set, and `id -u` inside it returns `65534`.
