// ChaiCode landing page server — reads public/index.html on EVERY request,
// so files synced into the container show up instantly, no restart needed.
const http = require("http");
const fs = require("fs");
const path = require("path");

const port = process.env.PORT || 3000;
const publicDir = path.join(__dirname, "public");

http
  .createServer((req, res) => {
    const file = path.join(publicDir, "index.html");
    fs.readFile(file, (err, html) => {
      if (err) {
        res.statusCode = 500;
        res.end("public/index.html missing\n");
        return;
      }
      res.setHeader("content-type", "text/html; charset=utf-8");
      res.end(html);
    });
  })
  .listen(port, () => console.log(`chaicode landing on ${port}`));
