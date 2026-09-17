# Exercise

**37.1 — Compose the GenAI stack.**

The api service is scaffolded in `workspace/ch37/api/` (read `server.js` — it's short and it's the whole lesson). Your job is the Compose file.

1. Create **`workspace/ch37/compose.yaml`** defining the project **`chai-37`** (use the top-level `name:`) with two services:
   - **`qdrant`** from the **`qdrant/qdrant`** image, container named **`chai-37-qdrant`**, and **no published ports** — the database stays private.
   - **`api`** built from `./api`, image tagged **`chai-37-api`**, container named **`chai-37-api`**, its port `8000` published on host port **`8037`**, and `QDRANT_URL=http://qdrant:6333` in its environment.
2. Bring the stack up (build included) with one command.
3. Ask it something: `curl 'http://127.0.0.1:8037/ask?q=what+is+docker'` — you should get JSON with `hits` retrieved from Qdrant. (First seconds after boot it may answer `503 still seeding` — that's the retry loop doing its job; ask again.)

**You pass when:**

- Both containers are running and belong to the Compose project `chai-37`.
- The api answers on host port `8037`; the qdrant container has no host port at all.
- `GET /ask?q=...` returns JSON with `"source": "qdrant"` and at least one hit with text.

The verifier checks the running stack and the HTTP behavior — any compose.yaml that produces that state is a correct compose.yaml.
