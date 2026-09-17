#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect mcp/fetch >/dev/null 2>&1; then
  fail "The mcp/fetch image isn't pulled. Run: docker pull mcp/fetch"
fi
pass "Official MCP server image mcp/fetch is present"

f="${LAB_WORKSPACE:?}/ch38/handshake.json"
if [ ! -f "$f" ]; then
  fail "No file at workspace/ch38/handshake.json. Pipe the initialize request into 'docker run -i --rm mcp/fetch' and redirect stdout there (hint 2 has the full pipeline)."
fi
pass "workspace/ch38/handshake.json exists"

check=$(node -e '
const fs = require("fs");
try {
  const raw = fs.readFileSync(process.argv[1], "utf8").trim();
  const j = JSON.parse(raw.split("\n")[0]);
  if (j.jsonrpc !== "2.0") { console.log("NOTJSONRPC"); process.exit(0); }
  if (j.method === "initialize") { console.log("ISREQUEST"); process.exit(0); }
  const si = j?.result?.serverInfo;
  if (!si || typeof si.name !== "string" || !si.name) { console.log("NOSERVERINFO"); process.exit(0); }
  console.log("OK:" + si.name);
} catch (e) { console.log("BADJSON"); }
' "$f" 2>/dev/null)

case "$check" in
  OK:*) pass "It's a JSON-RPC 2.0 response — server identified itself as '${check#OK:}'" ;;
  BADJSON) fail "handshake.json isn't valid JSON. Redirect ONLY stdout to the file (add 2>/dev/null so server logs stay out), and make sure the request JSON was quoted correctly." ;;
  NOTJSONRPC) fail "The file parses but has no \"jsonrpc\":\"2.0\" field — that's not a JSON-RPC message. Save the server's raw reply, unmodified." ;;
  ISREQUEST) fail "You saved the initialize REQUEST, not the server's RESPONSE. The pipe direction matters: printf ... | docker run -i --rm mcp/fetch > file." ;;
  NOSERVERINFO) fail "The response has no result.serverInfo — the handshake didn't complete. Check your request matches the chapter's initialize shape exactly (protocolVersion, capabilities, clientInfo)." ;;
  *) fail "Couldn't validate handshake.json (node error). Re-create the file and try again." ;;
esac

celebrate "Exercise 38.1 complete. You just spoke fluent MCP to a containerized server."
