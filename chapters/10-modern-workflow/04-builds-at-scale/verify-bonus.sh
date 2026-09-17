#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

BAKE="${LAB_WORKSPACE:?}/ch44/docker-bake.hcl"
if [ ! -f "$BAKE" ]; then
  fail "No workspace/ch44/docker-bake.hcl — finish the main exercise first."
fi

if grep -q 'inherits' "$BAKE"; then
  pass "The bake file uses inheritance"
else
  fail "No 'inherits' in docker-bake.hcl — move the shared args/labels into a common target and pull it in with inherits = [\"common\"]."
fi

# JSON goes to stdout; buildx progress noise goes to stderr — keep them apart.
plan=$( (cd "${LAB_WORKSPACE}/ch44" && docker buildx bake --print) 2>/dev/null )
if [ $? -ne 0 ] || [ -z "$plan" ]; then
  err=$( (cd "${LAB_WORKSPACE}/ch44" && docker buildx bake --print) 2>&1 >/dev/null | tail -3 | tr '\n' ' ' )
  fail "After the refactor, bake --print no longer resolves: ${err:-unknown error}"
fi

result=$(echo "$plan" | node -e '
let s = "";
process.stdin.on("data", d => (s += d));
process.stdin.on("end", () => {
  let j;
  try { j = JSON.parse(s); } catch (e) { console.log("PARSE"); return; }
  const problems = [];
  const g = j.group && j.group.default && j.group.default.targets;
  if (!Array.isArray(g) || !g.includes("api") || !g.includes("worker"))
    problems.push("group default lost api/worker");
  for (const name of ["api", "worker"]) {
    const t = j.target && j.target[name];
    if (!t || !Array.isArray(t.tags) || !t.tags.includes(`chai-44-${name}:v1`))
      problems.push(`target ${name} lost its chai-44-${name}:v1 tag`);
  }
  console.log(problems.length ? "MISS: " + problems.join(" | ") : "OK");
});
')
case "$result" in
  OK) pass "Resolved plan still has both tagged targets in group 'default'" ;;
  MISS:*) fail "The refactor broke the plan: ${result#MISS: }." ;;
  *) fail "Couldn't parse the bake --print output after the refactor." ;;
esac

for img in chai-44-api:v1 chai-44-worker:v1; do
  if ! docker image inspect "$img" >/dev/null 2>&1; then
    fail "Image '$img' is missing — re-bake after the refactor: (cd ch44 && docker buildx bake)"
  fi
  bw=$(docker image inspect -f '{{index .Config.Labels "com.chaicode.built-with"}}' "$img")
  if [ "$bw" != "bake" ]; then
    fail "$img lacks com.chaicode.built-with=bake — add it to the common target and RE-BAKE so the images pick it up."
  fi
  proj=$(docker image inspect -f '{{index .Config.Labels "com.chaicode.project"}}' "$img")
  if [ "$proj" != "chai-44" ]; then
    fail "$img lost com.chaicode.project=chai-44 in the refactor — the common target must still carry the exercise labels."
  fi
  pass "$img re-baked with inherited labels (built-with=bake)"
done

celebrate "Challenge complete. Shared config declared once — drift has nowhere to live."
