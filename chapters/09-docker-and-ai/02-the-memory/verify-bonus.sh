#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-36-qdrant >/dev/null 2>&1; then
  fail "chai-36-qdrant doesn't exist — the challenge ends with a NEW container running on the old volume."
fi
if ! docker volume inspect chai-36-data >/dev/null 2>&1; then
  fail "Volume chai-36-data doesn't exist. Finish the main exercise first."
fi

volts=$(docker volume inspect -f '{{.CreatedAt}}' chai-36-data)
cts=$(docker container inspect -f '{{.Created}}' chai-36-qdrant)
gap=$(node -e 'console.log(Math.round((Date.parse(process.argv[2]) - Date.parse(process.argv[1]))/1000))' "$volts" "$cts" 2>/dev/null)
if [ "${gap:-0}" -ge 3 ]; then
  pass "Container is ${gap}s newer than its volume — this is a replacement container"
else
  fail "The running chai-36-qdrant appears to be the ORIGINAL container (created with the volume). Destroy it (docker rm -f chai-36-qdrant), wait a beat, and start a fresh one on the same volume."
fi

count=$(curl -fsS -X POST http://127.0.0.1:8036/collections/chai_notes/points/count \
  -H 'Content-Type: application/json' -d '{"exact":true}' 2>/dev/null \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s)?.result?.count ?? 0))' 2>/dev/null)
if [ "${count:-0}" -ge 2 ]; then
  pass "The data survived the swap: ${count} points still in chai_notes"
else
  fail "chai_notes has ${count:-0} points after the swap — did the new container get -v chai-36-data:/qdrant/storage? Without the volume the data really is gone."
fi

f="${LAB_WORKSPACE:?}/ch36/survived.txt"
if [ ! -f "$f" ]; then
  fail "No file at workspace/ch36/survived.txt. Write the live point count (just the number) there."
fi
written=$(tr -d '[:space:]' < "$f")
if [ "$written" = "$count" ]; then
  pass "survived.txt says ${written} — matches the live count"
else
  fail "survived.txt says '${written}' but the collection holds ${count} points. Update the file with the real count."
fi

celebrate "Challenge complete. Containers are cattle; volumes are the memory."
