# Exercise

**24.1 — Run a registry, then ship an image to it.**

1. Run the registry image `registry:2` as a **detached** container named exactly **`chai-24-registry`**, with its port `5000` published on host port **`8124`**.
2. Build the tiny image in `workspace/ch24/` (the lab terminal opens in `workspace/`, so the build context is `./ch24`) and name it **`chai-24-api:1.0`**.
3. Give the image its shipping name: tag it as **`127.0.0.1:8124/chai-24-api:1.0`** — remember, the registry address travels inside the name.
4. Push it, then ask the registry itself what it holds: `curl http://127.0.0.1:8124/v2/_catalog` and `curl http://127.0.0.1:8124/v2/chai-24-api/tags/list` should both mention your image.

**You pass when:**

- `chai-24-registry` is running from the `registry:2` image, published on host port `8124`.
- The registry's catalog lists `chai-24-api`.
- The registry reports tag `1.0` for `chai-24-api`.
- A local image named `127.0.0.1:8124/chai-24-api:1.0` exists.

The verifier looks only at the state you leave behind — a running registry with your artifact inside — never at which commands got you there.
