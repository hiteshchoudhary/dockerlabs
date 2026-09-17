#!/usr/bin/env bash
# Reset chapter 45: the chai-45 compose project, its volumes, its built
# images, and the student-written compose file. Touches nothing else.
docker compose -p chai-45 down -v --remove-orphans >/dev/null 2>&1
docker rm -f chai-45-web chai-45-api chai-45-db chai-45-cache chai-45-qdrant >/dev/null 2>&1
docker volume rm chai-45-pgdata chai-45-qdrant >/dev/null 2>&1
docker rmi chai-45-api chai-45-web >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch45/compose.yaml" 2>/dev/null
echo "  ✔ Chapter 45 reset (chai-45 project, volumes, images and compose.yaml removed)."
exit 0
