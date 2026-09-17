#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

f="${LAB_WORKSPACE:?}/ch38/mcp-config.json"
if [ ! -f "$f" ]; then
  fail "No file at workspace/ch38/mcp-config.json. Write the client config from the challenge (the chapter shows the exact shape)."
fi
pass "workspace/ch38/mcp-config.json exists"

check=$(node -e '
const fs = require("fs");
try {
  const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const servers = j.mcpServers;
  if (!servers || typeof servers !== "object" || Array.isArray(servers)) { console.log("NOSERVERS"); process.exit(0); }
  for (const [name, s] of Object.entries(servers)) {
    if (!s || s.command !== "docker") continue;
    const a = Array.isArray(s.args) ? s.args : [];
    if (!a.includes("run")) { console.log("NORUN:" + name); process.exit(0); }
    if (!a.includes("-i")) { console.log("NOI:" + name); process.exit(0); }
    if (!a.includes("--rm")) { console.log("NORM:" + name); process.exit(0); }
    if (!a.some(x => typeof x === "string" && x.startsWith("mcp/"))) { console.log("NOIMAGE:" + name); process.exit(0); }
    console.log("OK:" + name); process.exit(0);
  }
  console.log("NODOCKER");
} catch (e) { console.log("BADJSON"); }
' "$f" 2>/dev/null)

case "$check" in
  OK:*) pass "Server '${check#OK:}' is registered as a dockerized MCP server (docker run -i --rm mcp/...)" ;;
  BADJSON) fail "mcp-config.json isn't valid JSON — check for trailing commas or missing quotes (hint 3 shows a checker one-liner)." ;;
  NOSERVERS) fail "The config needs a top-level \"mcpServers\" object mapping server names to launch specs." ;;
  NODOCKER) fail "No server entry launches via \"command\": \"docker\". The client must spawn docker itself — that's what makes the server containerized." ;;
  NORUN:*) fail "Server '${check#NORUN:}': args must include \"run\" — the client literally executes docker with these args." ;;
  NOI:*) fail "Server '${check#NOI:}': args must include \"-i\" — without it stdin closes and JSON-RPC can't flow in." ;;
  NORM:*) fail "Server '${check#NORM:}': args must include \"--rm\" — one throwaway container per session, no corpses." ;;
  NOIMAGE:*) fail "Server '${check#NOIMAGE:}': args must end with a catalog image (something starting with \"mcp/\"), e.g. mcp/fetch." ;;
  *) fail "Couldn't validate mcp-config.json (node error). Re-create the file and try again." ;;
esac

celebrate "Challenge complete. Any MCP client on this machine can now grow a containerized hand."
