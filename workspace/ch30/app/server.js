// ChaiCode API — chapter 30 edition.
// Deliberately writes to disk at startup: if the container user can't write
// to /app/data, the process crashes immediately. Ownership mistakes in the
// Dockerfile surface here, loudly, instead of hiding until production.
const http = require('http');
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const countFile = path.join(dataDir, 'hits.json');

// This throws (and kills the process) if the current user can't write here.
fs.mkdirSync(dataDir, { recursive: true });
if (!fs.existsSync(countFile)) fs.writeFileSync(countFile, '{"hits":0}');

const server = http.createServer((req, res) => {
  const state = JSON.parse(fs.readFileSync(countFile, 'utf8'));
  state.hits += 1;
  fs.writeFileSync(countFile, JSON.stringify(state));
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify({
    service: 'chai-30-api',
    uid: process.getuid(),
    user: process.env.USER || null,
    hits: state.hits,
  }));
});

server.listen(3000, () => {
  console.log(`chai-30-api listening on 3000 as uid ${process.getuid()}`);
});
