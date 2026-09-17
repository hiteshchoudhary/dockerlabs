#!/usr/bin/env bash
# Reset this chapter: take the compose project down and remove its image
# and the student-written compose file (the api/ scaffolding stays).
docker compose -p chai-37 down -v --remove-orphans >/dev/null 2>&1
docker rm -f chai-37-api chai-37-qdrant >/dev/null 2>&1
docker rmi chai-37-api >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch37/compose.yaml" 2>/dev/null
echo "  ✔ Chapter 37 reset (project chai-37 down, image chai-37-api removed, compose.yaml removed — api/ scaffolding kept)."
exit 0
