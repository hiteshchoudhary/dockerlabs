# Exercise

**9.1 — Build a CLI-style tool image: fixed executable, swappable arguments.**

1. Look at `workspace/ch09/greet.sh` — it prints `chai says:` plus whatever arguments it gets.
2. Create a `Dockerfile` in `workspace/ch09/` that:
   - starts `FROM alpine`,
   - copies `greet.sh` to **`/usr/local/bin/greet`** and makes it executable (`RUN chmod +x ...`),
   - sets `ENTRYPOINT` to that executable — **exec form** (JSON array),
   - sets `CMD` to the single default argument **`namaste`** — also exec form.
3. Build it as **`chai-09-tool:v1`**.
4. Drive it like a binary:
   ```
   $ docker run --rm chai-09-tool:v1
   chai says: namaste
   $ docker run --rm chai-09-tool:v1 fresh chai
   chai says: fresh chai
   ```

**You pass when:**

- Image **`chai-09-tool:v1`** exists.
- Its `.Config.Entrypoint` and `.Config.Cmd` are both **exec form** — real JSON arrays, no smuggled `/bin/sh -c`.
- Run with no arguments, it prints `chai says: namaste`.
- Run with arguments (e.g. `fresh chai`), it prints them instead of the default.

The verifier builds nothing and reads no history — it inspects your image's config and runs two throwaway probes against it, so any Dockerfile with this exact behavior passes.
