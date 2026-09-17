# Challenge

Tags can move; you just recorded a name that can't. Prove you can use it.

Run a **detached** container named **`chai-04-digest`** from the nginx image referenced **purely by digest** — the reference form `nginx@sha256:...`, using the exact digest you recorded in `digest.txt` — publishing container port `80` on host port **`8004`**. No tag anywhere in the image reference: this is how production systems that must never drift specify images.

**You pass when:** `chai-04-digest` is running, its image reference is in `@sha256:` digest form matching the digest you recorded, and `http://127.0.0.1:8004` answers.
