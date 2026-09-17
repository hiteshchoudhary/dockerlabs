// ChaiCode API — twelve-factor edition. One image, many behaviors:
// everything environment-specific comes from process.env at RUNTIME.
const http = require("node:http");

const PORT = process.env.PORT || 3000;
const MODE = process.env.MODE || "unset";

const messages = {
  demo: "Demo mode: sample data, verbose errors, nothing here is real.",
  prod: "Prod mode: real data, terse errors, every request counts.",
};

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      service: "chaicode-api",
      mode: MODE,
      message: messages[MODE] || `No behavior defined for mode '${MODE}'.`,
    }) + "\n"
  );
});

server.listen(PORT, () => {
  console.log(`chaicode-api starting in '${MODE}' mode on port ${PORT}`);
});
