#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

CF="${LAB_WORKSPACE:?}/ch22/compose.yaml"
[ -f "$CF" ] || fail "No compose.yaml at workspace/ch22/. Create it there."
pass "workspace/ch22/compose.yaml exists"

cfg=$(docker compose -p chai-22 -f "$CF" config --format json 2>&1)
if [ $? -ne 0 ]; then
  fail "Your compose file doesn't parse: $(echo "$cfg" | head -n2). Run 'docker compose config' in workspace/ch22/ for the full error."
fi

sync_check=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const rules = c.services?.web?.develop?.watch || [];
  const r = rules.find(
    (x) =>
      x.action === "sync" &&
      String(x.path || "").replace(/\\/g, "/").endsWith("app/public") &&
      String(x.target || "") === "/usr/src/app/public"
  );
  console.log(r ? "ok" : rules.length ? "wrong-rule" : "no-watch");' 2>/dev/null)

case "$sync_check" in
  ok)         pass "web declares a sync watch rule: ./app/public → /usr/src/app/public" ;;
  no-watch)   fail "web has no develop.watch section. Add develop: → watch: with a sync rule (see the chapter's YAML)." ;;
  wrong-rule) fail "web has watch rules, but none is action: sync with path ./app/public and target /usr/src/app/public. Check path, target and action spelling." ;;
  *)          fail "Couldn't read develop.watch from the resolved config. Run 'docker compose config' and check the develop section survives." ;;
esac

if docker image inspect chai-22-web >/dev/null 2>&1; then
  pass "Image chai-22-web has been built"
else
  fail "No chai-22-web image found — build it: docker compose up -d --build (from workspace/ch22/, with name: chai-22 in the file)."
fi

web_id=$(docker ps -q \
  --filter "label=com.docker.compose.project=chai-22" \
  --filter "label=com.docker.compose.service=web" | head -n1)
if [ -z "$web_id" ]; then
  fail "No running 'web' container in project chai-22. Start it: docker compose up -d --build"
fi
pass "web is running under project chai-22"

if curl -fsS --max-time 5 http://localhost:8022/ 2>/dev/null | grep -qi "ChaiCode landing"; then
  pass "http://localhost:8022 serves the landing page"
else
  fail "Port 8022 doesn't serve the landing page. Check ports: (\"8022:3000\"), then docker compose up -d --build."
fi

celebrate "Exercise 22.1 complete. Save, sync, refresh — your inner loop is back."
