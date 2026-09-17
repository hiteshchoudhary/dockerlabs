#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

check_nginx_running() {  # $1 = container name
  local name="$1"
  if ! docker container inspect "$name" >/dev/null 2>&1; then
    fail "No container named '$name' found. Run one: docker run -d --name $name -p ... nginx:alpine"
  fi
  pass "Container '$name' exists"

  local img
  img=$(docker container inspect -f '{{.Config.Image}}' "$name")
  case "$img" in
    nginx:alpine*|nginx) pass "'$name' was created from nginx:alpine" ;;
    *) fail "'$name' uses image '$img' — expected 'nginx:alpine'. Remove it (docker rm -f $name) and re-run from the right image." ;;
  esac

  local state
  state=$(docker container inspect -f '{{.State.Status}}' "$name")
  if [ "$state" = "running" ]; then
    pass "'$name' is running"
  else
    fail "'$name' is '$state', not running. Check its logs (docker logs $name), then remove and re-run it."
  fi
}

# --- chai-16-web: loopback-only on 8016 ---
check_nginx_running chai-16-web

web_ip=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostIp}}' chai-16-web 2>/dev/null)
web_port=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostPort}}' chai-16-web 2>/dev/null)

if [ -z "$web_port" ]; then
  fail "chai-16-web publishes no ports at all. It needs container port 80 published on loopback: docker run -d --name chai-16-web -p 127.0.0.1:8016:80 nginx:alpine (remove the old one first)."
fi
if [ "$web_port" != "8016" ]; then
  fail "chai-16-web's 80/tcp is bound to host port '$web_port' — expected 8016. Recreate it with -p 127.0.0.1:8016:80."
fi
if [ "$web_ip" = "127.0.0.1" ]; then
  pass "chai-16-web: 80/tcp bound to 127.0.0.1:8016 (loopback only)"
else
  fail "chai-16-web's HostIp is '${web_ip:-<empty> (0.0.0.0, all interfaces)}' — it must bind ONLY to loopback. Recreate it with -p 127.0.0.1:8016:80."
fi

if curl -fsS --max-time 5 http://127.0.0.1:8016 >/dev/null 2>&1; then
  pass "nginx answers on http://127.0.0.1:8016"
else
  fail "Nothing answered on http://127.0.0.1:8016. Is chai-16-web healthy? Check docker logs chai-16-web, then recreate it with -p 127.0.0.1:8016:80."
fi

# --- chai-16-open: all interfaces on 8116 ---
check_nginx_running chai-16-open

open_ip=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostIp}}' chai-16-open 2>/dev/null)
open_port=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostPort}}' chai-16-open 2>/dev/null)

if [ -z "$open_port" ]; then
  fail "chai-16-open publishes no ports. It needs the default (all-interfaces) bind: docker run -d --name chai-16-open -p 8116:80 nginx:alpine."
fi
if [ "$open_port" != "8116" ]; then
  fail "chai-16-open's 80/tcp is bound to host port '$open_port' — expected 8116. Recreate it with -p 8116:80."
fi
case "$open_ip" in
  ""|0.0.0.0|::) pass "chai-16-open: 80/tcp bound on all interfaces (0.0.0.0:8116)" ;;
  *) fail "chai-16-open's HostIp is '$open_ip' — this one should use the DEFAULT bind (all interfaces). Recreate it with plain -p 8116:80, no IP prefix." ;;
esac

if curl -fsS --max-time 5 http://127.0.0.1:8116 >/dev/null 2>&1; then
  pass "nginx answers on http://127.0.0.1:8116"
else
  fail "Nothing answered on http://127.0.0.1:8116. Check docker logs chai-16-open, then recreate it with -p 8116:80."
fi

celebrate "Exercise 16.1 complete. Every -p you type from now on is a decision, not a reflex."
