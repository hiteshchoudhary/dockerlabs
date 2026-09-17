Bind mounts need an **absolute** host path — a bare name would create a volume instead (silently, with nginx serving 403). From the lab terminal in `workspace/`: `docker run -d --name chai-14-web -p 8014:80 -v "$(pwd)/ch14/site":/usr/share/nginx/html:ro nginx:alpine`. The `:ro` suffix is what makes it read-only.

---

The live-edit step needs no Docker at all — that's the lesson. Open `workspace/ch14/site/index.html` in any editor, replace `edit me` with your own words, save, and `curl -s http://127.0.0.1:8014/`. If curl shows a 403 or the default nginx welcome page, your mount path was wrong: `docker inspect -f '{{json .Mounts}}' chai-14-web` shows what actually got mounted.

---

For the challenge, a container's mounts are fixed at creation — so recreate it with one more flag: `docker rm -f chai-14-web && docker run -d --name chai-14-web -p 8014:80 -v "$(pwd)/ch14/site":/usr/share/nginx/html:ro --tmpfs /cache nginx:alpine`. Test both personalities: `docker exec chai-14-web sh -c 'echo hot > /cache/brew'` (works) vs `docker exec chai-14-web touch /usr/share/nginx/html/x` (read-only file system).
