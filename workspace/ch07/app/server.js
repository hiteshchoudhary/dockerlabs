// ChaiCode API — the app you're about to containerize.
// Zero dependencies: Node's built-in http module only.
const http = require("node:http");
const os = require("node:os");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      service: "chaicode-api",
      status: "ok",
      hostname: os.hostname(),
      node: process.version,
    }) + "\n"
  );
});

server.listen(PORT, () => {
  console.log(`chaicode-api listening on port ${PORT}`);
});
