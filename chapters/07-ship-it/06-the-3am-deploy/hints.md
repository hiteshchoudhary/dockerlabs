Registry: `docker run -d --name chai-29-registry -p 8129:5000 registry:2`. The two releases are the same build command with different `--build-arg` and tag: `docker build --build-arg APP_VERSION=1.0 -t 127.0.0.1:8129/chai-29-app:1.0 ./ch29` then `docker push` it; repeat with `2.0`. Verify the history: `curl http://127.0.0.1:8129/v2/chai-29-app/tags/list`.

---

Deploy v1: `docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0`. The upgrade ritual, in order: `docker pull 127.0.0.1:8129/chai-29-app:2.0` (fetch while v1 still serves), `docker stop chai-29-app`, `docker rm chai-29-app`, then `docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:2.0`. Check both truths agree: `curl http://127.0.0.1:8029/` and `docker inspect -f '{{.Config.Image}}' chai-29-app`.

---

Rollback is the identical ritual with the old tag: stop, rm, `docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0` (it's still local — pull is instant anyway). Then the morning note, from `workspace/`: `docker inspect -f '{{.Config.Image}}' chai-29-app > ./ch29/rollback.txt`.
