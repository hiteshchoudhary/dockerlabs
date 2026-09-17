Build in order: network first (`docker network create chai-18-net`), then the three containers, each with `--network chai-18-net`. Only the api gets a `-p`; the db and cache get none — that absence IS the exercise. Postgres needs `-e POSTGRES_PASSWORD=chai` or it exits immediately (check `docker logs chai-18-db` if it does).

---

The db and api, spelled out: `docker run -d --name chai-18-db --network chai-18-net -e POSTGRES_PASSWORD=chai postgres:16-alpine` and `docker run -d --name chai-18-api --network chai-18-net -p 8018:80 nginx:alpine`. Test the inside wiring with `docker exec chai-18-api nc -z -w 2 chai-18-db 5432` (exit code 0 = reachable — nginx:alpine ships BusyBox `nc`). Postgres takes a few seconds to start listening; if the probe fails, wait and retry.

---

Cache: `docker run -d --name chai-18-cache --network chai-18-net redis:alpine`. If you accidentally published a port on db or cache, recreate the container without the `-p` — bindings can't be removed from an existing container. Challenge: `docker run -d --name chai-18-lonely --network none alpine sleep 3600`, then `docker exec chai-18-lonely ping -c 1 8.8.8.8` to watch it fail.
