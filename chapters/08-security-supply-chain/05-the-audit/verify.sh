#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker
info "— THE AUDIT — one assertion per checklist line —"

# ============ THE IMAGE ============

if ! docker image inspect chai-34-api:v1 >/dev/null 2>&1; then
  fail "AUDIT 1/15 — no image 'chai-34-api:v1'. Build it from workspace/ch34/app: docker build -t chai-34-api:v1 ."
fi
pass "AUDIT  1/15 — image chai-34-api:v1 exists"

df="${LAB_WORKSPACE:?}/ch34/app/Dockerfile"
[ -f "$df" ] || fail "AUDIT 2/15 — no Dockerfile at workspace/ch34/app/Dockerfile."
fromline=$(grep -iE '^[[:space:]]*FROM[[:space:]]' "$df" | head -n1)
if ! echo "$fromline" | grep -qiE 'node[^[:space:]]*@sha256:[0-9a-f]{64}'; then
  fail "AUDIT 2/15 — FROM is '${fromline:-missing}': the base isn't pinned by digest. Chapter 33: docker pull node:22-alpine, then docker image inspect -f '{{index .RepoDigests 0}}' node:22-alpine."
fi
digest=$(echo "$fromline" | grep -oE 'sha256:[0-9a-f]{64}' | head -n1)
if ! docker image inspect "node@$digest" >/dev/null 2>&1; then
  fail "AUDIT 2/15 — the pinned digest ($digest) doesn't resolve to a local node image; it's not genuine. Copy it from docker image inspect -f '{{index .RepoDigests 0}}' node:22-alpine."
fi
pass "AUDIT  2/15 — base image pinned by a genuine digest"

imguser=$(docker image inspect -f '{{.Config.User}}' chai-34-api:v1)
case "$imguser" in
  ""|"root"|"0"|"0:0") fail "AUDIT 3/15 — the image runs as root (USER '${imguser:-<empty>}'). Chapter 30: dedicated user + USER line, rebuild." ;;
esac
pass "AUDIT  3/15 — image USER is '$imguser' (non-root)"

hc=$(docker image inspect -f '{{if .Config.Healthcheck}}{{.Config.Healthcheck.Test}}{{end}}' chai-34-api:v1)
if [ -z "$hc" ] || [ "$hc" = "[NONE]" ]; then
  fail "AUDIT 4/15 — no HEALTHCHECK in the image. Chapter 12: HEALTHCHECK --interval=5s CMD wget -q --spider http://127.0.0.1:3000/healthz || exit 1 — rebuild."
fi
pass "AUDIT  4/15 — HEALTHCHECK baked into the image"

title=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.title"}}' chai-34-api:v1)
version=$(docker image inspect -f '{{index .Config.Labels "org.opencontainers.image.version"}}' chai-34-api:v1)
if [ "$title" != "chai-34-api" ] || [ -z "$version" ]; then
  fail "AUDIT 5/15 — OCI labels incomplete (title='${title:-unset}', version='${version:-unset}'). Add LABEL org.opencontainers.image.title=\"chai-34-api\" org.opencontainers.image.version=\"v1\" and rebuild."
fi
pass "AUDIT  5/15 — OCI labels present (title=$title, version=$version)"

# ============ THE CONTAINER ============

if ! docker container inspect chai-34-api >/dev/null 2>&1; then
  fail "AUDIT 6/15 — no container 'chai-34-api'. Run the hardened command from the task (port 8034)."
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-34-api)
[ "$state" = "running" ] || fail "AUDIT 6/15 — chai-34-api is '$state', not running. docker logs chai-34-api will say why (EACCES → ownership; read-only errors → the app tried to write)."
cimg=$(docker container inspect -f '{{.Config.Image}}' chai-34-api)
[ "$cimg" = "chai-34-api:v1" ] || fail "AUDIT 6/15 — container runs '$cimg', expected chai-34-api:v1. Remove and re-run from your image."
pass "AUDIT  6/15 — container chai-34-api is running from chai-34-api:v1"

