#!/usr/bin/env bash
# Reset this chapter: remove its containers, image, and the student-written
# Dockerfile (committed scaffolding — server.js — stays).
docker rm -f chai-12-api chai-12-sick >/dev/null 2>&1
docker rmi -f chai-12-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch12/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 12 reset (chai-12 containers, image, and Dockerfile removed)."
exit 0
