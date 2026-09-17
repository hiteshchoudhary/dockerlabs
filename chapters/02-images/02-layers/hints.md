Steps 1–2 are Chapter 3 skills: `docker run -d --name chai-05-lab alpine sleep 3600`, then `docker exec chai-05-lab sh -c 'mkdir -p /app && echo "assembled by hand" > /app/build-info.txt'` (the `sh -c` wrapper keeps the redirect inside the container).

---

The commit is `docker commit <container> <image:tag>`: `docker commit chai-05-lab chai-05-snapshot:v1`. Sanity-check your frozen layer with a throwaway container: `docker run --rm chai-05-snapshot:v1 cat /app/build-info.txt`. For the comparison, `docker history chai-05-snapshot:v1` — the top row is your writable layer, frozen.

---

Challenge: list each image's layer digests with `docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' <image>`. Alpine has a single layer and the snapshot's list starts with that same digest, so the intersection is that one line. Scripted, from `workspace/`: `mkdir -p ch05` then `comm -12 <(docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' alpine | sort) <(docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' chai-05-snapshot:v1 | sort) > ./ch05/shared-layers.txt` — or just copy the shared digest into the file by hand.
