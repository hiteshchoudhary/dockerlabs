#!/usr/bin/env bash
# Reset this chapter: remove its container, image, and the student-written
# Dockerfile. Never touches the committed scaffold (token.txt, install-deps.sh,
# server.js).
docker rm -f chai-32-app chai-32-probe >/dev/null 2>&1
docker rmi chai-32-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch32/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 32 reset (chai-32-app, chai-32-api:v1 and Dockerfile removed)."
exit 0