health=""
for i in $(seq 1 45); do
  health=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' chai-34-api 2>/dev/null)
  [ "$health" = "healthy" ] && break
  sleep 1
done
if [ "$health" != "healthy" ]; then
  fail "AUDIT 7/15 — health is '${health:-none}' after 45s, not healthy. Check the HEALTHCHECK URL (127.0.0.1:3000/healthz) and docker inspect -f '{{json .State.Health}}' chai-34-api for the probe's own error output."
fi
pass "AUDIT  7/15 — container reports healthy"

uid=$(docker exec chai-34-api id -u 2>/dev/null)
if [ -z "$uid" ] || [ "$uid" = "0" ]; then
  fail "AUDIT 8/15 — process uid is '${uid:-unknown}'. The USER line must precede CMD; rebuild and re-run."
fi
pass "AUDIT  8/15 — process runs as uid $uid (≠ 0)"

ro=$(docker container inspect -f '{{.HostConfig.ReadonlyRootfs}}' chai-34-api)
[ "$ro" = "true" ] || fail "AUDIT 9/15 — rootfs is writable. Add --read-only (the app is stateless; no tmpfs needed)."
if docker exec chai-34-api sh -c 'touch /tmp/audit-probe' >/dev/null 2>&1; then
  fail "AUDIT 9/15 — a write INSIDE the container succeeded — the rootfs isn't effectively read-only. Re-run with --read-only and without stray writable mounts."
fi
pass "AUDIT  9/15 — rootfs read-only (write attempt inside really fails)"

capdrop=$(docker container inspect -f '{{range .HostConfig.CapDrop}}{{.}} {{end}}' chai-34-api)
echo "$capdrop" | grep -qiw "ALL" || fail "AUDIT 10/15 — CapDrop is '${capdrop:-empty}', expected ALL. Add --cap-drop ALL."
pass "AUDIT 10/15 — all capabilities dropped"

capadd=$(docker container inspect -f '{{range .HostConfig.CapAdd}}{{.}} {{end}}' chai-34-api)
nadds=$(echo "$capadd" | wc -w | tr -d ' ')
[ "$nadds" = "0" ] || fail "AUDIT 11/15 — CapAdd holds '$capadd'. A non-root stateless service needs NOTHING back — remove every --cap-add."
pass "AUDIT 11/15 — zero capabilities added back"

secopt=$(docker container inspect -f '{{range .HostConfig.SecurityOpt}}{{.}} {{end}}' chai-34-api)
echo "$secopt" | grep -q "no-new-privileges" || fail "AUDIT 12/15 — no-new-privileges not set. Add --security-opt no-new-privileges."
pass "AUDIT 12/15 — privilege escalation disabled (no-new-privileges)"

mem=$(docker container inspect -f '{{.HostConfig.Memory}}' chai-34-api)
if [ -z "$mem" ] || [ "$mem" = "0" ]; then
  fail "AUDIT 13/15 — no memory limit. Add --memory 256m."
fi
pass "AUDIT 13/15 — memory limit set ($mem bytes)"

pids=$(docker container inspect -f '{{.HostConfig.PidsLimit}}' chai-34-api)
if [ -z "$pids" ] || [ "$pids" = "0" ] || [ "$pids" = "-1" ]; then
  fail "AUDIT 14/15 — no pids limit. Add --pids-limit 100."
fi
pass "AUDIT 14/15 — pids limit set ($pids)"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8034/ 2>/dev/null)
[ -n "$body" ] || fail "AUDIT 15/15 — no HTTP answer on http://127.0.0.1:8034. Publish with -p 8034:3000."
if echo "$body" | grep -q '"uid":0[,}]'; then
  fail "AUDIT 15/15 — the API says it runs as uid 0. Fix the USER line and re-run."
fi
echo "$body" | grep -q '"service":"chai-34-api"' || fail "AUDIT 15/15 — unexpected response on 8034: '$body'. Run the chapter scaffold (workspace/ch34/app)."
pass "AUDIT 15/15 — API serves on 8034 as a non-root process"

celebrate "Exercise 34.1 complete. Fifteen for fifteen — the auditor signs off."
