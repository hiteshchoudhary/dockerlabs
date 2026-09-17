#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

# ── 1. Five containers, all running ─────────────────────────────────────────
for c in chai-45-web chai-45-api chai-45-db chai-45-cache chai-45-qdrant; do
  state=$(docker container inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  if [ "$state" != "running" ]; then
    fail "Container '$c' is ${state:-missing}. Write workspace/ch45/compose.yaml (name: chai-45, container_name $c) and run: docker compose up -d --wait  (from workspace/ch45)."
  fi
done
pass "All five containers running: web, api, db, cache, qdrant"

# ── 2. One compose project: chai-45 ─────────────────────────────────────────
proj=$(docker container inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' chai-45-api)
if [ "$proj" != "chai-45" ]; then
  fail "chai-45-api belongs to compose project '${proj:-none}', expected 'chai-45'. Put 'name: chai-45' at the top of compose.yaml."
fi
pass "Compose project is 'chai-45'"

# ── 3. Healthchecks ──────────────────────────────────────────────────────────
for c in chai-45-api chai-45-db chai-45-cache; do
  h=$(docker container inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$c")
  if [ "$h" != "healthy" ]; then
    fail "$c health is '$h' — it needs a healthcheck reporting healthy (api: wget its /health; db: pg_isready; cache: redis-cli ping). Check: docker compose ps"
  fi
  pass "$c reports healthy"
done

# ── 4. Startup ordering is gated on health ───────────────────────────────────
dep=$(docker container inspect -f '{{index .Config.Labels "com.docker.compose.depends_on"}}' chai-45-api)
case "$dep" in
  *service_healthy*) pass "api waits for healthy dependencies (condition: service_healthy)" ;;
  *) fail "The api service doesn't gate on healthy dependencies. Give it depends_on with 'condition: service_healthy' for db and cache, then: docker compose up -d --wait" ;;
esac

# ── 5. Hardened api: non-root + read-only rootfs ─────────────────────────────
uid=$(docker exec chai-45-api id -u 2>/dev/null)
if [ "$uid" = "0" ] || [ -z "$uid" ]; then
  fail "The api runs as UID '${uid:-unknown}' — it must be non-root. The scaffolded Dockerfile sets USER node; rebuild with: docker compose up -d --build"
fi
pass "api runs as non-root (UID $uid)"

ro=$(docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' chai-45-api)
if [ "$ro" != "true" ]; then
  fail "The api's root filesystem is writable. Add 'read_only: true' to the api service and recreate: docker compose up -d"
fi
pass "api root filesystem is read-only"

# ── 6. Network segmentation ──────────────────────────────────────────────────
front=$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' chai-45_frontend 2>/dev/null)
if [ -z "$front" ]; then
  fail "Network 'chai-45_frontend' doesn't exist. Define 'frontend' under top-level networks: in compose.yaml (project chai-45 names it chai-45_frontend)."
fi
for c in chai-45-web chai-45-api; do
  case " $front " in *" $c "*) : ;; *) fail "'$c' is not on chai-45_frontend (members: ${front:-none}). Add the network to its service." ;; esac
done
for c in chai-45-db chai-45-cache chai-45-qdrant; do
  case " $front " in *" $c "*) fail "'$c' sits on the frontend network — the backend trio must not be reachable from the front. Put it on backend only." ;; esac
done
pass "chai-45_frontend holds exactly the front of house: web + api"

back=$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' chai-45_backend 2>/dev/null)
if [ -z "$back" ]; then
  fail "Network 'chai-45_backend' doesn't exist. Define 'backend' under top-level networks: in compose.yaml."
fi
for c in chai-45-api chai-45-db chai-45-cache chai-45-qdrant; do
  case " $back " in *" $c "*) : ;; *) fail "'$c' is not on chai-45_backend (members: ${back:-none}). Add the network to its service." ;; esac
done
case " $back " in *" chai-45-web "*) fail "web is on the backend network — it should only ever talk to the api, on frontend." ;; esac
pass "chai-45_backend holds api + db + cache + qdrant (web stays out)"

# ── 7. Only web is published ─────────────────────────────────────────────────
for c in chai-45-api chai-45-db chai-45-cache chai-45-qdrant; do
  n=$(docker inspect -f '{{len .HostConfig.PortBindings}}' "$c")
  if [ "$n" != "0" ]; then
    fail "'$c' publishes host ports — nothing but web may be published. Remove its ports: section."
  fi
done
pass "db, cache, qdrant and api publish no host ports"

webport=$(docker port chai-45-web 80 2>/dev/null)
case "$webport" in
  *:8045*) pass "web is published on host port 8045" ;;
  *) fail "web's port 80 isn't published on 8045 (got: '${webport:-nothing}'). Use ports: [\"8045:80\"]." ;;
esac

# ── 8. Volumes ───────────────────────────────────────────────────────────────
dbm=$(docker inspect -f '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' chai-45-db)
case "$dbm" in
  *"chai-45-pgdata:/var/lib/postgresql/data"*) pass "Volume chai-45-pgdata is mounted at /var/lib/postgresql/data" ;;
  *) fail "db mounts: '$dbm' — expected volume 'chai-45-pgdata' at /var/lib/postgresql/data. Use name: chai-45-pgdata under top-level volumes:." ;;
esac

qm=$(docker inspect -f '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' chai-45-qdrant)
case "$qm" in
  *"chai-45-qdrant:/qdrant/storage"*) pass "Volume chai-45-qdrant is mounted at /qdrant/storage" ;;
  *) fail "qdrant mounts: '$qm' — expected volume 'chai-45-qdrant' at /qdrant/storage." ;;
esac

# ── 9. The platform actually answers ─────────────────────────────────────────
page=$(curl -fsS --max-time 10 http://127.0.0.1:8045/ 2>/dev/null)
case "$page" in
  *"ChaiCode Platform"*) pass "http://localhost:8045 serves the ChaiCode page" ;;
  *) fail "Nothing useful on http://localhost:8045 — is web running and published? Check: docker compose ps && docker compose logs web" ;;
esac

status=$(curl -sS --max-time 15 http://127.0.0.1:8045/api/status 2>/dev/null)
if [ -z "$status" ]; then
  fail "/api/status gave no answer through the proxy. nginx proxies /api to the api container — check: docker compose logs web api"
fi
for dep in db cache qdrant; do
  val=$(node -e 'try{const j=JSON.parse(process.argv[1]);console.log(j[process.argv[2]]||"missing")}catch(e){console.log("unparseable")}' "$status" "$dep")
  if [ "$val" != "connected" ]; then
    fail "/api/status reports $dep: '$val' — the api can't reach $dep. Same backend network? Service named '$dep'? Check: docker compose logs $dep"
  fi
  pass "api → $dep: connected (live check over the backend network)"
done

# ── 10. Seed data made it in ─────────────────────────────────────────────────
row=$(docker exec chai-45-db psql -U chai -d chaicode -tAc "SELECT count(*) FROM chai_menu WHERE name='masala chai'" 2>/dev/null | tr -d '[:space:]')
if [ "${row:-0}" -ge 1 ] 2>/dev/null; then
  pass "Seeded row present: 'masala chai' is on the menu"
else
  fail "chai_menu has no 'masala chai' — seed.sql didn't run. It only runs on an EMPTY volume: docker compose down -v && docker compose up -d --wait (yes, -v: you want a fresh seed here)."
fi

celebrate "Exercise 45.1 complete. Five services, two networks, one command — the whole book, running."
