#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-36-qdrant >/dev/null 2>&1; then
  fail "No container named 'chai-36-qdrant'. Run it: docker run -d --name chai-36-qdrant -p 8036:6333 -v chai-36-data:/qdrant/storage qdrant/qdrant"
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-36-qdrant)
if [ "$state" != "running" ]; then
  fail "chai-36-qdrant is '$state', not running. Check 'docker logs chai-36-qdrant', then remove and re-run it."
fi
pass "Container 'chai-36-qdrant' is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-36-qdrant)
case "$img" in
  qdrant/qdrant|qdrant/qdrant:*) pass "Created from the 'qdrant/qdrant' image" ;;
  *) fail "Container uses image '$img' — expected 'qdrant/qdrant'." ;;
esac

port=$(docker container inspect -f '{{(index (index .NetworkSettings.Ports "6333/tcp") 0).HostPort}}' chai-36-qdrant 2>/dev/null)
if [ "$port" = "8036" ]; then
  pass "REST port 6333 published on host port 8036"
else
  fail "Port 6333 isn't published on host port 8036 (found: '${port:-none}'). Re-run with -p 8036:6333."
fi

vol=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/qdrant/storage"}}{{.Name}}{{end}}{{end}}' chai-36-qdrant)
if [ "$vol" = "chai-36-data" ]; then
  pass "Volume 'chai-36-data' mounted at /qdrant/storage"
else
  fail "/qdrant/storage isn't backed by the volume 'chai-36-data' (found: '${vol:-nothing}'). Re-run with -v chai-36-data:/qdrant/storage."
fi

coll=$(curl -fsS http://127.0.0.1:8036/collections/chai_notes 2>/dev/null)
if [ -z "$coll" ]; then
  fail "GET /collections/chai_notes returned nothing — the collection doesn't exist yet. Create it: curl -X PUT http://127.0.0.1:8036/collections/chai_notes -H 'Content-Type: application/json' -d '{\"vectors\":{\"size\":4,\"distance\":\"Cosine\"}}'"
fi

shape=$(node -e '
const j = JSON.parse(process.argv[1]);
const v = j?.result?.config?.params?.vectors || {};
console.log(v.size === 4 && v.distance === "Cosine" ? "OK" : `size=${v.size} distance=${v.distance}`);
' "$coll" 2>/dev/null)
if [ "$shape" = "OK" ]; then
  pass "Collection 'chai_notes' exists (size 4, Cosine)"
else
  fail "Collection 'chai_notes' has the wrong shape ($shape) — expected size 4, distance Cosine. Delete it (curl -X DELETE .../collections/chai_notes) and recreate."
fi

count=$(curl -fsS -X POST http://127.0.0.1:8036/collections/chai_notes/points/count \
  -H 'Content-Type: application/json' -d '{"exact":true}' 2>/dev/null \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s)?.result?.count ?? 0))' 2>/dev/null)
if [ "${count:-0}" -ge 2 ]; then
  pass "Collection holds ${count} points (needed ≥ 2)"
else
  fail "Only ${count:-0} points in chai_notes — insert at least 2 via PUT /collections/chai_notes/points?wait=true (see hint 2)."
fi

hits=$(curl -fsS -X POST http://127.0.0.1:8036/collections/chai_notes/points/search \
  -H 'Content-Type: application/json' \
  -d '{"vector":[0.9,0.1,0.0,0.0],"limit":1,"with_payload":true}' 2>/dev/null \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log((JSON.parse(s)?.result||[]).length))' 2>/dev/null)
if [ "${hits:-0}" -ge 1 ]; then
  pass "Nearest-neighbor search returns a result"
else
  fail "A search against chai_notes returned no results. Check your points landed (points/count) and that vectors have exactly 4 numbers."
fi

celebrate "Exercise 36.1 complete. Your stack has a memory now — next we bolt it to the model."
