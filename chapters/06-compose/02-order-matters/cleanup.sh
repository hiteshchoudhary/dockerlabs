#!/usr/bin/env bash
# Reset this chapter: the chai-20 compose project and the student-written file.

docker compose -p chai-20 down -v --remove-orphans >/dev/null 2>&1

ids=$(docker ps -aq --filter "label=com.docker.compose.project=chai-20")
[ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
docker network rm chai-20_default >/dev/null 2>&1

rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch20/compose.yaml" 2>/dev/null

echo "  ✔ Chapter 20 reset (project chai-20 removed, compose.yaml cleared)."
exit 0
