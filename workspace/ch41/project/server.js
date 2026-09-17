// Chapter 41 scaffold — a deliberately tiny API with zero dependencies.
// The point of this chapter is not the app; it's the environment around it.
const http = require("http");

const port = process.env.PORT || 8041;

http
  .createServer((req, res) => {
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({ chapter: 41, status: "ready", node: process.version }) + "\n");
  })
  .listen(port, () => console.log(`chai-ch41-api listening on :${port}`));
