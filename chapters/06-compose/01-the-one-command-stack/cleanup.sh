#!/usr/bin/env bash
# Reset this chapter: both compose projects (chai-19 and the challenge's
# chai-19-b) plus the student-written compose file. Touches nothing else.

docker compose -p chai-19 down -v --remove-orphans >/dev/null 2>&1
docker compose -p chai-19-b down -v --remove-orphans >/dev/null 2>&1

# Fallback in case compose can't reconstruct the projects from labels.
for p in chai-19 chai-19-b; do
  ids=$(docker ps -aq --filter "label=com.docker.compose.project=$p")
  [ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1
  docker network rm "${p}_default" >/dev/null 2>&1
done

rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch19/compose.yaml" 2>/dev/null

echo "  ✔ Chapter 19 reset (projects chai-19 and chai-19-b removed, compose.yaml cleared)."
exit 0
