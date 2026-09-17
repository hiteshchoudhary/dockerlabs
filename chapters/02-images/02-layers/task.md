# Exercise

**5.1 — Build an image by hand (once, so you never do it again).**

1. Run a long-lived **detached** container named **`chai-05-lab`** from the `alpine` image (remember Chapter 3: give it something to do, or it exits instantly).
2. Modify its filesystem from the inside: create the file **`/app/build-info.txt`** containing exactly:
   ```
   assembled by hand
   ```
   Every byte of that change is landing in the container's writable layer — the image below is untouched.
3. Freeze that writable layer: `docker commit` the container as **`chai-05-snapshot:v1`**.
4. Look at the scar: run `docker history chai-05-snapshot:v1` and compare it with `docker history alpine`. One extra layer, and its CREATED BY says nothing useful about what you did — that's the trap, seen up close.

**You pass when:**

- An image named **`chai-05-snapshot:v1`** exists.
- A container started from it has `/app/build-info.txt` saying `assembled by hand` (the verifier launches its own throwaway probe to check).
- The image is alpine's layers plus at least one commit-created layer on top — not something a Dockerfile build produced.

As always, the verifier only examines the resulting images and files — the path you take to produce them is yours.
