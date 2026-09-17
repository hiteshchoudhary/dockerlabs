#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

DC="${LAB_WORKSPACE:?}/ch41/project/.devcontainer/devcontainer.json"
if [ ! -f "$DC" ]; then
  fail "No devcontainer.json at workspace/ch41/project/.devcontainer/ — finish the main exercise first."
fi

result=$(node -e '
const fs = require("fs");
let s = fs.readFileSync(process.argv[1], "utf8");
s = s.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|[^:"])\/\/.*$/gm, "$1");
s = s.replace(/,\s*([}\]])/g, "$1");
let j;
try { j = JSON.parse(s); } catch (e) { console.log("PARSE: " + e.message); process.exit(0); }
if (!j.image && !j.build) { console.log("MISS: image (or build) vanished — keep the exercise fields intact"); process.exit(0); }
if (!j.features || typeof j.features !== "object" || Array.isArray(j.features)) { console.log("NOFEAT"); process.exit(0); }
const keys = Object.keys(j.features);
if (keys.length === 0) { console.log("EMPTY"); process.exit(0); }
console.log("OK: " + keys.join(", "));
' "$DC" 2>&1)

case "$result" in
  OK:*)
    pass "features declared: ${result#OK: }"
    ;;
  PARSE:*) fail "devcontainer.json no longer parses: ${result#PARSE: } — fix the JSON syntax." ;;
  NOFEAT) fail "No 'features' object in devcontainer.json. Add e.g. \"features\": { \"ghcr.io/devcontainers/features/git:1\": {} }" ;;
  EMPTY) fail "'features' is present but empty — declare at least one feature entry." ;;
  MISS:*) fail "${result#MISS: }." ;;
  *) fail "Couldn't validate devcontainer.json ($result)." ;;
esac

celebrate "Challenge complete. Reusable tooling, declared — not scripted by hand."
