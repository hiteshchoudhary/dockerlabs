Step 1 is Chapter 4's retag: `docker tag nginx:alpine chai-06-api:v1` (pull `nginx:alpine` first if it's gone). Saving: `docker save` takes the image name and `-o <file>` for the output path — from `workspace/`: `mkdir -p ch06` first.

---

The round-trip, from `workspace/`: `docker save chai-06-api:v1 -o ./ch06/chai-06-api.tar`, then `docker rmi chai-06-api:v1`, then `docker load -i ./ch06/chai-06-api.tar`. Note `rmi` only removed the *name* here — the underlying blobs survived because `nginx:alpine` still points at them (Chapter 4: rmi peels stickers). On a truly blank machine, `load` would carry everything.

---

Challenge: `docker run --name chai-06-box chai-06-api:v1 true` gives you an (exited) container to export — export works fine on stopped containers. Then pipe the two commands together, no temp file needed: `docker export chai-06-box | docker import - chai-06-flat:v1`. Compare with `docker history` and `docker image inspect -f '{{len .RootFS.Layers}}' <image>` on both.
