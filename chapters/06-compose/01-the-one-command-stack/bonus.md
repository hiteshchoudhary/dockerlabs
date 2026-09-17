# Challenge

One compose file, two independent stacks — the project-name superpower.

First make your published port configurable: in `compose.yaml`, change the host port to the variable form **`"${WEB_PORT:-8019}:80"`** — Compose substitutes `WEB_PORT` from your shell if set, and falls back to `8019` otherwise (full variable story next chapter but one). Re-run `up -d` on `chai-19` and confirm nothing changed.

Then bring up a *second*, completely independent copy of the same stack from the same file: project name **`chai-19-b`** (use `-p` — the `-p` flag beats the `name:` in the file), with `WEB_PORT=8119` so the two web services don't fight over a port.

**You pass when:** project `chai-19-b` has its own running `web` and `redis` containers, `http://localhost:8119` serves the status board — and the original `chai-19` stack is still up on `8019`, untouched.
