#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-26-app >/dev/null 2>&1; then
  fail "No container named 'chai-26-app' found. Run it: docker run -d --name chai-26-app --restart unless-stopped --memory 64m --cpus 0.5 nginx:alpine"
fi
pass "Container 'chai-26-app' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-26-app)
case "$img" in
  nginx:alpine*) pass "Created from 'nginx:alpine'" ;;
  *) fail "chai-26-app uses image '$img' — expected 'nginx:alpine'. Recreate it: docker rm -f chai-26-app, then run again from nginx:alpine." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-26-app)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-26-app is '$state' — start it: docker start chai-26-app"
fi

policy=$(docker container inspect -f '{{.HostConfig.RestartPolicy.Name}}' chai-26-app)
if [ "$policy" = "unless-stopped" ]; then
  pass "Restart policy is unless-stopped"
else
  fail "Restart policy is '${policy:-no}' — expected 'unless-stopped'. Fix without recreating: docker update --restart unless-stopped chai-26-app"
fi

mem=$(docker container inspect -f '{{.HostConfig.Memory}}' chai-26-app)
if [ "$mem" = "67108864" ]; then
  pass "Memory limit is 64 MiB (67108864 bytes)"
else
  fail "Memory limit is '$mem' bytes — expected 67108864 (--memory 64m). Fix: docker update --memory 64m --memory-swap 64m chai-26-app (or recreate with the flag)."
fi

cpus=$(docker container inspect -f '{{.HostConfig.NanoCpus}}' chai-26-app)
if [ "$cpus" = "500000000" ]; then
  pass "CPU limit is 0.5 cores (NanoCpus 500000000)"
else
  fail "NanoCpus is '$cpus' — expected 500000000 (--cpus 0.5). Fix: docker update --cpus 0.5 chai-26-app (or recreate with the flag)."
fi

celebrate "Exercise 26.1 complete. This container can crash, recover, and never eat the machine."
