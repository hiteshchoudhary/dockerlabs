#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# ── 1. The registry itself ───────────────────────────────────────────────────
state=$(docker container inspect -f '{{.State.Status}}' chai-46-registry 2>/dev/null)
if [ "$state" != "running" ]; then
  fail "Container 'chai-46-registry' is ${state:-missing}. Start it: docker run -d --name chai-46-registry -p 8146:5000 registry:2"
fi
pass "chai-46-registry is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-46-registry)
case "$img" in
  registry:2*|registry) pass "It runs the registry:2 image" ;;
  *) fail "chai-46-registry uses image '$img' — expected 'registry:2'." ;;
esac

if ! curl -fsS --max-time 10 http://127.0.0.1:8146/v2/ >/dev/null 2>&1; then
  fail "The registry API isn't answering on http://127.0.0.1:8146/v2/ — publish it with -p 8146:5000."
fi
pass "Registry API answers on port 8146"

# ── 2. The pushed artifacts ──────────────────────────────────────────────────
catalog=$(curl -fsS --max-time 10 http://127.0.0.1:8146/v2/_catalog 2>/dev/null)
for repo in chai-46-api chai-46-web; do
  has=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log((j.repositories||[]).includes(process.argv[2])?"yes":"no")}catch(e){console.log("no")}' "$catalog" "$repo")
  if [ "$has" != "yes" ]; then
    fail "Repository '$repo' is not in the registry catalog (got: ${catalog:-nothing}). Tag and push: docker tag ... 127.0.0.1:8146/$repo:1.0.0 && docker push 127.0.0.1:8146/$repo:1.0.0"
  fi
  pass "Registry catalog has '$repo'"
done

for repo in chai-46-api chai-46-web; do
  tags=$(curl -fsS --max-time 10 "http://127.0.0.1:8146/v2/$repo/tags/list" 2>/dev/null)
  has=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log((j.tags||[]).includes("1.0.0")?"yes":"no")}catch(e){console.log("no")}' "$tags")
  if [ "$has" != "yes" ]; then
    fail "'$repo' has no 1.0.0 tag in the registry (tags: ${tags:-none}). Semver, not latest: push $repo:1.0.0."
  fi
  pass "$repo:1.0.0 is in the registry"
done

# ── 3. The platform is back, running FROM the registry ──────────────────────
for c in chai-45-web chai-45-api chai-45-db chai-45-cache chai-45-qdrant; do
  s=$(docker container inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  if [ "$s" != "running" ]; then
    fail "Container '$c' is ${s:-missing}. Boot the platform from the registry: docker compose -f compose.registry.yaml up -d --wait (from workspace/ch46)."
  fi
done
pass "All five platform containers are running again"

h=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' chai-45-api)
if [ "$h" != "healthy" ]; then
  fail "chai-45-api health is '$h' — keep the healthcheck from Chapter 45 in the deploy file too."
fi
pass "The pulled api reports healthy"

apiref=$(docker container inspect -f '{{.Config.Image}}' chai-45-api)
case "$apiref" in
  127.0.0.1:8146/chai-46-api:*) pass "api runs from the registry: $apiref" ;;
  *) fail "api runs from '$apiref' — the deploy file must use image: 127.0.0.1:8146/chai-46-api:1.0.0 (no build:)." ;;
esac

webref=$(docker container inspect -f '{{.Config.Image}}' chai-45-web)
case "$webref" in
  127.0.0.1:8146/chai-46-web:*) pass "web runs from the registry: $webref" ;;
  *) fail "web runs from '$webref' — the deploy file must use image: 127.0.0.1:8146/chai-46-web:1.0.0 (no build:)." ;;
esac

# ── 4. No local copies — the registry is the source of truth ─────────────────
for localtag in chai-45-api chai-45-web; do
  if docker image inspect "$localtag" >/dev/null 2>&1; then
    fail "Local image tag '$localtag' still exists — the fresh-machine proof requires removing it: docker rmi $localtag (take the stack down first if it's in use)."
  fi
  pass "Local build tag '$localtag' is gone"
done

# ── 5. And it actually works ─────────────────────────────────────────────────
page=$(curl -fsS --max-time 10 http://127.0.0.1:8045/ 2>/dev/null)
case "$page" in
  *"ChaiCode Platform"*) pass "http://localhost:8045 serves the ChaiCode page (pulled, not built)" ;;
  *) fail "Nothing on http://localhost:8045 — check: docker compose -f compose.registry.yaml ps" ;;
esac

status=$(curl -sS --max-time 15 http://127.0.0.1:8045/api/status 2>/dev/null)
ok=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log(j.db==="connected"&&j.cache==="connected"&&j.qdrant==="connected"?"yes":"no")}catch(e){console.log("no")}' "$status")
if [ "$ok" != "yes" ]; then
  fail "/api/status isn't all-connected (got: ${status:-nothing}). The deploy file needs the same networks and service names as Chapter 45."
fi
pass "api → db, cache, qdrant: all connected"

celebrate "Exercise 46.1 complete. The registry holds the only copies — and the platform runs anyway. That's shipping."
