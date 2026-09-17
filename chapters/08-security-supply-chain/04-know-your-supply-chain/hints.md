Fetch the digest: `docker pull alpine`, then `docker image inspect -f '{{index .RepoDigests 0}}' alpine` — the output (`alpine@sha256:...`) is literally your FROM line. The Dockerfile only needs three lines: that FROM, the `LABEL org.opencontainers.image.title="chai-33-api"`, and something like `CMD ["sleep", "3600"]`. Build from `workspace/ch33`: `docker build -t chai-33-api:v1 .`

---

Challenge setup: `docker run -d --name chai-33-registry -p 8133:5000 registry:2`, then `docker buildx create --name chai-33-builder --driver docker-container --driver-opt network=host --config ch33/buildkitd.toml` (from `workspace/`). Without the config, the push fails with "http: server gave HTTP response to HTTPS client" — that error message IS the reason the toml exists.

---

The attested push, from `workspace/`: `docker buildx build --builder chai-33-builder --sbom=true --provenance=true -t localhost:8133/chai-33-api:signed --push ch33`. Then `docker buildx imagetools inspect localhost:8133/chai-33-api:signed` — the `unknown/unknown` entry annotated `attestation-manifest` is your evidence riding in the index. `--format '{{ json .SBOM }}'` prints the SPDX document itself.
