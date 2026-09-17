#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-14-web >/dev/null 2>&1; then
  fail "No container named 'chai-14-web' found. Run nginx:alpine with --name chai-14-web."
fi
pass "Container 'chai-14-web' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-14-web)
case "$img" in
  nginx:alpine*) pass "Created from the 'nginx:alpine' image" ;;
  *) fail "chai-14-web uses image '$img' — expected 'nginx:alpine'." ;;
esac

state=$(docker container inspect -f '{{.State.Status}}' chai-14-web)
if [ "$state" = "running" ]; then
  pass "It is running"
else
  fail "chai-14-web is '$state', not running. Check 'docker logs chai-14-web' and start it again."
fi

mtype=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Type}}{{end}}{{end}}' chai-14-web)
msrc=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Source}}{{end}}{{end}}' chai-14-web)
mrw=$(docker container inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.RW}}{{end}}{{end}}' chai-14-web)

if [ -z "$mtype" ]; then
  fail "Nothing is mounted at /usr/share/nginx/html. Add -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro when you run the container."
fi
if [ "$mtype" != "bind" ]; then
  fail "The mount at /usr/share/nginx/html is a '$mtype', not a bind mount. A bare name in -v creates a volume — use the ABSOLUTE host path: -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro"
fi
case "$msrc" in
  */ch14/site) pass "Bind mount of your ch14/site directory is in place" ;;
  *) fail "The bind mount's source is '$msrc' — expected your workspace/ch14/site directory. Recreate the container with -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro (run from workspace/)." ;;
esac
if [ "$mrw" = "false" ]; then
  pass "…and it is read-only"
else
  fail "The bind mount is writable. Serve-only content gets :ro on principle — recreate with -v \"\$(pwd)/ch14/site\":/usr/share/nginx/html:ro"
fi

hostfile="${LAB_WORKSPACE:?}/ch14/site/index.html"
if [ ! -f "$hostfile" ]; then
  fail "workspace/ch14/site/index.html is missing on the host — it's the chapter's scaffolding. Restore it by running this chapter's cleanup, then redo the exercise."
fi
if grep -q "edit me" "$hostfile"; then
  fail "index.html still says 'edit me' — the live-edit step IS the exercise. Open workspace/ch14/site/index.html, replace the placeholder with your own message, and verify again (no docker commands needed)."
fi
pass "The 'edit me' placeholder is gone — you edited the file"

body=$(curl -fsS --max-time 5 http://127.0.0.1:8014/ 2>/dev/null)
if [ -z "$body" ]; then
  fail "Nothing answered on http://127.0.0.1:8014/. Publish the port when you run the container: -p 8014:80"
fi
if [ "$body" = "$(cat "$hostfile")" ]; then
  pass "Port 8014 serves byte-for-byte what's in index.html on your host right now — the mount is live"
else
  fail "The page on port 8014 doesn't match workspace/ch14/site/index.html. The container is serving something else — check 'docker inspect -f '{{json .Mounts}}' chai-14-web' and make sure the bind source is your ch14/site directory."
fi

celebrate "Exercise 14.1 complete. Edit on the host, served from the container — that's the dev loop."
