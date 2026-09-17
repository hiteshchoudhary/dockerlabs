# Exercise

**38.1 — Perform the MCP handshake with a containerized server.**

1. Pull the official **`mcp/fetch`** server image from the Docker MCP Catalog.
2. Build an `initialize` request — JSON-RPC 2.0, one line: `method` `"initialize"`, an `id`, and `params` carrying `protocolVersion` `"2024-11-05"`, empty `capabilities`, and a `clientInfo` with your client's name and version (the chapter shows the exact shape).
3. Pipe it into the server — `docker run -i --rm mcp/fetch` — and save the server's JSON-RPC **response** to **`workspace/ch38/handshake.json`** (from `workspace/`: `./ch38/handshake.json`, create the folder if needed). Keep the file clean: protocol only, no stderr noise.

**You pass when:**

- `workspace/ch38/handshake.json` exists and is valid JSON.
- It's a JSON-RPC 2.0 **response** whose `result.serverInfo` identifies the server (a real handshake reply, not the request echoed back).

The verifier reads the file you saved — the state, not the pipeline that produced it. Any client that can write one line and read one line could have done this; that's the point of MCP.
