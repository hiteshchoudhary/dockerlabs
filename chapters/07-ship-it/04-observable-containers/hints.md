Log options are `docker run` flags: `--log-driver json-file --log-opt max-size=1m --log-opt max-file=3`, stacked before the image name. Log config can't be changed on a live container — if you got it wrong, `docker rm -f chai-27-app` and run again.

---

Full run: `docker run -d --name chai-27-app --log-driver json-file --log-opt max-size=1m --log-opt max-file=3 alpine sh -c 'i=0; while true; do echo "tick $i"; i=$((i+1)); sleep 1; done'`. Check with `docker logs --tail 5 chai-27-app` and `docker inspect -f '{{json .HostConfig.LogConfig}}' chai-27-app`.

---

Challenge, in order: `docker stop chai-27-app`, then `docker start chai-27-app`, then `mkdir -p ch27 && docker events --since 10m --until 0s --filter container=chai-27-app > ./ch27/events.txt` (from `workspace/`). The `--until 0s` means "up to right now" — that's what makes `events` return instead of streaming forever.
