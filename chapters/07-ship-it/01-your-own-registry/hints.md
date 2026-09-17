The registry is just a container: `docker run -d --name chai-24-registry -p 8124:5000 registry:2`. Test it's alive before anything else: `curl http://127.0.0.1:8124/v2/_catalog` should answer `{"repositories":[]}`. Then build from the scaffold: `docker build -t chai-24-api:1.0 ./ch24` (from `workspace/`).

---

There's no destination flag on `docker push` — the destination is baked into the name. `docker tag chai-24-api:1.0 127.0.0.1:8124/chai-24-api:1.0` creates the alias (same image ID, check with `docker images`), then `docker push 127.0.0.1:8124/chai-24-api:1.0`. No login needed: Docker allows plain HTTP for `127.0.0.1`.

---

Challenge: `docker rmi chai-24-api:1.0 127.0.0.1:8124/chai-24-api:1.0`, then `docker pull 127.0.0.1:8124/chai-24-api:1.0`, then `docker tag 127.0.0.1:8124/chai-24-api:1.0 chai-24-api:roundtrip`. Compare `docker image inspect -f '{{.RepoDigests}}' chai-24-api:roundtrip` with `curl -sI -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' http://127.0.0.1:8124/v2/chai-24-api/manifests/1.0 | grep -i docker-content-digest`.
