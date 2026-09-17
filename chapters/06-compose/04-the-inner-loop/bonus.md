# Challenge

A sync rule can't install dependencies. Add a **second watch rule** to `web`: `action: rebuild`, watching **`./app/package.json`** — so a dependency change triggers the full build-and-recreate path instead of a useless file copy.

If you still have `docker compose watch` running, prove it: `touch app/package.json` and watch it rebuild instead of sync.

**You pass when:** `web`'s resolved config carries both rules — the sync rule from the exercise *and* a rebuild rule whose path ends in `package.json`.
