The file lives at `workspace/ch41/project/.devcontainer/devcontainer.json` — note the leading dot on the folder. Start from the example in the chapter: `image`, `forwardPorts` (an array of numbers — `[8041]`), `postCreateCommand` (a string), `customizations` (an object). Plain JSON is safest.

---

The container is ordinary Docker: `docker run -d --name chai-41-dev -v <absolute-path-to-project>:/workspaces/project -w /workspaces/project node:22-alpine sleep infinity`. The lab terminal opens in `workspace/`, so the absolute path is `"$PWD/ch41/project"`. If the name is taken from an earlier attempt: `docker rm -f chai-41-dev`.

---

Prove the toolchain: `docker exec chai-41-dev node --version` — it should print a version even if your host has no Node at all. For the challenge, add a top-level `"features": { "ghcr.io/devcontainers/features/git:1": {} }` to the JSON (no rebuild needed here — the verifier checks the declaration statically).
