Build the command incrementally and let the crashes guide you: start with `docker run -d --name chai-31-app -p 8031:80 --read-only nginx:alpine`, then `docker logs chai-31-app` names the directory nginx couldn't write. Add a `--tmpfs <that-path>` for each complaint (there are two: `/var/cache/nginx` and `/run`), removing the failed container (`docker rm -f chai-31-app`) between attempts.

---

Capabilities next: add `--cap-drop ALL --cap-add CHOWN --cap-add SETGID --cap-add SETUID`. If you want to see *why* those three, try with fewer and read the `[emerg]` line in the logs — nginx literally names the failing operation (`chown(...) Operation not permitted`). Then bolt on `--security-opt no-new-privileges` and `--pids-limit 100`.

---

The full command: `docker run -d --name chai-31-app -p 8031:80 --read-only --tmpfs /var/cache/nginx --tmpfs /run --cap-drop ALL --cap-add CHOWN --cap-add SETGID --cap-add SETUID --security-opt no-new-privileges --pids-limit 100 nginx:alpine`. Challenge: `docker run -d --name chai-31-flag --user 65534:65534 --read-only --cap-drop ALL --security-opt no-new-privileges alpine sleep 3600` — note there's no `--cap-add` at all.
