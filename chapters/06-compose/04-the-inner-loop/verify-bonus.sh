#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

CF="${LAB_WORKSPACE:?}/ch22/compose.yaml"
[ -f "$CF" ] || fail "No compose.yaml at workspace/ch22/ — finish the main exercise first."

cfg=$(docker compose -p chai-22 -f "$CF" config --format json 2>&1)
if [ $? -ne 0 ]; then
  fail "Your compose file doesn't parse: $(echo "$cfg" | head -n2)."
fi

result=$(printf '%s' "$cfg" | node -e '
  const c = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const rules = c.services?.web?.develop?.watch || [];
  const sync = rules.some(
    (x) => x.action === "sync" && String(x.path || "").replace(/\\/g, "/").endsWith("app/public")
  );
  const rebuild = rules.some(
    (x) => x.action === "rebuild" && String(x.path || "").replace(/\\/g, "/").endsWith("package.json")
  );
  console.log(sync && rebuild ? "ok" : !sync ? "no-sync" : "no-rebuild");' 2>/dev/null)

case "$result" in
  ok)         pass "web carries both rules: sync on app/public AND rebuild on package.json" ;;
  no-sync)    fail "The exercise's sync rule went missing — keep both rules in the watch list." ;;
  no-rebuild) fail "No rebuild rule on package.json found. Add a second watch item: action: rebuild, path: ./app/package.json." ;;
  *)          fail "Couldn't read develop.watch from the resolved config — run 'docker compose config' to debug." ;;
esac

celebrate "Challenge complete. Cheap action for cheap changes, full rebuild when it counts."
