# Exercise

**14.1 — Serve a page from a bind mount, then edit it live.**

1. Look at the scaffolding in **`workspace/ch14/site/`** — an `index.html` containing the placeholder text `edit me`.
2. Run a detached container named exactly **`chai-14-web`** from the **`nginx:alpine`** image:
   - publish host port **`8014`** to container port `80`,
   - bind-mount the host directory `workspace/ch14/site/` (absolute path — from the lab terminal in `workspace/`, use `"$(pwd)/ch14/site"`) **read-only** at **`/usr/share/nginx/html`**.
3. `curl -s http://127.0.0.1:8014/` — you should get the scaffold page, `edit me` and all.
4. Now the point of the chapter: **edit `workspace/ch14/site/index.html` on the host** — replace `edit me` with a message of your own — and curl again. The container serves your new text immediately. No rebuild, no restart, no docker command at all.

**You pass when:**

- `chai-14-web` is running from `nginx:alpine`.
- `/usr/share/nginx/html` is a **bind** mount of your `ch14/site` directory, and it is **read-only**.
- The placeholder `edit me` is gone from the file — you actually edited it.
- The page served on port `8014` is byte-for-byte the current content of `index.html` on your host — proof the mount is live, not a copy.

The verifier compares live Docker and HTTP state against the file on disk; it doesn't watch what you type, and it never edits the file for you.
