#!/usr/bin/env bash
# Reset this chapter: remove its containers, images, and the student-written
# Dockerfile (committed scaffolding — main.go, go.mod — stays).
docker rm -f chai-11-api chai-11-mini >/dev/null 2>&1
docker rmi -f chai-11-api:slim chai-11-api:scratch >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch11/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 11 reset (chai-11 containers, images, and Dockerfile removed)."
exit 0
