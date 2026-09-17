# The Memory

The model from last chapter has a problem you can't fine-tune away: it knows nothing about *your* data. Ask smollm2 about your course notes, your product docs, your students' past mistakes — it will confidently invent an answer, because none of that was in its training set. Models don't have memory. Memory is something you bolt on, and the industry-standard bolt is a **vector database**.

## Embeddings: meaning as coordinates

Everything starts with one idea. An **embedding** is a piece of text converted into a list of numbers — a vector — by an embedding model, such that *texts with similar meaning land close together* in that space. "How do I brew chai?" and "tea preparation steps" produce nearby vectors; "kernel namespaces" lands far away from both. Real embedding models output hundreds of dimensions (384, 768, 1536 are common), but the property is the only thing that matters: **distance ≈ meaning**.

That property turns search on its head. Keyword search finds documents that share your *words*; vector search finds documents that share your *meaning*, even with zero words in common. And once meaning is geometry, "what do I know about X?" becomes a nearest-neighbor query.

A **vector database** is a database built for exactly that query: store millions of vectors (each carrying a **payload** — the original text and any metadata), and answer "give me the k nearest vectors to this one" in milliseconds. We'll use **Qdrant** — open source, first-class REST API, and shipped, naturally, as a container.

## RAG, in one paragraph

This is the architecture powering most "chat with your data" products, and it's called **RAG — Retrieval-Augmented Generation**. Index time: split your documents into chunks, embed each chunk, store vector + text in the vector DB. Question time: embed the *question*, ask the DB for the nearest chunks, then hand those chunks to the LLM as context — "answer using only this." The model stops guessing and starts citing. That's it. No retraining, and updating the model's "knowledge" is just a database write. The model reasons; the database remembers. Next chapter we compose the two; today we build the memory.

## Running the memory

Qdrant is a stateful service, and Part 4 taught you what that means: the data must outlive the container, so it gets a **named volume**. Qdrant keeps everything under `/qdrant/storage` and serves REST on port `6333`:

```
$ docker run -d --name chai-36-qdrant \
    -p 8036:6333 \
    -v chai-36-data:/qdrant/storage \
    qdrant/qdrant
$ curl -s http://127.0.0.1:8036/
{"title":"qdrant - vector search engine","version":"1.18.2",...}
```

A database that speaks plain HTTP — every operation below is a `curl` away. Vectors live in **collections** (Qdrant's tables). Creating one pins down two things up front: the vector **size** (every vector in the collection must have exactly that many dimensions — it's the shape of the space) and the **distance metric** (how "near" is measured; **Cosine** — angle between vectors — is the usual choice for text):

```
$ curl -X PUT http://127.0.0.1:8036/collections/chai_notes \
    -H 'Content-Type: application/json' \
    -d '{"vectors":{"size":4,"distance":"Cosine"}}'
{"result":true,"status":"ok"}
```

Size *four*? Deliberate. Real embeddings need an embedding model to produce them, which would bury the database mechanics under model plumbing. So this chapter uses toy 4-dimensional vectors we can write by hand and reason about by eye — and here's the important sentence: **the API calls you're about to make are byte-for-byte identical at 768 dimensions.** Only the length of the number list changes. Learn the mechanics in 4-d, deploy them in 768-d.

Insert points — each an `id`, a `vector`, and a `payload`:

```
$ curl -X PUT 'http://127.0.0.1:8036/collections/chai_notes/points?wait=true' \
    -H 'Content-Type: application/json' \
    -d '{"points":[
      {"id":1,"vector":[0.9,0.1,0.0,0.0],"payload":{"text":"masala chai needs ginger and cardamom"}},
      {"id":2,"vector":[0.0,0.9,0.1,0.0],"payload":{"text":"docker volumes outlive containers"}}
    ]}'
{"result":{"operation_id":0,"status":"completed"},"status":"ok"}
```

(`wait=true` blocks until the write is durable — handy in scripts.) Now the payoff query — *search*. Hand Qdrant a vector, get back the nearest stored points, best first:

```
$ curl -X POST http://127.0.0.1:8036/collections/chai_notes/points/search \
    -H 'Content-Type: application/json' \
    -d '{"vector":[0.85,0.15,0.0,0.0],"limit":1,"with_payload":true}'
{"result":[{"id":1,"score":0.997,"payload":{"text":"masala chai needs ginger and cardamom"}}]}
```

The query vector `[0.85,0.15,0,0]` points *almost* the same direction as point 1 — cosine score 0.997, nearly identical meaning. In production, that query vector would be the embedding of a user's question, and the payload text coming back is exactly what you'd paste into the LLM's context. You've just executed the R in RAG.

:::notebook Why a dedicated database — and where the speed comes from
Couldn't you store vectors in Postgres and loop over them? At a thousand vectors, sure. At fifty million, comparing your query against *every* vector per search is game over. Vector DBs use approximate nearest-neighbor indexes — Qdrant's default is **HNSW** (Hierarchical Navigable Small World): a multi-layer graph where each search hops from a sparse top layer down to dense lower ones, homing in on the neighborhood in logarithmic-ish time and skipping almost all of the data. The trade is in the name — *approximate*: a tuned index very occasionally misses the true nearest neighbor, and that's the accepted price of millisecond search at scale. This index lives in the files under `/qdrant/storage` — which is why the volume you attached isn't a nicety. Lose it, and re-embedding your entire corpus is the bill (real embedding runs cost real money and hours). Postgres people, before you object: yes, `pgvector` exists and is excellent — the concept transfers; the lesson stands.
:::

One more habit from Part 4 worth re-arming here: the container is disposable, the volume is not. Prove it to yourself in the challenge — kill the container, start a fresh one on the same volume, and watch your vectors greet you like nothing happened.

Time to give your stack a memory.
