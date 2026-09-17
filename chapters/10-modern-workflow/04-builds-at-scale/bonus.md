# Challenge

Your bake file says `APP_VERSION` and `com.chaicode.project` twice. In a real platform with a dozen targets, that duplication is where drift is born. Refactor with **inheritance**:

1. Add a base target (call it **`common`**) holding everything shared: the `APP_VERSION` arg, the `com.chaicode.project` label — plus one *new* shared label: `com.chaicode.built-with = "bake"`.
2. Make `api` and `worker` pull it in with `inherits = ["common"]`, keeping only their own dockerfile and tags.
3. Re-bake, so both images pick up the new shared label.

(Tip: `common` is scaffolding, not a real build — leave it out of the `default` group. `docker buildx bake --print` shows you the resolved result of the inheritance before you build.)

**You pass when:** the bake file uses `inherits`, still resolves cleanly with both tagged targets in group `default`, and both freshly-baked images carry `com.chaicode.built-with=bake` alongside the exercise labels.
