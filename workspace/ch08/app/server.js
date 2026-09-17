// ChaiCode API v2 — now with a real dependency (`ms`), so the image
// build has an install step worth caching.
const http = require("node:http");
const ms = require("ms");

const PORT = process.env.PORT || 3000;
const started = Date.now();

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      service: "chaicode-api",
      status: "ok",
      uptime: ms(Date.now() - started, { long: true }),
    }) + "\n"
  );
});

server.listen(PORT, () => {
  console.log(`chaicode-api (ch08) listening on port ${PORT}`);
});
