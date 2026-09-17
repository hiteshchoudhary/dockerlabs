// ChaiCode platform API — zero dependencies, Node stdlib only.
//
// Endpoints:
//   GET /health      → instant liveness answer (no dependency checks)
//   GET /api/status  → readiness: actually connects to db, cache and qdrant
//
// The dependency checks are real connections, not pings-of-faith:
//   db     → speaks the Postgres wire protocol (StartupMessage → expects
//            an Authentication request back)
//   cache  → speaks RESP (sends PING, expects +PONG)
//   qdrant → HTTP GET / (expects 200)
'use strict';

const http = require('http');
const net = require('net');

const PORT = parseInt(process.env.PORT || '3000', 10);
const VERSION = process.env.APP_VERSION || 'dev';

const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = parseInt(process.env.DB_PORT || '5432', 10);
const DB_USER = process.env.DB_USER || 'chai';
const DB_NAME = process.env.DB_NAME || 'chaicode';
const CACHE_HOST = process.env.CACHE_HOST || 'cache';
const CACHE_PORT = parseInt(process.env.CACHE_PORT || '6379', 10);
const QDRANT_HOST = process.env.QDRANT_HOST || 'qdrant';
const QDRANT_PORT = parseInt(process.env.QDRANT_PORT || '6333', 10);

const TIMEOUT_MS = 2000;

// Postgres: open a TCP socket and send a protocol-3 StartupMessage.
// A live Postgres answers with an Authentication request ('R', 0x52).
function checkPostgres() {
  return new Promise((resolve) => {
    const sock = net.connect({ host: DB_HOST, port: DB_PORT });
    const done = (v) => { sock.destroy(); resolve(v); };
    sock.setTimeout(TIMEOUT_MS, () => done('timeout'));
    sock.on('error', () => done('unreachable'));
    sock.on('connect', () => {
      const params = `user\0${DB_USER}\0database\0${DB_NAME}\0\0`;
      const body = Buffer.concat([
        Buffer.from([0x00, 0x03, 0x00, 0x00]), // protocol version 3.0
        Buffer.from(params, 'utf8'),
      ]);
      const msg = Buffer.alloc(4 + body.length);
      msg.writeInt32BE(4 + body.length, 0);
      body.copy(msg, 4);
      sock.write(msg);
    });
    sock.once('data', (buf) => done(buf[0] === 0x52 ? 'connected' : 'error'));
  });
}

// Redis: send PING over RESP, expect +PONG.
function checkRedis() {
  return new Promise((resolve) => {
    const sock = net.connect({ host: CACHE_HOST, port: CACHE_PORT });
    const done = (v) => { sock.destroy(); resolve(v); };
    sock.setTimeout(TIMEOUT_MS, () => done('timeout'));
    sock.on('error', () => done('unreachable'));
    sock.on('connect', () => sock.write('PING\r\n'));
    sock.once('data', (buf) => done(buf.toString().startsWith('+PONG') ? 'connected' : 'error'));
  });
}

// Qdrant: plain HTTP — its root endpoint answers 200 with version info.
function checkQdrant() {
  return new Promise((resolve) => {
    const req = http.get(
      { host: QDRANT_HOST, port: QDRANT_PORT, path: '/', timeout: TIMEOUT_MS },
      (res) => { res.resume(); resolve(res.statusCode === 200 ? 'connected' : 'error'); }
    );
    req.on('timeout', () => { req.destroy(); resolve('timeout'); });
    req.on('error', () => resolve('unreachable'));
  });
}

const server = http.createServer(async (req, res) => {
  const url = (req.url || '/').split('?')[0];

  if (url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', version: VERSION }));
    return;
  }

  if (url === '/api/status') {
    const [db, cache, qdrant] = await Promise.all([
      checkPostgres(), checkRedis(), checkQdrant(),
    ]);
    const allUp = db === 'connected' && cache === 'connected' && qdrant === 'connected';
    res.writeHead(allUp ? 200 : 503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(
      { service: 'chaicode-api', version: VERSION, db, cache, qdrant },
      null, 2
    ));
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not found', try: ['/health', '/api/status'] }));
});

server.listen(PORT, () => {
  console.log(`chaicode-api ${VERSION} listening on :${PORT}`);
});

// Behave like a good PID 1: exit promptly on stop signals (Chapter 2, Chapter 9).
process.on('SIGTERM', () => server.close(() => process.exit(0)));
process.on('SIGINT', () => process.exit(0));
