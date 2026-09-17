#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

f="${LAB_WORKSPACE:?}/ch35/api-reply.json"
if [ ! -f "$f" ]; then
  fail "No file at workspace/ch35/api-reply.json. Call the endpoint from a container and redirect the JSON there (see the challenge text)."
fi
pass "workspace/ch35/api-reply.json exists"

check=$(node -e '
const fs = require("fs");
try {
  const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const content = j?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) { console.log("NOCONTENT"); process.exit(0); }
  if (!String(j?.model || "").includes("smollm2")) { console.log("WRONGMODEL:" + (j?.model || "none")); process.exit(0); }
  console.log("OK");
} catch (e) { console.log("BADJSON"); }
' "$f" 2>/dev/null)

case "$check" in
  OK) pass "Valid OpenAI-style response from smollm2 with real content" ;;
  BADJSON) fail "api-reply.json is not valid JSON. Make sure you redirected the raw response body (curl -s ... > ./ch35/api-reply.json) and that the request itself succeeded." ;;
  NOCONTENT) fail "The JSON parsed, but choices[0].message.content is missing or empty. POST to /engines/v1/chat/completions with a messages array — check the hint for the exact body shape." ;;
  WRONGMODEL:*) fail "The response came from '${check#WRONGMODEL:}', not smollm2. Set \"model\":\"ai/smollm2:135M-Q4_K_M\" in the request body." ;;
  *) fail "Couldn't validate api-reply.json (node error). Re-create the file and try again." ;;
esac

celebrate "Challenge complete. Any OpenAI-API app can now run against your machine."
