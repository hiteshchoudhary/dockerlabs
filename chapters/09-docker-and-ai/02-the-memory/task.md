# Exercise

**36.1 — Boot a vector database, store meaning, search it.**

1. Run Qdrant detached from the **`qdrant/qdrant`** image: container named **`chai-36-qdrant`**, REST port `6333` published on host port **`8036`**, and a named volume **`chai-36-data`** mounted at `/qdrant/storage`.
2. Create a collection named **`chai_notes`** via the REST API: vector **size 4**, distance **Cosine**. (Four dimensions is intentional — hand-writable vectors, identical mechanics to 768-d.)
3. Insert **at least 2 points**, each with a 4-number vector and a `payload` containing some text.
4. Run a **search** (`POST /collections/chai_notes/points/search`) with a query vector close to one of your points and confirm the right payload comes back first.

**You pass when:**

- `chai-36-qdrant` is running from the `qdrant/qdrant` image with port `8036` published and volume `chai-36-data` mounted at `/qdrant/storage`.
- `GET http://127.0.0.1:8036/collections/chai_notes` reports the collection (size 4, Cosine).
- The collection holds at least 2 points.
- A nearest-neighbor search against it returns a result.

The verifier probes the live database over HTTP and inspects the container — it never sees your curl commands, only the state they left behind.
