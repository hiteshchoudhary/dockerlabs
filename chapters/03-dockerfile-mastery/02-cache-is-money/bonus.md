# Challenge

`.dockerignore` isn't just about speed — it's your first line of defense against shipping secrets. Anything that enters the build context can end up in a layer, and layers can be read by anyone who gets the image.

1. Create a fake credentials file **`workspace/ch08/app/secret.env`** with any content (e.g. `API_KEY=super-secret-chai`).
2. Extend your `.dockerignore` so it never enters the build context (`secret.env` or a `*.env` pattern).
3. Rebuild **`chai-08-api:v1`** — `COPY . .` now copies "everything"… except what the ignore file vetoes.

**You pass when:** `secret.env` exists on your host, your `.dockerignore` covers it, and a probe of the image shows `server.js` made it in while `secret.env` did **not**.
