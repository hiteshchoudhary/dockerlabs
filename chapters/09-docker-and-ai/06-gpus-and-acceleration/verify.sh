#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

rt="${LAB_WORKSPACE:?}/ch40/runtimes.txt"
if [ ! -f "$rt" ]; then
  fail "No file at workspace/ch40/runtimes.txt. Save it: docker info -f '{{json .Runtimes}}' > ./ch40/runtimes.txt (from workspace/)."
fi
pass "workspace/ch40/runtimes.txt exists"

live=$(docker info -f '{{json .Runtimes}}')

# Compare the SET of runtime NAMES (keys), not the volatile feature blob.
cmp=$(node -e '
const fs = require("fs");
const keys = (s) => { try { return Object.keys(JSON.parse(s)).sort(); } catch { return null; } };
const saved = keys(fs.readFileSync(process.argv[1], "utf8"));
const live  = keys(process.argv[2]);
if (!saved) { console.log("SAVEDBAD"); process.exit(0); }
if (!live)  { console.log("LIVEBAD"); process.exit(0); }
console.log(JSON.stringify(saved) === JSON.stringify(live) ? "MATCH:" + saved.join(",") : "DIFF:" + saved.join(",") + "|" + live.join(","));
' "$rt" "$live" 2>/dev/null)

case "$cmp" in
  MATCH:*) pass "runtimes.txt matches the live daemon (runtimes: ${cmp#MATCH:})" ;;
  SAVEDBAD) fail "runtimes.txt isn't valid JSON. Re-save with: docker info -f '{{json .Runtimes}}' > ./ch40/runtimes.txt" ;;
  DIFF:*) fail "runtimes.txt lists different runtimes than the daemon now reports. Re-run the exact command: docker info -f '{{json .Runtimes}}' > ./ch40/runtimes.txt" ;;
  *) fail "Couldn't compare runtimes (node error). Re-save runtimes.txt and try again." ;;
esac

# does the daemon actually have an nvidia runtime?
has_nvidia=$(node -e 'try{const r=JSON.parse(process.argv[1]);console.log(Object.keys(r).some(k=>k.toLowerCase().includes("nvidia"))?"yes":"no")}catch{console.log("no")}' "$live" 2>/dev/null)

nf="${LAB_WORKSPACE}/ch40/nvidia.txt"
if [ ! -f "$nf" ]; then
  fail "No file at workspace/ch40/nvidia.txt. Write 'yes' or 'no' — whether an nvidia runtime exists on this daemon (on this machine: $has_nvidia)."
fi
answer=$(tr -d '[:space:]' < "$nf" | tr '[:upper:]' '[:lower:]')
case "$answer" in
  yes|no) : ;;
  *) fail "nvidia.txt says '$answer' — it must be exactly 'yes' or 'no'." ;;
esac
if [ "$answer" = "$has_nvidia" ]; then
  pass "nvidia.txt says '$answer' — matches reality (this daemon has ${has_nvidia} nvidia runtime)"
else
  fail "nvidia.txt says '$answer', but this daemon's nvidia runtime presence is '$has_nvidia'. Read runtimes.txt and answer truthfully for THIS machine."
fi

celebrate "Exercise 40.1 complete. You read your platform correctly — the first skill of GPU work."
