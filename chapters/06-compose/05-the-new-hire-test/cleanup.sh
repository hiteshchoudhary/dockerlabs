#!/usr/bin/env bash
# Reset this chapter: the chai-23 project (with profile services and the
# pgdata volume), its built image, and the student-written compose file.

WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch23"

if [ -f "$WS/compose.yaml" ]; then
  docker compose -p chai-23 -f "$WS/compose.yaml" --profile debug down -v --remove-orphans >/dev/null 2>&1
fi
docker compose -p chai-23 down -v --remove-orphans >/dev/null 2>&1

ids=$(docker ps -aq --filter "label=com.docker.compose.project=chai-23")
[ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
docker network rm chai-23_default >/dev/null 2>&1
docker volume rm chai-23_pgdata >/dev/null 2>&1
docker rmi chai-23-api >/dev/null 2>&1

rm -f "$WS/compose.yaml" 2>/dev/null

echo "  ✔ Chapter 23 reset (project chai-23, image chai-23-api, volume and compose.yaml removed)."
exit 0
