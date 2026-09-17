#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-14-web >/dev/null 2>&1; then
  fail "chai-14-web doesn't exist — finish the main exercise first."
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-14-web)
if [ "$state" != "running" ]; then
  fail "chai-14-web is '$state', not running. Start it again."
fi

ttype=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/cache"}}{{.Type}}{{end}}{{end}}' chai-14-web)
if [ "$ttype" != "tmpfs" ]; then
  # --tmpfs sometimes surfaces only under HostConfig.Tmpfs; accept that spelling too
  if docker container inspect -f '{{json .HostConfig.Tmpfs}}' chai-14-web 2>/dev/null | grep -q '"/cache"'; then
    ttype="tmpfs"
  fi
fi
if [ "$ttype" = "tmpfs" ]; then
  pass "A tmpfs mount sits at /cache"
else
  fail "No tmpfs at /cache (found: '${ttype:-nothing}'). Mounts are fixed at creation — recreate: docker rm -f chai-14-web && docker run -d --name chai-14-web -p 8014:80 -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro --tmpfs /cache nginx:alpine"
fi

if docker exec chai-14-web sh -c 'echo probe > /cache/.chai-14-probe && rm /cache/.chai-14-probe' >/dev/null 2>&1; then
  pass "A process inside can write to /cache (RAM-backed, gone at stop)"
else
  fail "Couldn't write inside /cache from within the container. Check the tmpfs flag: --tmpfs /cache"
fi

mrw=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Type}}:{{.RW}}{{end}}{{end}}' chai-14-web)
if [ "$mrw" = "bind:false" ]; then
  pass "…while the html bind mount is still read-only"
else
  fail "The read-only bind mount at /usr/share/nginx/html is '${mrw:-missing}' — keep the main exercise's -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro when you add the tmpfs."
fi

celebrate "Challenge complete. Three mount types, one container, each doing the job it's built for."
