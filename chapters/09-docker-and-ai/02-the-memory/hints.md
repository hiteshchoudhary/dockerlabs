The run command mirrors the Postgres pattern from Part 4: `docker run -d --name chai-36-qdrant -p 8036:6333 -v chai-36-data:/qdrant/storage qdrant/qdrant`. Confirm it's up with `curl -s http://127.0.0.1:8036/` — you should get a JSON banner with a version.

---

All three API calls are in the chapter, verbatim: `PUT /collections/chai_notes` with body `{"vectors":{"size":4,"distance":"Cosine"}}`, then `PUT /collections/chai_notes/points?wait=true` with a `{"points":[...]}` body (each point: `id`, 4-number `vector`, `payload`), then `POST /collections/chai_notes/points/search` with `{"vector":[...],"limit":1,"with_payload":true}`. Don't forget `-H 'Content-Type: application/json'` on each.

---

Challenge: `docker rm -f chai-36-qdrant`, wait a few seconds, re-run the exact same `docker run` from hint 1 (the volume still exists, so your data is already inside). Get the count: `curl -s -X POST http://127.0.0.1:8036/collections/chai_notes/points/count -H 'Content-Type: application/json' -d '{"exact":true}'` — then write just the number: `echo 2 > ./ch36/survived.txt` (from `workspace/`, with your actual count; `mkdir -p ch36` first).
