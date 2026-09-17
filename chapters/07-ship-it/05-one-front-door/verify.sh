#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker network inspect chai-28-net >/dev/null 2>&1; then
  fail "No network named 'chai-28-net'. Create it: docker network create chai-28-net"
fi
pass "Network 'chai-28-net' exists"

for c in chai-28-api1 chai-28-api2; do
  if ! docker container inspect "$c" >/dev/null 2>&1; then
    fail "No container named '$c'. Run it: docker run -d --name $c --network chai-28-net chai-28-api:1.0"
  fi

  state=$(docker container inspect -f '{{.State.Status}}' "$c")
  if [ "$state" != "running" ]; then
    fail "$c is '$state' — start it: docker start $c (if it crashes, check docker logs $c)"
  fi

  img=$(docker container inspect -f '{{.Config.Image}}' "$c")
  case "$img" in
    chai-28-api*) : ;;
    *) fail "$c runs image '$img' — expected your chai-28-api build. Recreate it from the scaffold image (docker build -t chai-28-api:1.0 ./ch28)." ;;
  esac

  nets=$(docker container inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$c")
  case "$nets" in
    *chai-28-net*) : ;;
    *) fail "$c is on '$nets' — not on chai-28-net. Recreate it with --network chai-28-net (the proxy finds it by name there)." ;;
  esac

  published=$(docker container inspect -f '{{len .HostConfig.PortBindings}}' "$c")
  if [ "$published" != "0" ]; then
    fail "$c publishes ports to the host — replicas must be UNREACHABLE except through the proxy. Recreate it without any -p flag."
  fi
done
pass "Both replicas running on chai-28-net, from the chai-28-api image, no published ports"

if ! docker container inspect chai-28-proxy >/dev/null 2>&1; then
  fail "No container named 'chai-28-proxy'. Run it: docker run -d --name chai-28-proxy --network chai-28-net -p 8028:80 -v \"\$PWD/ch28/nginx.conf:/etc/nginx/conf.d/default.conf:ro\" nginx:alpine"
fi

state=$(docker container inspect -f '{{.State.Status}}' chai-28-proxy)
if [ "$state" != "running" ]; then
  fail "chai-28-proxy is '$state' — a bad nginx.conf makes nginx exit at boot. Check docker logs chai-28-proxy, fix the config, recreate."
fi

nets=$(docker container inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' chai-28-proxy)
case "$nets" in
  *chai-28-net*) pass "chai-28-proxy is running on chai-28-net" ;;
  *) fail "chai-28-proxy is on '$nets' — it must join chai-28-net to resolve the replicas by name. Recreate it with --network chai-28-net." ;;
esac

if ! curl -fsS --max-time 5 http://127.0.0.1:8028/ >/dev/null 2>&1; then
  fail "Nothing (or an error) answers on http://127.0.0.1:8028/ — publish the proxy with -p 8028:80 and check docker logs chai-28-proxy (502 means it can't reach the replicas)."
fi
pass "The front door answers on host port 8028"

distinct=$(for i in $(seq 1 20); do curl -fsS --max-time 5 http://127.0.0.1:8028/ 2>/dev/null; done | sort -u | grep -c 'hello from')
if [ "$distinct" -lt 2 ]; then
  # nginx sidelines an upstream member for 10s after a failed attempt
  # (e.g. a replica that wasn't listening yet) — give it one more chance
  info "Only $distinct backend answered — waiting out nginx's fail_timeout and retrying..."
  sleep 11
  distinct=$(for i in $(seq 1 20); do curl -fsS --max-time 5 http://127.0.0.1:8028/ 2>/dev/null; done | sort -u | grep -c 'hello from')
fi
if [ "$distinct" -ge 2 ]; then
  pass "Twenty requests were served by $distinct different hostnames — round-robin, observed"
else
  fail "Twenty requests all came back from the same backend (or unexpected bodies). The upstream must list BOTH replicas (chai-28-api1:3000 and chai-28-api2:3000) — check your nginx.conf against the template, recreate the proxy, verify again."
fi

celebrate "Exercise 28.1 complete. One front door, two hidden replicas, zero exposed apps."
