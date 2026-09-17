#!/usr/bin/env bash
# Reset this chapter: remove its containers, image, and the student-written
# Dockerfile. Never touches the committed scaffold (server.js, package.json).
docker rm -f chai-30-api chai-30-flag >/dev/null 2>&1
docker rmi chai-30-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch30/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 30 reset (chai-30-api, chai-30-flag, image and Dockerfile removed)."
exit 0
