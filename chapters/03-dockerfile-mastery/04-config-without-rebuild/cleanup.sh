#!/usr/bin/env bash
# Reset this chapter: remove its containers, images, and the student-written
# Dockerfile (committed scaffolding — server.js — stays).
docker rm -f chai-10-demo chai-10-prod >/dev/null 2>&1
docker rmi -f chai-10-api:v1 chai-10-api:stamped >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch10/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 10 reset (chai-10 containers, images, and Dockerfile removed)."
exit 0
