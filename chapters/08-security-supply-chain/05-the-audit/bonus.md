# Challenge

One finding remains open: the "partner integration" needs its key (**`workspace/ch34/partner.key`**) inside the container — and the auditor will scan your environment variables for anything that smells like a secret.

Re-run **`chai-34-api`** with all of the exercise's hardening **plus** the key delivered the Chapter 32 way:

- the key file **read-only bind-mounted** at **`/run/secrets/partner.key`**,
- the environment carrying only the **pointer** — `PARTNER_KEY_FILE=/run/secrets/partner.key` (`_FILE` convention: env may hold a *path*, never a *value*).

`curl localhost:8034` should flip to `partnerKeyLoaded: true` and report the key's sha256 fingerprint — the server already speaks the convention.

**You pass when:** the audited container (still passing everything in 34.1) additionally has the key mounted read-only at `/run/secrets/partner.key`, the API reports the correct fingerprint, and the env scan comes back clean — no variable carries the key value, and nothing secret-named appears except `_FILE` pointers.
