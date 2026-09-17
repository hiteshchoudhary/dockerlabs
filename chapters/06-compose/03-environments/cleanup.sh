#!/usr/bin/env bash
# Reset this chapter: the chai-21 project (including the profile service),
# its built image, and the student-written files.

WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch21"

if [ -f "$WS/compose.yaml" ]; then
  docker compose -p chai-21 -f "$WS/compose.yaml" --profile debug down -v --remove-orphans >/dev/null 2>&1
fi
docker compose -p chai-21 down -v --remove-orphans >/dev/null 2>&1

ids=$(docker ps -aq --filter "label=com.docker.compose.project=chai-21")
[ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
docker network rm chai-21_default >/dev/null 2>&1
docker rmi chai-21-web >/dev/null 2>&1

rm -f "$WS/compose.yaml" "$WS/.env" "$WS/web.env" 2>/dev/null

echo "  ✔ Chapter 21 reset (project chai-21, image chai-21-web and generated files removed)."
exit 0
