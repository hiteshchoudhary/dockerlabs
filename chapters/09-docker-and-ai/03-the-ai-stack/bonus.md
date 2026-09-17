# Challenge

Give the stack its brain. Add two environment variables to the **api** service and re-`up`:

```
MODEL_ENDPOINT: http://model-runner.docker.internal/engines/v1
MODEL_NAME: ai/smollm2:135M-Q4_K_M
```

The scaffolded code already knows what to do when they're present: `/ask` will retrieve from Qdrant *and* have the local model phrase an `answer` from the retrieved notes — the full RAG loop, running entirely on your laptop. (This manual wiring is exactly what the `models:` element automates on Compose ≥ v2.38.)

**You pass when:** the running `chai-37-api` container has `MODEL_ENDPOINT` in its environment, and `GET /ask?q=...` returns a non-empty `answer` field alongside the Qdrant hits.
