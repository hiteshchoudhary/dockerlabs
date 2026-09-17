// ChaiCode API — chapter 32 edition.
// Reads its secret from a FILE at request time (the runtime pattern), never
// from an environment variable. Reports fingerprints, never the secret itself.
const http = require('http');
const fs = require('fs');
const crypto = require('crypto');

const SECRET_PATH = '/run/secrets/apitoken';
const BUILD_FINGERPRINT_PATH = '/app/token.fingerprint';

const sha256 = (buf) => crypto.createHash('sha256').update(buf).digest('hex');

const server = http.createServer((req, res) => {
  let fingerprint = null;
  try {
    fingerprint = sha256(fs.readFileSync(SECRET_PATH));
  } catch {
    // no runtime secret mounted — that's a reportable condition, not a crash
  }
  let buildFingerprint = null;
  try {
    buildFingerprint = fs.readFileSync(BUILD_FINGERPRINT_PATH, 'utf8').trim();
  } catch {}

  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify({
    service: 'chai-32-api',
    secretLoaded: fingerprint !== null,
    fingerprint,
    buildFingerprint,
  }));
});

server.listen(3000, () => console.log('chai-32-api listening on 3000'));
