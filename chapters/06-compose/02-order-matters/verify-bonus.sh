#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

find_svc() {
  docker ps -q \
    --filter "label=com.docker.compose.project=chai-20" \
    --filter "label=com.docker.compose.service=$1" | head -n1
}

for svc in db web; do
  id=$(find_svc "$svc")
  if [ -z "$id" ]; then
    fail "No running '$svc' container in project chai-20 — finish the main exercise first, then add the restart policy."
  fi
  policy=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$id")
  if [ "$policy" = "unless-stopped" ]; then
    pass "$svc carries restart: unless-stopped"
  else
    fail "$svc's restart policy is '${policy:-no}' — add restart: unless-stopped to the service and apply it with docker compose up -d."
  fi
done

celebrate "Challenge complete. This stack now survives crashes — and respects a deliberate stop."
