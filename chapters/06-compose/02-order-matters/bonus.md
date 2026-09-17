# Challenge

`depends_on` only guards startup. Give the stack its long-term survival instinct: add a **restart policy** to *both* services so they come back after a crash or a daemon restart — but stay down when you deliberately stop them. (There's exactly one policy with those semantics; the chapter named it.)

Apply it with a single `docker compose up -d` — Compose diffs the file against reality and recreates only what changed.

**You pass when:** both the `db` and `web` containers of project `chai-20` carry the `unless-stopped` restart policy (the verifier reads it straight off `docker inspect`).
