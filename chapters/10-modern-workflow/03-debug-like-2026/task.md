# Exercise

**43.1 — Build a sealed box, prove it's sealed, debug it anyway.**

The scaffold at `workspace/ch43/` has a tiny Go API (`main.go`), its `go.mod`, and a multi-stage `Dockerfile` that compiles a static binary and ships it on `scratch`.

1. **Build** the image **`chai-43-api:v1`** from `workspace/ch43/`.
2. **Run** it detached as **`chai-43-api`**, publishing host port **8043** to container port 8043. Confirm `http://localhost:8043/` answers.
3. **Prove there's no way in.** Try to exec a shell in it. It will fail — capture that failure message to **`workspace/ch43/noshell.txt`**. Depending on the Docker version the message arrives on stdout *or* stderr, so capture both: `> file 2>&1`.
4. **Debug it from outside.** Without any shell, extract what PID 1 actually is: use `docker inspect` to read the container's entrypoint binary path, and write it to **`workspace/ch43/findings.txt`** as a single line in this form:
   ```
   entrypoint=<the binary path>
   ```

**You pass when:**

- Image `chai-43-api:v1` exists, is tiny (under 20 MB), and has at most 2 layers — proof the toolchain stayed in the build stage.
- Container `chai-43-api` is running from that image and answers on port 8043.
- `noshell.txt` contains the runtime's "executable file not found" failure.
- `findings.txt`'s `entrypoint=` line matches what the container is genuinely running (the verifier asks Docker itself and compares).

As always, the verifier examines images, containers, and files — the route you took is invisible to it.
