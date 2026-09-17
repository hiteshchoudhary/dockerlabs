The initialize request is printed in full in the chapter — it's one line of JSON. `printf '%s\n' '<that json>'` produces it; the single quotes around the JSON matter because it's full of double quotes. `-i` keeps stdin open (Chapter 3); no `-t` — a pseudo-TTY would corrupt the machine-to-machine stream.

---

Full pipeline, from `workspace/`:
```
mkdir -p ch38
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"chai-lab","version":"1.0.0"}}}' \
  | docker run -i --rm mcp/fetch > ./ch38/handshake.json 2>/dev/null
```
The `2>/dev/null` keeps any server logs (stderr) out of your file; only stdout — the protocol — is redirected. `cat ./ch38/handshake.json` should show a response with `"result"` in it.

---

Challenge — the config is literally the chapter's example. Save as `workspace/ch38/mcp-config.json`:
```json
{
  "mcpServers": {
    "fetch": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "mcp/fetch"]
    }
  }
}
```
Check your JSON parses: `node -e 'JSON.parse(require("fs").readFileSync("./ch38/mcp-config.json"))' && echo ok`
