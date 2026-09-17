# Challenge

3 AM. Version 2.0 is the suspect. You know what to do — the same ritual, pointing backward.

Roll **`chai-29-app`** back to **`127.0.0.1:8129/chai-29-app:1.0`**: stop, remove, run the old tag on the same port. No new machinery — that's the point of the symmetry.

Then leave a note for the morning team (every 3 AM action gets written down): put the exact image reference you rolled back to into **`workspace/ch29/rollback.txt`** —

```
docker inspect -f '{{.Config.Image}}' chai-29-app > ./ch29/rollback.txt
```

**You pass when:** `chai-29-app` is running from the `:1.0` tag, `http://127.0.0.1:8029/` answers with the `version 1.0` marker, and `rollback.txt` records the `:1.0` reference the container is actually running.
