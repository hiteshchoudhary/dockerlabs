# Exercise

**35.1 — Pull a model, run it, keep the receipt.**

1. Confirm Model Runner is up with `docker model status`.
2. Pull the model **`ai/smollm2:135M-Q4_K_M`** (~100 MB — the smallest model that can hold a conversation).
3. Run a **one-shot prompt** against it with `docker model run` — ask it anything you like ("Explain in one sentence why chai is better with ginger" is a classic) — and save the model's reply to **`workspace/ch35/reply.txt`** (the lab terminal opens in `workspace/`, so from there: `./ch35/reply.txt` — create the folder if needed).

**You pass when:**

- Model Runner answers `docker model status`.
- `docker model list` shows an `ai/smollm2` model.
- `workspace/ch35/reply.txt` exists and contains a real reply (more than 20 characters of actual text).

As always, the verifier looks at the state you leave behind — the model in the list, the file on disk — not at how you produced it.
