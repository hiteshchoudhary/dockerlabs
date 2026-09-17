# Challenge

Give the container some deliberately forgetful storage: recreate **`chai-14-web`** with everything from the exercise intact (same name, same port, same read-only bind mount) **plus a tmpfs mount at `/cache`**.

Prove to yourself what you built: `docker exec chai-14-web sh -c 'echo hot > /cache/brew'` succeeds (RAM-backed, writable) while `docker exec chai-14-web touch /usr/share/nginx/html/x` is refused (read-only bind mount). Then check `docker inspect -f '{{json .Mounts}}' chai-14-web` — one `bind`, one `tmpfs`, each with the right flags.

**You pass when:** `chai-14-web` has a tmpfs mount at `/cache` that a process inside can write to — while the html bind mount is still there and still read-only (the main exercise must stay green).
