# Exercise

**21.1 — One stack, configured from the outside.**

Scaffolding is in `workspace/ch21/` — an `app/` folder with a tiny server (it answers with JSON echoing its `CHAI_MESSAGE` and `CHAI_MODE` environment) and its Dockerfile. Work in `workspace/ch21/`; you'll create three files.

1. **`.env`** — sets `CHAI_MODE=dev`. This feeds compose-file substitution, not the container.
2. **`web.env`** — sets `CHAI_MESSAGE=chai is ready`. This one goes into the container.
3. **`compose.yaml`** — project name **`chai-21`**, two services:
   - **`web`** — `build: ./app`, publishing host port **`8021`** to container port `3000`. Wire its config both ways: `env_file: web.env` for the message, and an `environment:` entry `CHAI_MODE: ${CHAI_MODE:-prod}` so the mode is substituted from your `.env` (defaulting to `prod` anywhere the file is missing).
   - **`debug`** — image **`alpine`**, command `sleep infinity`, behind the profile **`debug`**. A plain `up` must not start it.
4. Bring the stack up detached (build included) — *without* the profile. Then check your wiring: `curl http://localhost:8021/` should say the message and mode, and `docker compose config` should show both values resolved.

**You pass when:**

- `.env` defines `CHAI_MODE=dev` and `web.env` defines `CHAI_MESSAGE=chai is ready`.
- The resolved compose config gives `web` both values, and shows `debug` only when the profile is activated.
- The `web` container (project `chai-21`) is running and `http://localhost:8021` answers with `"message":"chai is ready"` and `"mode":"dev"`.

State is what's judged — the verifier reads your files, the resolved config, and the live HTTP answer, not your terminal.
