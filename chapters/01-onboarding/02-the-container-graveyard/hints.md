Detached mode is the `-d` flag: `docker run -d --name chai-02-web nginx`. Confirm it's running with `docker ps`. The junk container: `docker run --name chai-02-junk alpine` — it exits instantly because alpine's default command has nothing to do.

---

The lifecycle verbs: `docker stop chai-02-web` then `docker start chai-02-web` — or both at once with `docker restart chai-02-web`. Wait a few seconds after the initial `run` before cycling, so the timestamps clearly differ. Remove the junk with `docker rm chai-02-junk`.

---

Full sequence: `docker run -d --name chai-02-web nginx` → wait ~5s → `docker restart chai-02-web` → `docker run --name chai-02-junk alpine` → `docker rm chai-02-junk`. Challenge: `docker run --name chai-02-crash alpine sh -c "exit 7"` — then `docker inspect -f '{{.State.ExitCode}}' chai-02-crash`.
