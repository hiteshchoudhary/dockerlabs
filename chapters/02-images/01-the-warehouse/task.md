# Exercise

**4.1 — Pull two variants, retag the pinned one, record its fingerprint.**

1. **Pull two different tags** of the nginx image: the floating **`nginx:alpine`** and the version-pinned **`nginx:1.25-alpine`**. Compare them with `docker images --digests` — same repository, different digests, different images.
2. **Retag** the pinned one: give `nginx:1.25-alpine` the additional name **`chai-04-api:pinned`**. Confirm with `docker images` that both names share one IMAGE ID — no copy was made.
3. **Record the digest** of that image into **`workspace/ch04/digest.txt`** — the file should contain its `sha256:...` digest (the lab terminal opens in `workspace/`, so the path from there is `./ch04/digest.txt`; create the folder if needed). You can read the digest off the pull output, `docker images --digests`, or an `inspect` template.

**You pass when:**

- Both `nginx:alpine` and `nginx:1.25-alpine` are present locally.
- An image named **`chai-04-api:pinned`** exists and is the *same image* as `nginx:1.25-alpine` (identical ID — retagged, not rebuilt).
- `workspace/ch04/digest.txt` contains that image's real digest (the verifier resolves the digest itself and compares).

The verifier reads Docker's state and your file — it has no idea which commands produced them, so take any route you like.
