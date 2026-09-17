#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

BAKE="${LAB_WORKSPACE:?}/ch44/docker-bake.hcl"
if [ ! -f "$BAKE" ]; then
  fail "No workspace/ch44/docker-bake.hcl — write the bake file next to the two Dockerfiles."
fi
pass "docker-bake.hcl exists"

# JSON goes to stdout; buildx progress noise goes to stderr — keep them apart.
plan=$( (cd "${LAB_WORKSPACE}/ch44" && docker buildx bake --print) 2>/dev/null )
if [ $? -ne 0 ] || [ -z "$plan" ]; then
  err=$( (cd "${LAB_WORKSPACE}/ch44" && docker buildx bake --print) 2>&1 >/dev/null | tail -3 | tr '\n' ' ' )
  fail "docker buildx bake --print can't resolve the file: ${err:-unknown error} — fix the HCL and retry."
fi
pass "bake --print resolves the file"

result=$(echo "$plan" | node -e '
let s = "";
process.stdin.on("data", d => (s += d));
process.stdin.on("end", () => {
  let j;
  try { j = JSON.parse(s); } catch (e) { console.log("PARSE"); return; }
  const problems = [];
  const g = j.group && j.group.default && j.group.default.targets;
  if (!Array.isArray(g) || !g.includes("api") || !g.includes("worker"))
    problems.push("group default must list targets api and worker");
  for (const name of ["api", "worker"]) {
    const t = j.target && j.target[name];
    if (!t) { problems.push(`target ${name} missing`); continue; }
    const tag = `chai-44-${name}:v1`;
    if (!Array.isArray(t.tags) || !t.tags.includes(tag))
      problems.push(`target ${name} must tag ${tag}`);
  }
  console.log(problems.length ? "MISS: " + problems.join(" | ") : "OK");
});
')
case "$result" in
  OK) pass "Group 'default' → api + worker, tags chai-44-api:v1 / chai-44-worker:v1" ;;
  MISS:*) fail "The resolved plan is off: ${result#MISS: }." ;;
  *) fail "Couldn't parse the bake --print output — is docker-bake.hcl producing valid JSON via --print?" ;;
esac

for img in chai-44-api:v1 chai-44-worker:v1; do
  if ! docker image inspect "$img" >/dev/null 2>&1; then
    fail "Image '$img' doesn't exist locally — run the bake: (cd ch44 && docker buildx bake)"
  fi
  proj=$(docker image inspect -f '{{index .Config.Labels "com.chaicode.project"}}' "$img")
  if [ "$proj" != "chai-44" ]; then
    fail "$img is missing the shared label com.chaicode.project=chai-44 (got '${proj:-none}') — set labels on the target and re-bake."
  fi
  ver=$(docker image inspect -f '{{index .Config.Labels "com.chaicode.version"}}' "$img")
  if [ "$ver" != "v1" ]; then
    fail "$img has com.chaicode.version='${ver:-none}', expected 'v1' — the APP_VERSION arg didn't flow. Set args = { APP_VERSION = \"v1\" } on the target and re-bake."
  fi
  pass "$img built, labels project=chai-44 version=v1"
done

celebrate "Exercise 44.1 complete. One file, one command, the whole platform built."
