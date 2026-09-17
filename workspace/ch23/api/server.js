// ChaiCode API — deliberately dependency-free. It answers /health for its own
// healthcheck, and on any other path reports whether it can reach the db and
// cache over the project network (plain TCP checks — no client libraries).
const http = require("http");
const net = require("net");

const port = process.env.PORT || 3000;
const DB_HOST = process.env.DB_HOST || "db";
const CACHE_HOST = process.env.CACHE_HOST || "cache";

function tcpCheck(host, portNum) {
  return new Promise((resolve) => {
    const sock = net.connect({ host, port: portNum, timeout: 1500 });
    sock.on("connect", () => { sock.end(); resolve("up"); });
    sock.on("error", () => resolve("down"));
    sock.on("timeout", () => { sock.destroy(); resolve("down"); });
  });
}

http
  .createServer(async (req, res) => {
    if (req.url === "/health") {
      res.end("ok\n");
      return;
    }
    const [db, cache] = await Promise.all([
      tcpCheck(DB_HOST, 5432),
      tcpCheck(CACHE_HOST, 6379),
    ]);
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ service: "chaicode-api", db, cache }) + "\n");
  })
  .listen(port, () => console.log(`chaicode-api on ${port}`));
