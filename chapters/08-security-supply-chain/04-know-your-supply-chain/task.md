# Exercise

**33.1 — Pin the base by digest, for real.**

1. Pull `alpine` and extract its **repo digest** from your local image store (the chapter shows the exact `inspect` template).
2. Write a `Dockerfile` in **`workspace/ch33`** that:
   - starts `FROM` alpine **pinned by that digest** (`alpine@sha256:...` — the tag-plus-digest form is fine too),
   - carries an OCI title label: `org.opencontainers.image.title="chai-33-api"`,
   - has a `CMD` that keeps the container alive if run (e.g. a long sleep — nobody can re-point *your* base now, might as well let the container nap).
3. Build it as **`chai-33-api:v1`**.

**You pass when:**

- `workspace/ch33/Dockerfile` exists and its `FROM` line contains a real `@sha256:` digest.
- That digest is genuinely alpine's — it matches an alpine repo digest present on this machine (a made-up digest can't pass; content addressing doesn't negotiate).
- Image `chai-33-api:v1` exists and its bottom layer is byte-identical to that pinned base's — proof the build really stood on the digest you named.

No commands are checked — only the Dockerfile's pin and the resulting image's ancestry.
