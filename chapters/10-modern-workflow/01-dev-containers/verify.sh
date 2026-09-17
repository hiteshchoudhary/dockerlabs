#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

DC="${LAB_WORKSPACE:?}/ch41/project/.devcontainer/devcontainer.json"
if [ ! -f "$DC" ]; then
  fail "No devcontainer.json at workspace/ch41/project/.devcontainer/ — create the .devcontainer folder (leading dot) and the JSON file inside it."
fi
pass "devcontainer.json exists"

# devcontainer.json may legally contain comments/trailing commas (JSONC) — strip, then parse.
result=$(node -e '
const fs = require("fs");
let s = fs.readFileSync(process.argv[1], "utf8");
s = s.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|[^:"])\/\/.*$/gm, "$1");
s = s.replace(/,\s*([}\]])/g, "$1");
let j;
try { j = JSON.parse(s); } catch (e) { console.log("PARSE: " + e.message); process.exit(0); }
const miss = [];
if (!j.image && !j.build) miss.push("image (or build)");
if (!Array.isArray(j.forwardPorts) || !j.forwardPorts.includes(8041)) miss.push("forwardPorts including 8041");
if (!j.postCreateCommand) miss.push("postCreateCommand");
if (!j.customizations || typeof j.customizations !== "object") miss.push("customizations");
console.log(miss.length ? "MISS: " + miss.join(" | ") : "OK");
' "$DC" 2>&1)

case "$result" in
  OK) pass "All four core fields present (image/build, forwardPorts→8041, postCreateCommand, customizations)" ;;
  PARSE:*) fail "devcontainer.json doesn't parse: ${result#PARSE: } — fix the JSON syntax." ;;
  MISS:*) fail "devcontainer.json is missing/wrong: ${result#MISS: }. Add the field(s) shown in the chapter example." ;;
  *) fail "Couldn't validate devcontainer.json ($result). Is the file valid JSON?" ;;
esac

if ! docker container inspect chai-41-dev >/dev/null 2>&1; then
  fail "No container named 'chai-41-dev'. Start the dev container yourself: docker run -d --name chai-41-dev -v \"\$PWD/ch41/project:/workspaces/project\" node:22-alpine sleep infinity"
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-41-dev)
if [ "$state" = "running" ]; then
  pass "Container 'chai-41-dev' is running"
else
  fail "chai-41-dev is '$state' — it must idle, not exit. Recreate it with a do-nothing command like: sleep infinity"
fi

mounts=$(docker container inspect -f '{{range .Mounts}}{{.Type}} {{.Source}}{{"\n"}}{{end}}' chai-41-dev)
if echo "$mounts" | grep -Eq '^bind .*ch41/project/?$'; then
  pass "The project folder is bind-mounted into the container"
else
  fail "chai-41-dev has no bind mount from workspace/ch41/project. Recreate it with -v \"\$PWD/ch41/project:/workspaces/project\" (absolute host path required)."
fi

nodever=$(docker exec chai-41-dev node --version 2>/dev/null)
case "$nodever" in
  v*) pass "node --version inside the container answers: $nodever" ;;
  *) fail "Running node --version inside chai-41-dev failed — use a Node-capable image (e.g. node:22-alpine) for the dev container." ;;
esac

celebrate "Exercise 41.1 complete. Humans and agents now get the same machine."
