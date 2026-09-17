Start from the compose skeleton printed in the chapter — it's complete for the main exercise. Save it as `workspace/ch37/compose.yaml`, then from `workspace/ch37/`: `docker compose up -d --build`. Check what's running with `docker compose ps`.

---

If `/ask` errors: `docker compose logs api` tells the story. "waiting for qdrant" lines are normal for the first seconds; a `503 still seeding` reply means ask again in a moment. If you see connection refused instead, check the api's `QDRANT_URL` is `http://qdrant:6333` — service name, internal port, no published port needed (containers talk on the project network, not through the host).

---

Challenge: add under the api service —
```yaml
    environment:
      QDRANT_URL: http://qdrant:6333
      MODEL_ENDPOINT: http://model-runner.docker.internal/engines/v1
      MODEL_NAME: ai/smollm2:135M-Q4_K_M
```
then `docker compose up -d` again (Compose recreates only what changed). Verify with `docker exec chai-37-api env | grep MODEL` and re-curl `/ask` — the smollm2 model must be pulled (Chapter 35) and Model Runner running.
