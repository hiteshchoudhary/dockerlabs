#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-31-app >/dev/null 2>&1; then
  fail "No container named 'chai-31-app'. Build the hardened run command from the chapter (start with --read-only and let the crashes guide you)."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-31-app)
if [ "$state" != "running" ]; then
  fail "chai-31-app is '$state', not running. Read docker logs chai-31-app — nginx names exactly what it's missing (a tmpfs path or a capability). Fix, docker rm -f chai-31-app, re-run."
fi
pass "Container 'chai-31-app' is running"

img=$(docker container inspect -f '{{.Config.Image}}' chai-31-app)
case "$img" in
  nginx:alpine|nginx:alpine@*) pass "Created from 'nginx:alpine'" ;;
  *) fail "chai-31-app uses image '$img' — expected 'nginx:alpine'." ;;
esac

ro=$(docker container inspect -f '{{.HostConfig.ReadonlyRootfs}}' chai-31-app)
if [ "$ro" != "true" ]; then
  fail "Root filesystem is writable. Add --read-only (plus the tmpfs mounts nginx needs: /var/cache/nginx and /run)."
fi
pass "Root filesystem is read-only"

# prove it, don't just trust the flag
if docker exec chai-31-app sh -c 'touch /etc/pwned' >/dev/null 2>&1; then
  fail "A write to /etc inside the container SUCCEEDED — the rootfs isn't actually read-only. Re-run with --read-only."
fi
pass "A write attempt inside really fails (Read-only file system)"

capdrop=$(docker container inspect -f '{{range .HostConfig.CapDrop}}{{.}} {{end}}' chai-31-app)
if ! echo "$capdrop" | grep -qiw "ALL"; then
  fail "CapDrop is '${capdrop:-empty}' — expected ALL. Add --cap-drop ALL."
fi
pass "All capabilities dropped (CapDrop: ALL)"

capadd=$(docker container inspect -f '{{range .HostConfig.CapAdd}}{{.}} {{end}}' chai-31-app)
for c in CHOWN SETGID SETUID; do
  if ! echo "$capadd" | grep -qi "$c"; then
    fail "CapAdd is '${capadd:-empty}' — missing $c. nginx's master needs CHOWN, SETGID and SETUID back: --cap-add CHOWN --cap-add SETGID --cap-add SETUID."
  fi
done
ncaps=$(echo "$capadd" | wc -w | tr -d ' ')
if [ "$ncaps" != "3" ]; then
  fail "CapAdd holds $ncaps capabilities ('$capadd') — the allowlist is exactly three: CHOWN, SETGID, SETUID. Remove the extras (nginx doesn't even need NET_BIND_SERVICE in a container)."
fi
pass "Capability allowlist is exactly CHOWN, SETGID, SETUID"

secopt=$(docker container inspect -f '{{range .HostConfig.SecurityOpt}}{{.}} {{end}}' chai-31-app)
if ! echo "$secopt" | grep -q "no-new-privileges"; then
  fail "no-new-privileges isn't set (SecurityOpt: '${secopt:-empty}'). Add --security-opt no-new-privileges."
fi
pass "Privilege escalation is welded shut (no-new-privileges)"

pids=$(docker container inspect -f '{{.HostConfig.PidsLimit}}' chai-31-app)
if [ "$pids" != "100" ]; then
  fail "PidsLimit is '${pids:-unset}' — expected 100. Add --pids-limit 100."
fi
pass "Process ceiling set (pids limit 100)"

code=$(curl -fsS -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8031/ 2>/dev/null)
if [ "$code" != "200" ]; then
  fail "nginx doesn't answer with 200 on http://127.0.0.1:8031 (got '${code:-nothing}'). Publish with -p 8031:80 and check docker logs chai-31-app."
fi
pass "nginx serves normally on 8031 — full armor, zero functional cost"

celebrate "Exercise 31.1 complete. The workshop is gone; only the web server remains."
