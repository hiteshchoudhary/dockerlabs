Registry first: `docker run -d --name chai-25-registry -p 8125:5000 registry:2`. Then the builder: `docker buildx create --name chai-25-builder --driver docker-container --driver-opt network=host`. The `network=host` part is what lets the builder container reach `127.0.0.1:8125` — without it the push dies with `connection refused`, because "localhost" inside the builder is the builder.

---

The build (run from `workspace/`): `docker buildx build --builder chai-25-builder --platform linux/amd64,linux/arm64 -t 127.0.0.1:8125/chai-25-api:1.0 --provenance=false --output type=registry,registry.insecure=true ./ch25`. If you used `--push` instead and hit `http: server gave HTTP response to HTTPS client` — that's the point of `--output type=registry,registry.insecure=true`: the builder needs its own permission to speak plain HTTP.

---

Check with `docker buildx imagetools inspect 127.0.0.1:8125/chai-25-api:1.0` — you want two `Platform:` lines. Challenge: `docker pull --platform linux/amd64 127.0.0.1:8125/chai-25-api:1.0`, then `docker run --rm --name chai-25-probe 127.0.0.1:8125/chai-25-api:1.0 > ./ch25/arch.txt` (from `workspace/`). The container prints the arch that was baked at build time: `x86_64`.
