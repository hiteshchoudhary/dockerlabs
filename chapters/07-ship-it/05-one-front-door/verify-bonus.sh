#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-28-proxy >/dev/null 2>&1; then
  fail "chai-28-proxy doesn't exist — finish the main exercise first."
fi

body=$(curl -fsS --max-time 5 http://127.0.0.1:8028/health 2>/dev/null)
if [ -z "$body" ]; then
  fail "http://127.0.0.1:8028/health doesn't answer 200. Add to your ch28/nginx.conf server block: location /health { return 200 \"ok\\n\"; } — then recreate the proxy (docker rm -f chai-28-proxy and run it again)."
fi

trimmed=$(echo "$body" | tr -d '[:space:]')
if [ "$trimmed" = "ok" ]; then
  pass "/health answers 200 with body 'ok' — served by nginx itself"
else
  fail "/health answered '$body' — that looks proxied to a replica, not served by nginx. Use a return directive (location /health { return 200 \"ok\\n\"; }), not proxy_pass, and recreate the proxy."
fi

distinct=$(for i in $(seq 1 20); do curl -fsS --max-time 5 http://127.0.0.1:8028/ 2>/dev/null; done | sort -u | grep -c 'hello from')
if [ "$distinct" -ge 2 ]; then
  pass "/ still round-robins across $distinct hostnames"
else
  fail "/ no longer load-balances across both replicas — your /health edit may have damaged the location / block. Compare against the template and recreate the proxy."
fi

celebrate "Challenge complete. The door can now vouch for itself."
