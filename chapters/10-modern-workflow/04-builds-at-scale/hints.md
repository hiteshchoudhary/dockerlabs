The bake file's shape is in the chapter — `group "default" { targets = [...] }` plus two `target "..." { }` blocks. Keys you need: `context`, `dockerfile`, `tags` (a list), `args` (a map), `labels` (a map, keys quoted because of the dots). Save it as `ch44/docker-bake.hcl` — bake finds it by name.

---

Run everything from inside `ch44/` (`cd ch44`): `docker buildx bake --print` to see the resolved JSON plan, then `docker buildx bake` to build both targets in parallel. Check the result: `docker image inspect -f '{{.Config.Labels}}' chai-44-api:v1` should show both `com.chaicode.project` and `com.chaicode.version`.

---

Challenge shape — a `target "common"` block containing only the shared lines (`args = { APP_VERSION = "v1" }` on one line, `labels = { "com.chaicode.project" = "chai-44", "com.chaicode.built-with" = "bake" }` on the next) — then in `api`/`worker`: `inherits = ["common"]` and delete their own `args`/`labels`. Keep `default`'s targets as just `["api", "worker"]`, re-run `docker buildx bake`, and the new label lands on both images.
