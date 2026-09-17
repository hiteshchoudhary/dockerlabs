# Challenge

Now the `ARG` side of the divide: a build-time value, baked into permanent metadata, absent at runtime — the way CI pipelines stamp images with the commit that built them.

Extend your Dockerfile with:

- an **`ARG BUILD_ID`** (near the bottom, so it never busts your cache-friendly layers),
- a **`LABEL org.opencontainers.image.version=$BUILD_ID`** that bakes it in.

Then build a second tag, **`chai-10-api:stamped`**, passing any non-empty stamp you like via `--build-arg BUILD_ID=...` (a date, a pretend git SHA, `chai-2026-07-13` — your call).

**You pass when:** the image **`chai-10-api:stamped`** carries a non-empty `org.opencontainers.image.version` label, **and** `BUILD_ID` appears nowhere in the image's runtime environment — proof that `ARG` steered the build and then evaporated.
