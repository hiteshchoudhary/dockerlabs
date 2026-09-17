#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=$1" \
    --filter "label=com.docker.compose.service=$2" | head -n1
}

# The original stack must still be up and untouched.
if [ -z "$(find_svc chai-19 web)" ]; then
  fail "Project chai-19 is no longer running — the challenge adds a second stack, it doesn't replace the first. Bring chai-19 back up."
fi
if ! curl -fsS --max-time 5 http://localhost:8019/ 2>/dev/null | grep -qi "ChaiCode status board"; then
  fail "The original stack no longer answers on 8019. Did WEB_PORT leak into the chai-19 project? Re-run docker compose up -d without WEB_PORT set."
fi
pass "Original chai-19 stack still up on 8019"

b_web=$(find_svc chai-19-b web)
if [ -z "$b_web" ]; then
  fail "No running 'web' service in project chai-19-b. Start the copy: WEB_PORT=8119 docker compose -p chai-19-b up -d (from workspace/ch19/)."
fi
pass "Second project chai-19-b has its own web service"

if [ -z "$(find_svc chai-19-b redis)" ]; then
  fail "Project chai-19-b has no running redis service — the whole stack should come up, not just web."
fi
pass "…and its own redis service"

if curl -fsS --max-time 5 http://localhost:8119/ 2>/dev/null | grep -qi "ChaiCode status board"; then
  pass "http://localhost:8119 serves the second stack"
else
  fail "Port 8119 doesn't answer. Make the port variable — \"\${WEB_PORT:-8019}:80\" — and start with WEB_PORT=8119 docker compose -p chai-19-b up -d."
fi

celebrate "Challenge complete. One file, two isolated stacks — that's what project names buy you."
