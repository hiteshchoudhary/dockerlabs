# Challenge

Pushing is only half of shipping — now prove the round trip loses nothing.

Pull `127.0.0.1:8124/chai-24-api:1.0` back from your registry (a `docker rmi` of the local copies first makes it a *real* pull), then give the pulled image a new local alias: **`chai-24-api:roundtrip`**.

Then compare identities yourself: `docker image inspect -f '{{.RepoDigests}}' chai-24-api:roundtrip` versus the digest the registry reports (`curl -sI` the manifest URL with an `Accept: application/vnd.docker.distribution.manifest.v2+json` header and read the `Docker-Content-Digest` response header). Same `sha256` — the tag names changed twice, the bytes never did.

**You pass when:** an image named `chai-24-api:roundtrip` exists locally and its repo digest matches the digest the registry reports for `chai-24-api:1.0` — the verifier compares them for real.
