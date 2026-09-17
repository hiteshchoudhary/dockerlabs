# Exercise

**32.1 — Build with a secret the image never keeps.**

The scaffold is in **`workspace/ch32`**: `token.txt` (the "API token"), `install-deps.sh` (dies without the token; records its sha256 fingerprint to `/app/token.fingerprint`), and `server.js` (listens on 3000).

1. Write a `Dockerfile` in `workspace/ch32` that:
   - starts from `node:22-alpine` with `WORKDIR /app`,
   - copies in **only** `server.js` and `install-deps.sh` — the token file must never be COPYed,
   - runs `sh ./install-deps.sh` with the token supplied as a **BuildKit secret mount** (id **`apitoken`**),
   - starts the server with `node server.js`.
2. Build it as **`chai-32-api:v1`**, passing `token.txt` as the secret. If you see the script's FATAL error, the secret mount isn't wired up yet — that's the script refusing to build a half-configured image.
3. Audit your own image the way an attacker would: `docker history --no-trunc chai-32-api:v1`, and `docker run --rm chai-32-api:v1 env`. The token should appear in neither.

**You pass when:**

- Image `chai-32-api:v1` exists.
- The token value appears nowhere in `docker history` output and in no image environment variable.
- A throwaway probe of the image finds `/run/secrets` empty (the mount left no trace) and no `APITOKEN`-style variable at runtime.
- `/app/token.fingerprint` inside the image matches the sha256 of `workspace/ch32/token.txt` — cryptographic proof the secret really was there during the build.

The verifier never watches your build command — it interrogates the finished image, exactly like an auditor who only gets the artifact.
