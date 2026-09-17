# Challenge

Build-time is half the story — now deliver the secret at **run time**, the file way, and keep env clean.

Run a container named **`chai-32-app`** from your `chai-32-api:v1`, publishing host port **8032** to container port 3000, with the token delivered as a **read-only bind mount** at the conventional path **`/run/secrets/apitoken`** — and *no* token anywhere in the container's environment.

`server.js` already knows the convention: hit `curl localhost:8032` and it reports `secretLoaded: true` plus the token's sha256 fingerprint (never the token). Note the two fingerprints in the response — build-time and run-time — match: same secret, delivered twice, kept zero times.

**You pass when:** `chai-32-app` is running from `chai-32-api:v1`; the API on 8032 reports `secretLoaded: true` with the correct fingerprint; the mount at `/run/secrets/apitoken` is read-only; and no environment variable in the container carries the token value.
