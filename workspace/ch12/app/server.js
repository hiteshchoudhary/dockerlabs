// ChaiCode API — ship-ready edition. Same zero-dependency server as ch07,
// plus a /health endpoint for Docker's HEALTHCHECK to probe.
// Set FAIL_HEALTH=1 (any non-empty value) to simulate a sick service:
// the app keeps running, but /health starts answering 503.
const http = require("node:http");

const PORT = process.env.PORT || 3000;
const SICK = Boolean(process.env.FAIL_HEALTH);

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    if (SICK) {
      res.writeHead(503, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "failing" }) + "\n");
      return;
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "healthy" }) + "\n");
    return;
  }
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      service: "chaicode-api",
      status: "ok",
      endpoints: ["/", "/health"],
    }) + "\n"
  );
});

server.listen(PORT, () => {
  console.log(`chaicode-api (ch12) listening on port ${PORT}`);
});
