# Challenge

Version 1.0.0 is live. Ship the book's final release: **1.0.1**.

The api's Dockerfile takes a build argument for exactly this moment (`ARG APP_VERSION` — Chapter 10's build-time knob, baked into the image as env):

1. Build the new release from the same source, with the new version stamped in:

   ```
   docker build -t 127.0.0.1:8146/chai-46-api:1.0.1 --build-arg APP_VERSION=1.0.1 ../ch45/api
   ```

2. Push it. The push takes about a second — every layer except the tiny changed one already sits in the registry.
3. Upgrade the running platform the immutable way (Chapter 29): edit `compose.registry.yaml` so the api service says `1.0.1`, then `docker compose -f compose.registry.yaml up -d --wait`. Compose recreates *only* the api — nothing else moves, and the data doesn't blink.

**You pass when:** the registry serves `chai-46-api:1.0.1`, the running api container's image is exactly **`127.0.0.1:8146/chai-46-api:1.0.1`**, and `/api/status` reports `"version": "1.0.1"` — the new release, answering live, pulled from your own registry. That's the last green check in the book. Make it count.
