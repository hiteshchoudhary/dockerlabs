# The AI Stack

You now hold all three ingredients of a modern GenAI application: a local model with an OpenAI-compatible endpoint (Chapter 35), a vector database that remembers (Chapter 36), and — from Part 6 — the tool that turns a pile of `docker run` commands into a system: Compose. Today they meet. The pattern you'll wire up is the backbone of nearly every "AI app" shipping right now: an **API service** that *retrieves* from a vector DB and *generates* with a model. Strip away the hype and a GenAI stack is just services in a Compose file — which is excellent news, because you've been composing services for ten chapters.

## The service in the middle

Look in `workspace/ch37/api/` — a tiny TutorAI API is scaffolded for you: one `server.js` (plain Node, zero npm dependencies) and a Dockerfile. It's this Part's motivating app in miniature, and it does three things:

1. **On boot**, it seeds a mini knowledge base into Qdrant — a `chai_docs` collection with a few documents as toy 4-d vectors (same trick as last chapter, same identical-at-768-d mechanics). Note *how* it boots: a retry loop that waits for Qdrant to answer. Compose starts services in parallel, and Chapter 20 taught you that `depends_on` orders *starting*, not *readiness* — resilient apps retry.
2. **`GET /ask?q=...`** embeds the question (a toy keyword embedder), searches Qdrant for the nearest documents, and returns them as JSON. That's the *retrieval* half of RAG, live.
3. **If — and only if —** it finds `MODEL_ENDPOINT` and `MODEL_NAME` in its environment, it also sends the retrieved documents plus the question to that endpoint and includes the model's phrased `answer` in the response. The *generation* half, wired through configuration alone.

That last point is Chapter 10's twelve-factor lesson doing real work. The code never hardcodes where the model lives; it reads an env var. Point it at Model Runner today, at Ollama tomorrow, at a paid cloud API in production — same image, zero rebuilds. The OpenAI-compatible protocol is what makes the swap free.

## Composing it

The stack is two services — and one deliberate asymmetry:

```yaml
name: chai-37
services:
  qdrant:
    image: qdrant/qdrant
    container_name: chai-37-qdrant

  api:
    build: ./api
    image: chai-37-api
    container_name: chai-37-api
    ports:
      - "8037:8000"
    environment:
      QDRANT_URL: http://qdrant:6333
    depends_on:
      - qdrant
```

The api reaches Qdrant as `http://qdrant:6333` — service-name DNS on the project network, Part 5's embedded DNS server earning its keep. And notice what has **no `ports:` at all**: the database. Only the api is reachable from the host; Qdrant is private wiring. You proved why in Chapter 18 — a database with a published port is an incident report waiting for a timestamp.

```
$ docker compose up -d --build
$ curl -s 'http://127.0.0.1:8037/ask?q=what+is+docker'
{
  "question": "what is docker",
  "source": "qdrant",
  "hits": [
    { "score": 1.0, "text": "Docker packages an app together with its entire environment." },
    ...
  ]
}
```

A question goes in; the nearest knowledge comes out, served by a vector DB the outside world can't even see.

## Where's the model in the YAML?

The model deliberately isn't a `service:` — Chapter 35 showed why: Model Runner executes weights host-side for hardware acceleration, so there's no container to compose. From inside the project, the endpoint is simply reachable at `http://model-runner.docker.internal/engines/v1`, and our api picks it up via `MODEL_ENDPOINT` — that's the challenge.

Compose is closing this last seam as we write. Newer releases (Compose v2.38+) understand a first-class **`models:`** element:

```yaml
# Requires Docker Compose ≥ v2.38 — on this lab's v2.34 it does NOT
# validate yet, which is why we wire the endpoint manually via environment.
services:
  api:
    models:
      llm:
        endpoint_var: MODEL_ENDPOINT
        model_var: MODEL_NAME
models:
  llm:
    model: ai/smollm2:135M-Q4_K_M
```

Declare the model like a volume, attach it to a service, and Compose pulls it through Model Runner and injects the endpoint URL and model name as env vars of your choosing. Read that twice: it injects *exactly the two env vars our scaffolded api already reads*. The manual `environment:` wiring you'll do in the challenge is byte-for-byte what `models:` automates — learn it by hand once, and the shiny syntax holds no mysteries when your Compose version catches up.

:::notebook What `models:` actually automates
Under the hood the `models:` element is thin, and that's its charm. At `up`, Compose calls the Model Runner API on the host: ensure the model artifact is pulled (same OCI pull as Chapter 35), ensure the inference server is up, then resolve the model's endpoint URL and inject it — plus the model tag — into the attached services' environment (`endpoint_var` / `model_var` name the variables; there are defaults if you omit them). No new network plumbing: containers still reach the endpoint over the existing `model-runner.docker.internal` bridge. It's dependency declaration, not dependency injection magic — which is why apps written the twelve-factor way (base URL from env) adopt it without a single code change, and why apps with hardcoded model URLs can't. Write your AI services like this scaffold and the tooling will keep meeting you halfway.
:::

One stack, one command, a private memory, and a pluggable brain. Compose it.
