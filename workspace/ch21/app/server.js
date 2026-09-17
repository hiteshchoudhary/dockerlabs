// ChaiCode config echo — a tiny server whose whole personality comes from env.
// It has no config file on purpose: same image everywhere, environment decides.
const http = require("http");

const port = process.env.PORT || 3000;

http
  .createServer((req, res) => {
    res.setHeader("content-type", "application/json");
    res.end(
      JSON.stringify({
        service: "chaicode-web",
        message: process.env.CHAI_MESSAGE || "(CHAI_MESSAGE not set)",
        mode: process.env.CHAI_MODE || "(CHAI_MODE not set)",
      }) + "\n"
    );
  })
  .listen(port, () => {
    console.log(
      `chaicode-web listening on ${port} in '${process.env.CHAI_MODE || "?"}' mode`
    );
  });
