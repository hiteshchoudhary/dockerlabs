Build and run from `workspace/`: `docker build -t chai-43-api:v1 ./ch43` then `docker run -d --name chai-43-api -p 8043:8043 chai-43-api:v1`. Check it: `curl localhost:8043` — you should get a small JSON answer.

---

Capturing the sealed-box proof: `docker exec chai-43-api sh > ./ch43/noshell.txt 2>&1` — the OCI runtime's complaint lands on stdout or stderr depending on the Docker version, so grab both. For the findings: the entrypoint binary is in inspect's JSON — `docker inspect -f '{{.Path}}' chai-43-api` prints exactly the path PID 1 was started from. Write the line: `echo "entrypoint=$(docker inspect -f '{{.Path}}' chai-43-api)" > ./ch43/findings.txt`.

---

Challenge — join the target's network namespace, so the probe's localhost becomes the container's localhost: `docker run --rm --network container:chai-43-api busybox wget -qO- http://127.0.0.1:9090/ > ./ch43/probe.txt`. Port 9090 is reachable only from inside that namespace; your host's 9090 has nobody listening.
