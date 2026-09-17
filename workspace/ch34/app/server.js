// ChaiCode API — chapter 34 (audit) edition.
// Stateless by design: writes nothing, so it runs happily on a read-only
// rootfs. Secrets arrive as files via the _FILE pointer convention; the API
// reports fingerprints, never values.
const http = require('http');
const fs = require('fs');
const crypto = require('crypto');

const sha256 = (buf) => crypto.createHash('sha256').update(buf).digest('hex');

const server = http.createServer((req, res) => {
  res.setHeader('content-type', 'application/json');

  if (req.url === '/healthz') {
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  let partnerKeyFingerprint = null;
  const keyPath = process.env.PARTNER_KEY_FILE;
  if (keyPath) {
    try {
      partnerKeyFingerprint = sha256(fs.readFileSync(keyPath));
    } catch {
      // pointer set but file missing — report it, don't crash
    }
  }

  res.end(JSON.stringify({
    service: 'chai-34-api',
    uid: process.getuid(),
    partnerKeyLoaded: partnerKeyFingerprint !== null,
    partnerKeyFingerprint,
  }));
});

server.listen(3000, () => {
  console.log(`chai-34-api listening on 3000 as uid ${process.getuid()}`);
});
