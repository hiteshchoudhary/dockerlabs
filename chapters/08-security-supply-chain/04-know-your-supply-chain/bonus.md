# Challenge

Ship the image **with its evidence attached**: SBOM and provenance attestations, pushed to your own registry, inspected with your own eyes.

1. Run a local registry container **`chai-33-registry`** (`registry:2`) publishing port **8133**.
2. Create a buildx builder named **`chai-33-builder`** (docker-container driver) that can push plain HTTP to it — you need **host networking** and the provided **`workspace/ch33/buildkitd.toml`** config (this is the Chapter 25 insecure-registry dance).
3. Rebuild the chapter's image with that builder, with **`--sbom=true --provenance=true`**, tagged **`localhost:8133/chai-33-api:signed`**, and `--push` it.
4. Look at what you shipped: `docker buildx imagetools inspect localhost:8133/chai-33-api:signed` — find the `unknown/unknown` manifest from the chapter's notebook, annotated as an attestation. Dig out the documents themselves with `--format '{{ json .SBOM }}'` and `'{{ json .Provenance }}'`.

**You pass when:** the registry is up on 8133, and `localhost:8133/chai-33-api:signed` carries an attestation manifest with a non-empty SBOM (SPDX) and SLSA provenance — verified straight from the registry, exactly as a downstream consumer would.
