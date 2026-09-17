Pulling explicitly: `docker pull nginx:alpine` and `docker pull nginx:1.25-alpine`. Then `docker images --digests` — note the two rows share a REPOSITORY but nothing else. The `Digest: sha256:...` line at the end of each pull is the fingerprint you'll need later.

---

Retagging is `docker tag <existing> <newname>`: `docker tag nginx:1.25-alpine chai-04-api:pinned`. It's instant because nothing is copied — check `docker images` and you'll see `nginx:1.25-alpine` and `chai-04-api:pinned` with the same IMAGE ID. For the digest file, the surgical route is an inspect template: `docker image inspect -f '{{index .RepoDigests 0}}' chai-04-api:pinned` prints `nginx@sha256:...` — the `sha256:...` part is the digest.

---

Full commands, from `workspace/`: `mkdir -p ch04`, then `docker image inspect -f '{{index .RepoDigests 0}}' chai-04-api:pinned | cut -d@ -f2 > ./ch04/digest.txt` (writing the whole `nginx@sha256:...` string also passes — the verifier looks for the `sha256:` part). Challenge: `docker run -d --name chai-04-digest -p 8004:80 nginx@$(cat ./ch04/digest.txt)` — then `curl http://127.0.0.1:8004`.
