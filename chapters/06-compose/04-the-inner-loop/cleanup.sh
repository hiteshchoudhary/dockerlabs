#!/usr/bin/env bash
# Reset this chapter: the chai-22 project, its built image, and the
# student-written compose file. Committed scaffolding under app/ is kept.

docker compose -p chai-22 down -v --remove-orphans >/dev/null 2>&1

ids=$(docker ps -aq --filter "label=com.docker.compose.project=chai-22")
[ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
docker network rm chai-22_default >/dev/null 2>&1
docker rmi chai-22-web >/dev/null 2>&1

rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch22/compose.yaml" 2>/dev/null

echo "  ✔ Chapter 22 reset (project chai-22, image chai-22-web and compose.yaml removed)."
exit 0
