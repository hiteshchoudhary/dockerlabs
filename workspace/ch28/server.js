// Chapter 28 — the world's smallest identifiable API.
// Every response names the machine that served it, which is exactly
// what you need to SEE load-balancing happen.
const http = require('http');
const os = require('os');

const port = process.env.PORT || 3000;

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(`hello from ${os.hostname()}\n`);
}).listen(port, () => {
  console.log(`chai-28 api ready on :${port} (hostname: ${os.hostname()})`);
});
