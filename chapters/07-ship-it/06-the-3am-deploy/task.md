# Exercise

**29.1 — Release two versions, deploy one, upgrade by replacement.**

1. Run this chapter's registry: **`chai-29-registry`** from `registry:2`, detached, published on host port **`8129`**.
2. Release **v1**: build `workspace/ch29/` (context `./ch29`) with `--build-arg APP_VERSION=1.0`, tagged **`127.0.0.1:8129/chai-29-app:1.0`**, and push it.
3. Release **v2**: same build with `APP_VERSION=2.0`, tagged **`127.0.0.1:8129/chai-29-app:2.0`**, and push it. The registry now holds your whole version history — check `/v2/chai-29-app/tags/list`.
4. Deploy v1: run **`chai-29-app`** detached from the `:1.0` registry tag, published on host port **`8029`**. Confirm: `curl http://127.0.0.1:8029/` answers `chai-29-app version 1.0`.
5. Upgrade to v2 **by the ritual** — `pull → stop → rm → run` with the `:2.0` tag. Do not modify the running container; replace it. Same name, same port, new artifact.

**You pass when:**

- The registry on `8129` lists **both** tags `1.0` and `2.0` for `chai-29-app`.
- A container named `chai-29-app` is running from `127.0.0.1:8129/chai-29-app:2.0`.
- `http://127.0.0.1:8029/` answers with the `version 2.0` marker — the config and the response telling the same story.
- (Once you've done the challenge's rollback, the verifier also accepts the `:1.0` deployment — provided its morning note exists and the response still matches the tag.)

The verifier inspects the deployed state and interrogates the live service; the ritual leaves exactly the evidence it checks.
