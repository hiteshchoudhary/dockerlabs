# Exercise

**25.1 — Build one tag that runs on amd64 and arm64.**

1. Run a registry for this chapter: **`chai-25-registry`** from `registry:2`, detached, published on host port **`8125`**.
2. Create a buildx builder named exactly **`chai-25-builder`** using the `docker-container` driver, with host networking (`--driver-opt network=host`) so it can reach your loopback registry.
3. From `workspace/` (build context `./ch25`), run a single `docker buildx build` for **both** `linux/amd64` **and** `linux/arm64`, tagged **`127.0.0.1:8125/chai-25-api:1.0`**, pushed straight to the registry from the builder (`--output type=registry,registry.insecure=true` — the builder doesn't share the daemon's loopback trust). Add `--provenance=false` to keep the manifest list clean.
4. Read your work back: `docker buildx imagetools inspect 127.0.0.1:8125/chai-25-api:1.0` should list both platforms under one tag.

**You pass when:**

- `chai-25-registry` is running and answering on port `8125`, with `chai-25-api` in its catalog.
- The manifest list for `127.0.0.1:8125/chai-25-api:1.0` contains **both** `linux/amd64` and `linux/arm64`.

However you assemble it, the verifier only interrogates the registry's manifest list — the artifact is the proof.
