# Exercise

**44.1 — Declare the whole build, run it in one command.**

The scaffold at `workspace/ch44/` holds two trivial Dockerfiles: `Dockerfile.api` and `Dockerfile.worker`. Both accept an `APP_VERSION` build arg. Don't touch them — everything happens in the bake file you write.

1. Create **`workspace/ch44/docker-bake.hcl`** declaring:
   - a group **`default`** whose targets are **`api`** and **`worker`**;
   - target `api`: context `.`, `Dockerfile.api`, tag **`chai-44-api:v1`**;
   - target `worker`: context `.`, `Dockerfile.worker`, tag **`chai-44-worker:v1`**;
   - on **both** targets, the shared build arg `APP_VERSION = "v1"` and the shared label `com.chaicode.project = "chai-44"`.
2. Sanity-check the plan without building: `docker buildx bake --print` (run it in `ch44/`, or point `-f` at the file).
3. Bake the default group — both images build from the single command.

**You pass when:**

- `docker buildx bake --print` resolves your file cleanly, with group `default` containing `api` and `worker`, and each target carrying its `chai-44-*:v1` tag.
- Images `chai-44-api:v1` and `chai-44-worker:v1` exist locally.
- Both images carry the label `com.chaicode.project=chai-44` **and** the label `com.chaicode.version=v1` (that one is set by the Dockerfiles *from your `APP_VERSION` arg* — it proves the arg flowed through).

The verifier resolves your bake file and inspects the built images — which commands produced them is not its business.
