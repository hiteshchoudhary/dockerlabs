Creating the wire: `docker network create chai-17-net` (bridge is the default driver). Putting a container on it at birth: add `--network chai-17-net` to `docker run`. And remember the Chapter 3 trick — alpine needs a long-running command like `sleep 3600` or it exits immediately.

---

The two containers: `docker run -d --name chai-17-a --network chai-17-net alpine sleep 3600` (same for `chai-17-b`). Test the DNS yourself before verifying: `docker exec chai-17-a ping -c 2 chai-17-b`. If ping says `bad address`, the container isn't on `chai-17-net` — check with `docker network inspect chai-17-net`.

---

Challenge: `docker run -d --name chai-17-c alpine sleep 3600` (note: no `--network`, so it lands on the default bridge), then patch it in live with `docker network connect chai-17-net chai-17-c`. Unplug with `docker network disconnect chai-17-net chai-17-c`, plug back in, and confirm both networks show under `docker inspect -f '{{json .NetworkSettings.Networks}}' chai-17-c`.
