# Challenge

Now prove the *other* half of the lesson: files outside the volume really do die with the container.

1. In your running **`chai-13-db`**, write a file at exactly **`/doomed.txt`** (any content). That path is on the writable layer — `/var/lib/postgresql/data` is the only directory backed by your volume.
2. Capture the evidence: save the output of `docker diff chai-13-db` to **`workspace/ch13/diff.txt`** (from the lab terminal in `workspace/`: `mkdir -p ch13 && docker diff chai-13-db > ./ch13/diff.txt`). Look for the `A /doomed.txt` line — the writable layer confessing.
3. Run the incident once more: `docker rm -f chai-13-db`, then start a fresh **`chai-13-db`** with the **`chai-13-pgdata`** volume again.

**You pass when:** `workspace/ch13/diff.txt` records that `/doomed.txt` was added to a container's writable layer, the current `chai-13-db` no longer has that file — and the `incident` row is still alive in the volume.
