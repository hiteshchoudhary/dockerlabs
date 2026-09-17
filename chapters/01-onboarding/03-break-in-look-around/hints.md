Keep alpine alive by giving it a long command: `docker run -d --name chai-03-box alpine sleep 3600`. Confirm with `docker ps` — STATUS should say "Up".

---

Creating the file inside: `docker exec chai-03-box sh -c 'mkdir -p /app && echo "all systems go" > /app/status.txt'` — the `sh -c` wrapper matters, because the redirect (`>`) must happen *inside* the container, not in your host shell. Verify your work: `docker exec chai-03-box cat /app/status.txt`.

---

Extract: `mkdir -p ch03 && docker cp chai-03-box:/app/status.txt ./ch03/status.txt` (run from `workspace/`). Challenge: `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' chai-03-box > ./ch03/ip.txt`
