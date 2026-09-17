// TutorAI mini API — Chai aur Docker lab scaffolding (Chapter 37).
// No npm dependencies: plain Node 22 (built-in http + global fetch).
//
// On boot it seeds a tiny knowledge base into Qdrant, then answers:
//   GET /ask?q=<question>  → nearest documents from Qdrant (+ optional LLM answer)
//   GET /healthz           → { ok, seeded }
//
// Config (all via environment — twelve-factor, Chapter 10):
//   QDRANT_URL      where the vector DB lives        (default http://qdrant:6333)
//   MODEL_ENDPOINT  OpenAI-compatible base URL — IF PRESENT, /ask also asks the
//                   LLM to phrase an answer from the retrieved documents
//   MODEL_NAME      model to request from that endpoint

const http = require('http');

const PORT = Number(process.env.PORT || 8000);
const QDRANT_URL = (process.env.QDRANT_URL || 'http://qdrant:6333').replace(/\/$/, '');
const MODEL_ENDPOINT = (process.env.MODEL_ENDPOINT || '').replace(/\/$/, '');
const MODEL_NAME = process.env.MODEL_NAME || '';
const COLLECTION = 'chai_docs';

// The "corpus". Toy 4-d vectors, one axis per topic — Chapter 36 explains
// why the mechanics are identical to real 768-d embeddings.
const DOCS = [
  { id: 1, vector: [1, 0, 0, 0], text: 'Masala chai is brewed with milk, water, ginger and cardamom.' },
  { id: 2, vector: [0, 1, 0, 0], text: 'Docker packages an app together with its entire environment.' },
  { id: 3, vector: [0, 0, 1, 0], text: 'Qdrant stores vectors and finds the nearest ones by meaning.' },
  { id: 4, vector: [0, 0, 0, 1], text: 'Compose boots a whole multi-service stack with one command.' },
];

// Toy "embedding model": bucket keywords onto the 4 axes.
function embed(question) {
  const s = String(question || '').toLowerCase();
  const v = [
    /chai|tea|ginger|cardamom|brew/.test(s) ? 1 : 0,
    /docker|container|image|ship/.test(s) ? 1 : 0,
    /vector|qdrant|search|memory|embed/.test(s) ? 1 : 0,
    /compose|stack|service|boot/.test(s) ? 1 : 0,
  ];
  return v.some(Boolean) ? v : [0.5, 0.5, 0.5, 0.5];
}

let seeded = false;

async function seed() {
  await fetch(`${QDRANT_URL}/collections/${COLLECTION}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ vectors: { size: 4, distance: 'Cosine' } }),
  });
  const res = await fetch(`${QDRANT_URL}/collections/${COLLECTION}/points?wait=true`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      points: DOCS.map((d) => ({ id: d.id, vector: d.vector, payload: { text: d.text } })),
    }),
  });
  if (!res.ok) throw new Error(`qdrant upsert failed: HTTP ${res.status}`);
  seeded = true;
  console.log(`seeded ${DOCS.length} documents into ${QDRANT_URL}/${COLLECTION}`);
}

// Retry until Qdrant is reachable — containers in a stack start in parallel.
(async function seedLoop() {
  for (;;) {
    try { await seed(); return; }
    catch (e) { console.log(`waiting for qdrant (${e.message}) ...`); }
    await new Promise((r) => setTimeout(r, 2000));
  }
})();

async function retrieve(question) {
  const res = await fetch(`${QDRANT_URL}/collections/${COLLECTION}/points/search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ vector: embed(question), limit: 2, with_payload: true }),
  });
  if (!res.ok) throw new Error(`qdrant search failed: HTTP ${res.status}`);
  const json = await res.json();
  return (json.result || []).map((p) => ({ score: p.score, text: p.payload?.text || '' }));
}

async function generate(question, hits) {
  const context = hits.map((h) => `- ${h.text}`).join('\n');
  const res = await fetch(`${MODEL_ENDPOINT}/chat/completions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    signal: AbortSignal.timeout(30000),
    body: JSON.stringify({
      model: MODEL_NAME,
      max_tokens: 100,
      messages: [
        { role: 'system', content: 'Answer in one short sentence using ONLY the provided notes.' },
        { role: 'user', content: `Notes:\n${context}\n\nQuestion: ${question}` },
      ],
    }),
  });
  if (!res.ok) throw new Error(`model endpoint failed: HTTP ${res.status}`);
  const json = await res.json();
  return json.choices?.[0]?.message?.content?.trim() || null;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const send = (code, body) => {
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body, null, 2) + '\n');
  };

  try {
    if (url.pathname === '/healthz') return send(200, { ok: true, seeded });
    if (url.pathname === '/ask') {
      if (!seeded) return send(503, { error: 'still seeding qdrant — try again in a moment' });
      const question = url.searchParams.get('q') || 'what is docker?';
      const hits = await retrieve(question);
      const body = { question, source: 'qdrant', hits };
      if (MODEL_ENDPOINT && MODEL_NAME) {
        try { body.answer = await generate(question, hits); }
        catch (e) { body.answer = null; body.model_error = e.message; }
      }
      return send(200, body);
    }
    return send(404, { error: 'try GET /ask?q=... or GET /healthz' });
  } catch (e) {
    return send(500, { error: e.message });
  }
});

server.listen(PORT, () => {
  console.log(`tutorai api listening on :${PORT}`);
  console.log(`qdrant: ${QDRANT_URL}`);
  console.log(MODEL_ENDPOINT ? `model: ${MODEL_NAME} via ${MODEL_ENDPOINT}` : 'model: not wired (set MODEL_ENDPOINT + MODEL_NAME)');
});
