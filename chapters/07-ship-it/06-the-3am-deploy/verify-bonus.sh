#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-29-app >/dev/null 2>&1; then
  fail "No container named 'chai-29-app' — finish the main exercise, then roll back."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-29-app)
if [ "$state" != "running" ]; then
  fail "chai-29-app is '$state' — a rollback ends with the old version RUNNING. Re-run the ritual's final step: docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0"
fi

img=$(docker container inspect -f '{{.Config.Image}}' chai-29-app)
if [ "$img" = "127.0.0.1:8129/chai-29-app:1.0" ]; then
  pass "chai-29-app is running the :1.0 tag again"
else
  fail "chai-29-app runs '$img' — roll back by the same ritual: docker stop chai-29-app && docker rm chai-29-app && docker run -d --name chai-29-app -p 8029:80 127.0.0.1:8129/chai-29-app:1.0"
fi

body=$(curl -fsS --max-time 5 http://127.0.0.1:8029/ 2>/dev/null)
if echo "$body" | grep -q 'version 1.0'; then
  pass "The service answers 'version 1.0' — rollback is live"
else
  fail "http://127.0.0.1:8029/ answers '${body:-nothing}' — expected the version 1.0 marker. Re-run the rollback ritual and make sure -p 8029:80 is on the run."
fi

notefile="${LAB_WORKSPACE:?}/ch29/rollback.txt"
if [ ! -f "$notefile" ]; then
  fail "No morning note at workspace/ch29/rollback.txt. Record what production runs now: docker inspect -f '{{.Config.Image}}' chai-29-app > ./ch29/rollback.txt"
fi

if grep -q '127.0.0.1:8129/chai-29-app:1.0' "$notefile"; then
  pass "rollback.txt records the :1.0 reference — the morning team will know"
else
  fail "rollback.txt says '$(tr -d '[:space:]' < "$notefile")' — it must record the exact reference the container runs. Regenerate it: docker inspect -f '{{.Config.Image}}' chai-29-app > ./ch29/rollback.txt"
fi

celebrate "Challenge complete. Rollback at 3 AM: three commands and a note, then back to bed."
