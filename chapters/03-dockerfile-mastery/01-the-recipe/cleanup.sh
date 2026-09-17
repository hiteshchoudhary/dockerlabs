#!/usr/bin/env bash
# Reset this chapter: remove its containers, image, and the student-written
# Dockerfile (committed scaffolding — server.js — stays).
docker rm -f chai-07-api chai-07-copy >/dev/null 2>&1
docker rmi -f chai-07-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch07/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 7 reset (chai-07 containers, image, and Dockerfile removed)."
exit 0
